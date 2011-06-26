/*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/fail.h>

CAMLprim value
caml_ones_complement_checksum(value v_bitstr, value v_initial)
{
  char *buf = String_val(Field(v_bitstr, 0));
  size_t off = Int_val(Field(v_bitstr,1)) / 8;
  size_t count = Int_val(Field(v_bitstr,2)) / 8;
  uint32_t sum = Int32_val(v_initial);

  unsigned char *addr = buf + off;
  uint16_t checksum;
  while (count > 1) {
    uint16_t v = (*addr << 8) + (*(addr+1));
    sum += v;
    count -= 2;
    addr += 2;
  }
  if (count > 0)
    sum += (*(unsigned char *)addr) << 8;
  while (sum >> 16)
    sum = (sum & 0xffff) + (sum >> 16);
  checksum = ~sum;
  return Val_int(checksum);
}
