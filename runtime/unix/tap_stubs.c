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

extern uint8_t ev_callback_ml[];
extern uint8_t ev_fds[];

CAMLprim value
tap_read(value v_fd, value v_buf, value v_off, value v_len)
{
  int fd = Int_val(v_fd);
  int res = read(fd, String_val(v_buf) + Int_val(v_off), Int_val(v_len));
  if (res < 0) {
    fprintf(stderr, "read err: %s\n", strerror(errno));
    caml_failwith("tap_read < 0");
  }
  return Val_int(res);
}

CAMLprim value
tap_has_input(value v_fd)
{
  int fd = Int_val(v_fd);
  fd_set fdset;
  struct timeval tv;
  int ret;
  FD_ZERO(&fdset);
  FD_SET(fd, &fdset);
  tv.tv_sec = 0;
  tv.tv_usec = 1;
  ret = select(fd+1, &fdset, NULL, NULL, &tv);
  return Val_int(ret == 1 ? 1 : 0);
}

CAMLprim value
tap_write(value v_fd, value v_buf)
{
  int fd = Int_val(v_fd);
  ssize_t len = caml_string_length(v_buf);
  int res = write(fd, String_val(v_buf), len);
  if (res != len) {
    fprintf(stderr, "tap_write: not full res=%d len=%lu (%s)\n", res, len, strerror(errno));
    caml_failwith("tap_write: not full write");
  }
  return Val_int(len);
}
