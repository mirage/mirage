/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/* OCaml interface to the libev main loop */

#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/callback.h>
#include <err.h>
#include "libev/ev.h"

#define Watcher_val(x) (*((ev_io **) (Data_custom_val(x))))

/* The LWT mainloop registers a run callback if there are
   still active threads */
value *run_callback;

/* Singleshot timer for main loop timeouts */
static ev_timer timeout_watcher;

/* Called when a file descriptor is ready for reads or writes */
static void
io_watcher_callback(ev_io *w, int revents)
{
  int flags = 0;
  value v_cb = ((value)w->data);
  /* Stop any outstanding timer since I/O is ready instead */
  ev_timer_stop(&timeout_watcher);
  if (revents & EV_READ)
    flags |= 1;
  if (revents & EV_WRITE)
    flags |= 2;
  fprintf(stderr, "io_watcher_callback: flags=%d\n", flags);
  caml_callback(v_cb, Val_int(flags));
  if (run_callback)
    caml_callback(*run_callback, Val_unit);
}

/* Called when the event handler times out.
 */
static void
timer_watcher_callback(ev_timer *w, int revents)
{
  fprintf(stderr, "timer_watcher_callback: w=%p revents=%d\n", w, revents);
  if (run_callback)
    caml_callback(*run_callback, Val_unit);
}

/* This is a debugging sanity check to ensure the watcher has been
   deregistered correctly from the ML code */
static void 
watcher_finalize_gc(value v_watcher)
{
  ev_io *w = Watcher_val(v_watcher);
  if (w->data != NULL)
    errx(1, "watcher_finalize_gc: watcher->data != NULL, missing deregister");
}

/* Register a file descriptor and associated callback function,
   and return the watcher.
 */
CAMLprim value
caml_register_fd(value v_fd, value v_mask, value v_cb)
{
  CAMLparam3(v_fd, v_mask, v_cb);
  CAMLlocal1(v_watcher);
  int fd = Int_val(v_fd);
  fprintf(stderr, "caml_register_fd: fd=%d mask=%d value=%lu\n", fd, Int_val(v_mask), v_cb);
  /* Allocate an IO watcher, associate the OCaml callback with it,
     and register the callback as a generational root */
  ev_io *watcher = caml_stat_alloc(sizeof (struct ev_io));
  watcher->data = (void *) v_cb;
  caml_register_generational_global_root((value *)&watcher->data);
  ev_io_init(watcher, io_watcher_callback, fd, Int_val(v_mask));
  v_watcher = caml_alloc_final(2, watcher_finalize_gc, 1, 100);
  Watcher_val(v_watcher) = watcher;
  ev_io_start(watcher);
  CAMLreturn(v_watcher);
}

/* Deregister a watcher, which will free its memory and stop IO events */
CAMLprim value
caml_unregister_fd(value v_watcher)
{
  CAMLparam1(v_watcher);
  fprintf(stderr, "caml_unregister_fd\n");
  ev_io *w = Watcher_val(v_watcher);
  caml_remove_generational_global_root((value *)(w->data));
  ev_io_stop(w);
  free(w);
  Watcher_val(v_watcher) = NULL;
  CAMLreturn(Val_unit);
}

/* Block until an I/O event comes in */
CAMLprim value
caml_block_domain(value v_unit)
{
  fprintf(stderr, "caml_block_domain\n");
  if (!run_callback)
    run_callback = caml_named_value("Main.run");
  return Val_unit;
}

/* Block with a timeout */
CAMLprim value
caml_block_domain_with_timeout(value v_timeout)
{
  fprintf(stderr, "caml_block_domain_with_timeout: %f\n", Double_val(v_timeout));
  if (!run_callback)
    run_callback = caml_named_value("Main.run");
  ev_timer_init(&timeout_watcher, timer_watcher_callback, Double_val(v_timeout), 0.0);
  ev_timer_start(&timeout_watcher);
  return Val_unit;
}
