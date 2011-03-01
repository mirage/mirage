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
#include <stdint.h>

#include <caml/mlvalues.h>
#include "istring.h"

/* Pool to cache istring I/O buffers. 
   If it's full excess buffers are freed, and if
   empty malloc() is used as normal */
#define POOL_SIZE 1024
static unsigned char *pool[POOL_SIZE];
static int pool_pos = -1;

/* Finalizer just sanity checks that the ref count is 0 */
static void
istring_finalize(value v_istring)
{
  istring *i = Istring_val(v_istring);
  if (pool_pos < (POOL_SIZE-1)) {
    pool_pos++;
    pool[pool_pos] = i->buf;
  } else {
    free(i->buf);
  }
  i->buf = NULL;
  Istring_val(v_istring) = NULL;
  free(i);
  return;
}

/* C function to wrap a buffer in an istring caml heap val */
value
istring_alloc(unsigned char *buf, size_t size)
{
  istring *s = caml_stat_alloc(sizeof (struct istring));
  s->buf = buf;
  s->size = size;
  s->ref = 0;
  value v = caml_alloc_final(2, istring_finalize, 1, 100);
  Istring_val(v) = s;
  return v;
}

/* Allocate a raw page as an istring */
CAMLprim value
caml_istring_alloc_page(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_istr);
  unsigned char *page;
  if (pool_pos >= 0) {
    page = pool[pool_pos];
    pool_pos--;
  } else {
    page = (unsigned char *)caml_stat_alloc(4096);
  }
  v_istr = istring_alloc(page, 4096);
  CAMLreturn(v_istr);
}

/* Increment istring ref count */
CAMLprim value
caml_istring_ref_incr(value v_istr)
{
  istring *i = Istring_val(v_istr);
  i->ref++;
  return Val_unit;
}

CAMLprim value
caml_istring_ref_decr(value v_istr)
{
  istring *i = Istring_val(v_istr);
  i->ref--;
  return Val_unit;
}

/* Get total size of istring */
CAMLprim value
caml_istring_size(value v_istr)
{
  return Val_int(Istring_val(v_istr)->size);
}

/* Get a character from an istring */
CAMLprim value
caml_istring_safe_get_char(value v_istr, value v_off)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  if (off >= i->size)
    caml_array_bound_error();
  unsigned char c = i->buf[off];
  return Val_int(c);
}

/* Get a character from an istring, no bounds checking */
CAMLprim value
caml_istring_unsafe_get_char(value v_istr, value v_off)
{
  return Val_int(Istring_val(v_istr)->buf[Int_val(v_off)]);
}

/* Set a character in an istring, no bounds checking */
CAMLprim value
caml_istring_unsafe_set_char(value v_istr, value v_off, value v_ch)
{
  Istring_val(v_istr)->buf[Int_val(v_off)] = Int_val(v_ch);
  return Val_unit;
}

/* Get an ocaml string from an istring */
CAMLprim value
caml_istring_safe_get_string(value v_istr, value v_off, value v_len)
{
  CAMLparam3(v_istr, v_off, v_len);
  CAMLlocal1(v_str);
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  int len = Int_val(v_len);
  if (off+len > i->size)
    caml_array_bound_error();
  v_str = caml_alloc_string(len);
  memcpy(String_val(v_str), i->buf + off, len);
  CAMLreturn(v_str);
}

/* Blit an ocaml string to an istring */
CAMLprim value
caml_istring_safe_blit(value v_istr, value v_off, value v_str)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  int len = caml_string_length(v_str);
  if (len+off > i->size)
    caml_array_bound_error();
  memcpy(i->buf + off, String_val(v_str), len);
  return Val_unit;
}

/* Blit from one view to another */
CAMLprim value
caml_istring_safe_blit_view(value v_dst, value v_dstoff, value v_src, value v_srcoff, value v_len)
{
  istring *dst = Istring_val(v_dst);
  istring *src = Istring_val(v_src);
  int dstoff = Int_val(v_dstoff);
  int srcoff = Int_val(v_srcoff);
  int len = Int_val(v_len);
  /* no need to check src bounds as it will have been safely constructed
     at the ocaml level */
  if (dst->size < dstoff + len)
    caml_array_bound_error();
  memcpy(dst->buf + dstoff, src->buf+srcoff, len);
  return Val_unit;
}

