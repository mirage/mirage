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

/* Stubs to handle waking up the xenulator.
   Statically registers any fds and timeout */

#include <stdio.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

int tap_fd = -1;
int tap_ready = 0;

CAMLprim value
unix_clear_events(value v_unit)
{
  tap_ready = 0;
  return Val_unit;
}

CAMLprim value
unix_block_domain(value v_time)
{
  CAMLparam1(v_time);
  struct timeval tv;
  int ret; 
  fd_set rfds;
  int nfds = 0;

  tv.tv_sec = (long)(Double_val(v_time));
  tv.tv_usec = 0; /* XXX convert from v_time remainder */

  fprintf(stderr, "unix_block_domain: %f  tv_sec=%lu\n", Double_val(v_time), tv.tv_sec);
  FD_ZERO(&rfds);
  if (tap_fd >= 0) {
    FD_SET(tap_fd, &rfds);
    nfds=1;
  }
  
  ret = select(nfds, &rfds, NULL, NULL, &tv);
  if (nfds > 0) {
    if (FD_ISSET(tap_fd, &rfds))
      tap_ready = 1;
  }
 
  CAMLreturn(Val_unit);
}
