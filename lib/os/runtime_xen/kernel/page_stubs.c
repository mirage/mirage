/*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

#include <mini-os/x86/os.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/gc.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

/* Allocate an array of [n_pages] bigarrays, returned in ascending address
   order */
CAMLprim value
caml_alloc_pages(value n_pages)
{
  CAMLparam1(n_pages);
  CAMLlocal2(page, result);
  int i;
  size_t len = Int_val(n_pages);
  /* XXX: Ideally we would use a lower-level interface to directly allocate pages */
  unsigned long block = (unsigned long) malloc(PAGE_SIZE * (len + 1));
  if (!block) caml_failwith("malloc");
  result = caml_alloc(len, 0);
  /* Align to a page boundary */
  block = PAGE_ALIGN(block);
  while (i < len){
    page = alloc_bigarray_dims(BIGARRAY_UINT8 | BIGARRAY_C_LAYOUT, 1, block, (long)PAGE_SIZE);
    Store_field(result, i, page);
    i++;
    block += (PAGE_SIZE / sizeof(unsigned long));
  };
  CAMLreturn(result);
}
