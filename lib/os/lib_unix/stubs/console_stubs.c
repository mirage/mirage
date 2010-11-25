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
#include <caml/alloc.h>

/* Dont bother with full console, just direct everything to
   stderr, so console_create is a noop for now */

CAMLprim value
console_create(value v_unit)
{
    return Val_int(0);
}

CAMLprim value
console_write(value v_cons, value v_buf, value v_off, value v_len)
{
    int len = Int_val(v_len);
    char buf[len+1];
    memcpy(buf, String_val(v_buf)+Int_val(v_off), Int_val(v_len));
    buf[len] = '\0';
    fprintf(stderr, "%s", buf);
    fflush(stderr);
    return Val_unit;
}
