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

/* WARNING: This code assumes that it is running on a little endian machine (x86) */
static inline uint16_t
htons(uint16_t v)
{
  return (((v & 0xFF) << 8) | ((v & 0xFF00) >> 8));
}

static inline uint16_t
ntohs(uint16_t v)
{
  return (htons(v));
}

static uint16_t
ones_complement_checksum_bigarray(unsigned char *addr, size_t ofs, size_t count, uint64_t sum64)
{
  addr += ofs;
  uint64_t *data64 = (uint64_t *) addr;
  while (count >= 8) {
    uint64_t s = *data64++;
    sum64 += s;
    if (sum64 < s) sum64++;
    count -= 8;
  }

  addr = (unsigned char *) data64;
  while (count > 1) {
    uint16_t v = *((uint16_t *) addr);
    sum64 += v;
    if (sum64 < v) sum64++;
    count -= 2;
    addr += 2;
  }

  if (count > 0) {
    uint16_t v = ntohs((*addr) << 8);
    sum64 += v;
    if (sum64 < v) sum64++;
  }

  while (sum64 >> 16)
    sum64 = (sum64 & 0xffff) + (sum64 >> 16);
  return htons(~sum64);
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
  checksum = ones_complement_checksum_bigarray(Caml_ba_data_val(v_ba), Int_val(v_ofs), Int_val(v_len), 0);
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
  uint16_t checksum = 0;
  uint16_t overflow_val = 0;
  uint16_t overflow = 0;
  size_t count = 0;
  struct caml_ba_array *a = NULL;
  unsigned char *addr;
  uint64_t *data64;
  uint64_t sum64 = 0;
  const size_t sizeof_ll = 8; /* sizeof (uint64_t) */
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
      overflow_val = ntohs((overflow_val << 8) + (*addr));
      sum64 += overflow_val;
      if (sum64 < overflow_val) sum64++;
      overflow = 0;
      addr++;
      count--;
    }

    data64 = (uint64_t *) addr;

#define checksum_DO_PARTIAL_LOOP_UNROLL
#ifdef checksum_DO_PARTIAL_LOOP_UNROLL
    while (count >= (20 * sizeof_ll)) {
      uint64_t s;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;

      count -= (20 * sizeof_ll);
    }
#endif

    while (count >= sizeof_ll)	{
      uint64_t s = *data64++;
      sum64 += s;
      if (sum64 < s) sum64++;
      count -= sizeof_ll;
    }

    addr = (unsigned char *) data64;
    while (count > 1) {
      uint16_t v = *((uint16_t *) addr);
      sum64 += v;
      if (sum64 < v) sum64++;
      count -= 2;
      addr += 2;
    }

    if (count > 0) {
      overflow_val = *addr;
      overflow = 1;
    }

  }

  if (overflow != 0) {
    overflow_val = ntohs(overflow_val << 8);
    sum64 += overflow_val;
    if (sum64 < overflow_val) sum64++;
  }

  while (sum64 >> 16)
    sum64 = (sum64 & 0xffff) + (sum64 >> 16);
  checksum = htons(~sum64);
  CAMLreturn(Val_int(checksum));
}

