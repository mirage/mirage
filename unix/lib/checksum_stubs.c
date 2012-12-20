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
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

static uint32_t
checksum_bigarray(unsigned char *addr, size_t ofs, size_t count, uint32_t sum)
{
  addr += ofs;
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
  return sum;
}

CAMLprim value
caml_ones_complement_checksum(value v_cstruct)
{
  CAMLparam1(v_cstruct);
  CAMLlocal3(v_ba, v_ofs, v_len);
  uint32_t sum = 0;
  uint16_t checksum = 0;
  v_ba = Field(v_cstruct, 0);
  v_ofs = Field(v_cstruct, 1);
  v_len = Field(v_cstruct, 2);
  sum = checksum_bigarray(Caml_ba_data_val(v_ba), Int_val(v_ofs), Int_val(v_len), 0);
  checksum = ~sum;
  CAMLreturn(Val_int(checksum));
}

/* Checksum a list of cstruct.ts. The complexity of overflow is due to
 * having potentially odd-sized buffers, and the odd byte must be carried
 * forward as 16-byte 1s complement addition if there are more buffers in
 * the chain. */
CAMLprim value
caml_ones_complement_checksum_list(value v_cstruct_list)
{
  CAMLparam1(v_cstruct_list);
  CAMLlocal4(v_hd, v_ba, v_ofs, v_len);
  uint32_t sum = 0;
  uint16_t checksum = 0;
  uint16_t overflow = 0;
  size_t count = 0;
  struct caml_ba_array *a = NULL;
  unsigned char *addr;
  while (v_cstruct_list != Val_emptylist) {
    v_hd = Field(v_cstruct_list, 0);
    v_cstruct_list = Field(v_cstruct_list, 1);
    v_ba = Field(v_hd, 0);
    v_ofs = Field(v_hd, 1);
    v_len = Field(v_hd, 2);
    a = Caml_ba_array_val(v_ba);
    addr = a->data + Int_val(v_ofs);
    count = Int_val(v_len);
    if (count <= 0) continue;
    if (overflow != 0) {
      sum += (overflow << 8) + (*addr);
      overflow = 0;
      addr++;
      count--;
    }
    while (count > 1) {
      uint16_t v = (*addr << 8) + (*(addr+1));
      sum += v;
      count -= 2;
      addr += 2;
    }
    if (count > 0) {
      if (v_cstruct_list == Val_emptylist)
        sum += (*(unsigned char *)addr) << 8;
      else
        overflow = *addr;
    }
  }
  if (overflow != 0)
    sum += overflow << 8;
  while (sum >> 16)
    sum = (sum & 0xffff) + (sum >> 16);
  checksum = ~sum;
  CAMLreturn(Val_int(checksum));
}
