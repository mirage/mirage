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

/*
 * UNIX support for Mirage networking via tuntap.
 *
 * This tuntap interface is not intended to be high-performance, but 
 * primarily for debugging the native Mirage networking stack under a 
 * full OS environment.
 */

#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <err.h>

CAMLprim value
tap_read(value v_fd, value v_buf, value v_off, value v_len)
{
  int fd = Int_val(v_fd);
  int res = read(fd, String_val(v_buf) + Int_val(v_off), Int_val(v_len));
  if (res < 0) {
    if (errno == EAGAIN || errno == EWOULDBLOCK)
      return Val_int(-1);
    else
      err(1, "tap_read");
  }
  return Val_int(res);
}

CAMLprim value
tap_write(value v_fd, value v_buf, value v_off, value v_len)
{
  int fd = Int_val(v_fd);
  size_t len = Int_val(v_len);
  int res = write(fd, String_val(v_buf) + Int_val(v_off), len);
  if (res != len) {
    fprintf(stderr, "tap_write: not full res=%d len=%lu (%s)\n", res, len, strerror(errno));
    err(1, "tap_write");
  }
  return Val_unit;
}