/* Blit from a view to an OCaml string */
CAMLprim value
caml_istring_safe_blit_to_string(value v_dst, value v_dstoff, value v_src, value v_srcoff, value v_len)
{
  istring *src = Istring_val(v_src);
  int dstoff = Int_val(v_dstoff);
  int srcoff = Int_val(v_srcoff);
  int len = Int_val(v_len);
  /* no need to check src bounds as it will have been safely constructed
     at the ocaml level */
  if (caml_string_length(v_dst) < dstoff + len)
    caml_array_bound_error();
  memcpy(String_val(v_dst) + dstoff, src->buf + srcoff, len);
  return Val_unit;
}

/* Get a uint16_t from an istring. big endian */
CAMLprim value
caml_istring_get_uint16_be(value v_istr, value v_off)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  uint16_t r = ((uint16_t)*(i->buf+off+0) << 8) +
                ((uint16_t)*(i->buf+off+1) << 0);
  return Val_int(r);
}

/* Set a uint16_t into an istring. big endian */
CAMLprim value
caml_istring_set_uint16_be(value v_istr, value v_off, value v_val)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  uint16_t v = (uint16_t)Int_val(v_val);
  if (i->size < off+2)
    caml_array_bound_error();
  unsigned char *p = i->buf + off;
  p[0] = (v >> 8) & 255;
  p[1] = v & 255;
  return Val_unit;
}

/* Set a uint32_t into an istring. big endian */
CAMLprim value
caml_istring_set_uint32_be(value v_istr, value v_off, value v_val)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  uint32_t v = Int32_val(v_val);
  if (i->size < off+4)
    caml_array_bound_error();
  unsigned char *p = i->buf + off;
  p[0] = (v >> 24) & 255;
  p[1] = (v >> 16) & 255;
  p[2] = (v >> 8) & 255;
  p[3] = v & 255;
  return Val_unit;
}

/* Set a uint64_t into an istring. big endian */
CAMLprim value
caml_istring_set_uint64_be(value v_istr, value v_off, value v_val)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  uint64_t v = Int64_val(v_val);
  if (i->size < off+8)
    caml_array_bound_error();
  unsigned char *p = i->buf + off;
  p[0] = (v >> 56) & 255;
  p[1] = (v >> 48) & 255;
  p[2] = (v >> 40) & 255;
  p[3] = (v >> 32) & 255;
  p[4] = (v >> 24) & 255;
  p[5] = (v >> 16) & 255;
  p[6] = (v >> 8) & 255;
  p[7] = v & 255;
  return Val_unit;
}

/* Get a uint32_t from an istring. big endian */
CAMLprim value
caml_istring_get_uint32_be(value v_istr, value v_off)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  uint32_t r = ((uint32_t)*(i->buf+off+0) << 24) +
                ((uint32_t)*(i->buf+off+1) << 16) +
                ((uint32_t)*(i->buf+off+2) <<  8) +
                ((uint32_t)*(i->buf+off+3) <<  0);
  return caml_copy_int32(r);
}

/* Get a uint64_t from an istring. big endian.
   XXX: um, verify all these typecasts -avsm */
CAMLprim value
caml_istring_get_uint64_be(value v_istr, value v_off)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  uint32_t a = ((uint32_t)*(i->buf+off+0) << 24) +
                ((uint32_t)*(i->buf+off+1) << 16) +
                ((uint32_t)*(i->buf+off+2) <<  8) +
                ((uint32_t)*(i->buf+off+3) <<  0);
  uint32_t b = ((uint32_t)*(i->buf+off+4) << 24) +
                ((uint32_t)*(i->buf+off+5) << 16) +
                ((uint32_t)*(i->buf+off+6) <<  8) +
                ((uint32_t)*(i->buf+off+7) <<  0);
  uint64_t c = ((uint64_t)a << 32) + b;
  return caml_copy_int64(c);
}

CAMLprim value
caml_istring_safe_set_byte(value v_istr, value v_off, value v_val)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  if (off >= i->size)
    caml_array_bound_error();
  i->buf[off] = (unsigned char)(Int_val(v_val));
  return Val_unit;
}

CAMLprim value
caml_istring_ones_complement_checksum(value v_istr, value v_off, value v_len, value v_initial)
{
  istring *i = Istring_val(v_istr);
  int off = Int_val(v_off);
  int count = Int_val(v_len);
  if (off+count >= i->size)
    caml_array_bound_error ();

  uint32_t sum = Int32_val(v_initial);
  unsigned char *addr = i->buf + off;
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

CAMLprim value
caml_istring_scan_char(value v_istr, value v_off, value v_char)
{
  istring *i = Istring_val(v_istr);
  unsigned char *buf = i->buf;
  int off = Int_val(v_off);
  char c = Int_val(v_char);
  if (off > i->size)
    return Val_int(-1);
  while (off < i->size) {
    if (buf[off] == c)
      return Val_int(off);
    off++;
  }
  return Val_int(-1);
}
