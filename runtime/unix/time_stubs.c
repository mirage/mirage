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
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>

#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define NR_EVENTS 128
extern uint8_t ev_callback_ml[NR_EVENTS];
extern uint8_t ev_fds[NR_EVENTS];

CAMLprim value
unix_block_domain(value v_time)
{
  CAMLparam1(v_time);
  struct timeval tv;
  int ret; 
  fd_set rfds;
  fd_set wfds;
  fd_set efds;
  int nfds = 0;
  unsigned int i;

  tv.tv_sec = (long)(Double_val(v_time));
  tv.tv_usec = 0; /* XXX convert from v_time remainder */

  FD_ZERO(&rfds);
 
  for (i=0; i < NR_EVENTS; i++) {
    if (ev_fds[i] > 0) {
      FD_SET(i, &rfds);
      FD_SET(i, &wfds);
      FD_SET(i, &efds);
      nfds=i+1;
    }  
  } 

  fprintf(stderr, "block_domain: %f\n", Double_val(v_time));
  ret = select(nfds, &rfds, &rfds, &efds, &tv);

  for (i=0; i < nfds; i++) {
    if (FD_ISSET(i, &rfds)) {
      ev_callback_ml[i] |= 1;
    }
    if (FD_ISSET(i, &wfds)) {
      ev_callback_ml[i] |= 2;
    }
    if (FD_ISSET(i, &efds)) {
      ev_callback_ml[i] |= 4;
    }
  }
 
  CAMLreturn(Val_unit);
}
