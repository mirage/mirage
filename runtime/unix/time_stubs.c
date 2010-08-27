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
  struct timeval tv;
  tv.tv_sec = (long)(Double_val(v_time));
  tv.tv_usec = 0; /* XXX convert from v_time remainder */

  fd_set rfds;
  FD_ZERO(&rfds);
  FD_SET(tap_fd, &rfds);
 
  int ret; 
  ret = select(1, &rfds, NULL, NULL, &tv);
  if (FD_ISSET(tap_fd, &rfds))
    tap_ready = 1;
 
  return Val_unit;
}
