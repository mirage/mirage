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

/* Allocate an 'out of heap' string that is not scanned by the GC */
CAMLprim value
caml_alloc_external_string(value v_len)
{
  /* We must follow the string encoding out of alloc.c here, 
     specifically the padding rules (although we are word-aligned in practise) */
  size_t len = Int_val(v_len);
  mlsize_t offset_index;
  mlsize_t wosize = (len + sizeof (value)) / sizeof (value);
  char *hp = caml_stat_alloc(sizeof(value) + (wosize * 8));
  Hd_hp(hp) = Make_header(wosize, String_tag, Caml_white);
  value v_buf = Val_hp(hp);
  /* Pad the end of the string */
  Field(v_buf, wosize-1) = 0;
  offset_index = Bsize_wsize(wosize)-1;
  Byte(v_buf, offset_index) = offset_index - len;
  return v_buf;
}

/* Given a string, determine the offset at which a page begins,
   how many pages there are. */
CAMLprim value
caml_chunk_string_pages(value v_str)
{
  CAMLparam1(v_str);
  CAMLlocal1(v_ret);
  unsigned long buf, buflen, bufoff;
  int nr_pages;
  buf = (unsigned long)(String_val(v_str));
  buflen = caml_string_length(v_str);
  if (buflen < PAGE_SIZE)
    caml_failwith("pages_of_string: len < PAGE_SIZE");
  bufoff = PAGE_ALIGN(buf) - buf;
  nr_pages = (buflen-bufoff) / PAGE_SIZE;
  v_ret = caml_alloc(2, 0);
  Store_field(v_ret, 0, Val_int(bufoff));
  Store_field(v_ret, 1, Val_int(nr_pages));
  CAMLreturn(v_ret);
}  

