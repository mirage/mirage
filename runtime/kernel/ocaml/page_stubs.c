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

/* Reads an OCaml string out of a raw page into an OCaml string */
CAMLprim value
caml_page_read_to_string(value v_page, value v_off, value v_len, value v_str)
{
    CAMLparam4(v_page, v_off, v_len, v_str);
    char *page = (char *)v_page;
    if (Int_val(v_off) + Int_val(v_len) >= PAGE_SIZE || caml_string_length(v_str) < Int_val(v_len))
        caml_array_bound_error();
    memcpy(String_val(v_str), page + Int_val(v_off), Int_val(v_len));
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
