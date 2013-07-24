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

#include <stdint.h>
#include <assert.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/bigarray.h>

#include "barrier.h"

#define xen_mb() mb()
#define xen_wmb() wmb()

CAMLprim value
caml_memory_barrier()
{
  xen_mb();
  return Val_unit;
}

CAMLprim value
caml_write_memory_barrier()
{
  wmb();
  return Val_unit;
}

CAMLprim value caml_cstruct_unsafe_load_uint32(value vc, value vofs) {
  CAMLparam2(vc, vofs);
  CAMLlocal2(vb, vbofs);
  vb = Field(vc, 0);
  vbofs = Field(vc, 1);
  int ofs = Int_val(vofs);
  int bofs = Int_val(vbofs);
  struct caml_ba_array *b = Caml_ba_array_val(vb);
  uint32_t *data = ((uint32_t*) (b->data + bofs));
  CAMLreturn (Val_int(data[ofs / sizeof(uint32_t)]));
}

CAMLprim value caml_cstruct_unsafe_save_uint32(value vc, value vofs, value x) {
  CAMLparam3(vc, vofs, x);
  CAMLlocal2(vb, vbofs);
  vb = Field(vc, 0);
  vbofs = Field(vc, 1);
  int ofs = Int_val(vofs);
  int bofs = Int_val(vbofs);
  struct caml_ba_array *b = Caml_ba_array_val(vb);
  uint32_t *data = ((uint32_t*) (b->data + bofs));
  data[ofs / sizeof(uint32_t)] = Int_val(x);
  CAMLreturn (Val_unit);
}

