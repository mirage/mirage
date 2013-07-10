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

#include <string.h>
#include <mini-os/x86/os.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/gc.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

/* Allocate a page-aligned bigarray of length [n_pages] pages.
   Since CAML_BA_MANAGED is set the bigarray C finaliser will
   call free() whenever all sub-bigarrays are unreachable.
 */
CAMLprim value
caml_alloc_pages(value n_pages, value blank)
{
  CAMLparam2(n_pages, blank);
  CAMLlocal2(result, bigarray);
  int i;
  size_t len = Int_val(n_pages) * PAGE_SIZE;
  /* If the allocation fails, return None. The ocaml layer will
     be able to trigger a full GC which just might run finalizers
     of unused bigarrays which will free some memory. */
  result = Val_int(0); /* None */
  unsigned long block = (unsigned long) memalign(PAGE_SIZE, len);
  if (!block) {
	printk("memalign(%d, %d) failed: returning None\n", PAGE_SIZE, len);
	goto out;
  }
  if (Bool_val(blank)) memset(block, 0, len);
  bigarray = caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT | CAML_BA_MANAGED, 1, block, (long)len);
  result = caml_alloc(1, 0);
  Store_field(result, 0, bigarray);
 out:
  CAMLreturn(result);
}
