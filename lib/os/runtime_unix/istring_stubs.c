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

#include <stdio.h>
#include <string.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/callback.h>

#define Istring_val(x) (*((istring **)(Data_custom_val(x))))

typedef struct istring {
  char *buf;         /* Pointer to buffer */
  size_t size;       /* Total length of buffer */
  unsigned int ref;  /* Reference count */
} istring;

typedef struct iview {
  istring *s;
} iview;

static void
istring_finalize(value v_istring)
{
  istring *istr = Istring_val(v_istring);
  fprintf(stderr, "istring_finalize\n");
  if (istr->ref != 0) 
    caml_failwith("istr ref != 0");
  free(istr->buf);
  istr->buf = NULL;
  return;
}

/* C function to wrap a buffer in an istring caml heap val */
value
alloc_istring(char *buf, size_t size)
{
  istring *s = caml_stat_alloc(sizeof (struct istring));
  s->buf = buf;
  s->size = size;
  s->ref = 0;
  return caml_alloc_final(2, istring_finalize, 1, 100);
}

/* Allocate an istring via malloc */
CAMLprim value
caml_alloc_istring(value v_size)
{
  CAMLparam1(v_size);
  CAMLlocal1(v_istr);
  size_t size = Int_val(v_size);
  char *buf = caml_stat_alloc(size);
  v_istr = alloc_istring(buf, size);
  CAMLreturn(v_istr);
}

/* Get total size of istring */
CAMLprim value
caml_istring_size(value v_istr)
{
  return Val_int(Istring_val(v_istr)->size);
}

/* Get a character from an istring */
CAMLprim value
caml_istring_safe_get(value v_istr, value v_off)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  if (off >= i->size)
    caml_array_bound_error();
  return Val_int(i->buf[off]);
}

/* Append a caml string to an istring */
CAMLprim value
caml_istring_safe_blit(value v_istr, value v_off, value v_str)
{
  istring *i = Istring_val(v_istr);
  int len = caml_string_length(v_str);
  int off = Int_val(v_off);
  if (len+off >= i->size)
    caml_array_bound_error();
  memcpy(i->buf + off, String_val(v_str), len);
  return Val_unit;
}
