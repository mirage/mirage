/*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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

#include <sys/param.h>
#include <stdlib.h>
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/bigarray.h>

/* Return the offset of the bigarray slice against the underlying
 * data buffer (which is recorded in the ba->proxy, if it is set */
CAMLprim value
caml_bigarray_base_offset(value v_ba)
{
  CAMLparam1(v_ba);
  struct caml_ba_array *ba = Caml_ba_array_val(v_ba);
  if (ba->proxy == NULL)
    CAMLreturn(Val_int(0));
  else {
    off_t len = (ba->data - ba->proxy->data);
    CAMLreturn(Val_int(len));
  }
}

/* Shift the array to the left, and ensure that it still remains
 * within the base bounds of the underlying bigarray.
 * Returns bool for success/failure and array is unchanged on fail */
CAMLprim value
caml_bigarray_shift_left(value v_ba, value v_len)
{
  CAMLparam2(v_ba, v_len);
  struct caml_ba_array *ba = Caml_ba_array_val(v_ba);
  /* Only supported for 1 dimensional arrays */
  if (ba->num_dims != 1)
    CAMLreturn(Val_int(0));
  /* If there is no proxy, we are already at the base */
  if (ba->proxy == NULL)
    CAMLreturn(Val_int(0));
  off_t avail = ba->data - ba->proxy->data;
  off_t len = Int_val(v_len);
  /* Ensure we have header space to shift left */
  if (len > avail)
    CAMLreturn(Val_int(0));
  /* Adjust the data pointer and length of the array */
  ba->data = ba->data - len;
  ba->dim[0] = ba->dim[0] + len;
  CAMLreturn(Val_int(1));
}
