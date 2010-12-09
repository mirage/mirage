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

#include "istring.h"
#include <err.h>

CAMLprim value
tap_read(value v_fd, value v_istr, value v_len)
{
  int fd = Int_val(v_fd);
  unsigned char *buf = Istring_val(v_istr)->buf;
  int res = read(fd, buf, Int_val(v_len));
  if (res < 0) {
    if (errno == EAGAIN || errno == EWOULDBLOCK)
      return Val_int(-1);
    else
      err(1, "tap_read");
  }
  return Val_int(res);
}

CAMLprim value
tap_write(value v_fd, value v_istr, value v_len)
{
  int fd = Int_val(v_fd);
  size_t len = Int_val(v_len);
  unsigned char *buf = Istring_val(v_istr)->buf;
  int res = write(fd, buf, len);
  if (res != len) {
    fprintf(stderr, "tap_write: not full fd=%d res=%d len=%lu (%s)\n", fd, res, len,strerror(errno));
    err(1, "tap_write");
  }
  return Val_unit;
}

