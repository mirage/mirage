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

#include <mini-os/x86/os.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

/* Reads an OCaml string out of a raw page into an OCaml string 
 * Same signature as String.blit except the source is a page 
 */
CAMLprim value
caml_page_read_to_string(value v_src, value v_srcoff, value v_dst, value v_dstoff, value v_len)
{
    CAMLparam5(v_src, v_srcoff, v_dst, v_dstoff, v_len);
    char *page = (char *)v_src;
    if (Int_val(v_srcoff) + Int_val(v_len) >= PAGE_SIZE || caml_string_length(v_dst) + Int_val(v_dstoff) < Int_val(v_len))
        caml_array_bound_error();
    memcpy(String_val(v_dst) + Int_val(v_dstoff), page + Int_val(v_srcoff), Int_val(v_len));
    CAMLreturn(Val_unit);
}

/* Read an OCaml character out of a raw page, mods offset with PAGE_SIZE  */
CAMLprim value
caml_page_safe_get(value v_page, value v_off)
{
    int off = Int_val(v_off) % PAGE_SIZE;
    return Int_val(*((char *)v_page + off));
}

/* Set a byte in a raw page, mods offset with PAGE_SIZE */
CAMLprim value
caml_page_safe_set(value v_page, value v_off, value v_char)
{
    int off = Int_val(v_off) % PAGE_SIZE;
    *((char *)v_page + off) = Int_val(v_char);
    return Val_unit;
}
