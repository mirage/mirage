//
// Copyright (c) 2011 Thomas Gazagnaire <thomas@gazagnaire.org>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

var util = require('util');
var net = require('net');

// Console
function console_create() {
    return 0;
}

function console_write(con, data, off, len) {
    if (typeof data == "object")
      data = data.toString();
    text = data.substring(off, off+len);
    util.log(text);
}

// Istring

function caml_istring_alloc_page() {
    var b = new Buffer(4096);
    return b;
};
function caml_istring_size(t) {
    return t.length;
};
function caml_istring_safe_set_byte(t,off,i) {
    // XXX: TODO bound checking
    t[off] = i;
};
function caml_istring_set_uint16_be(t,off,i) {
    t[off]   = (i >> 8) & 255;
    t[off+1] = v & 255;
};
function caml_istring_set_uint32_be(t,off,i32) {
    t[off]   = (v >> 24) & 255;
    t[off+1] = (v >> 16) & 255;
    t[off+2] = (v >> 8)  & 255;
    t[off+3] = v & 255;
};
function caml_istring_set_utin64_be(t,off,i64) {
    t[off]   = (v >> 56) & 255;
    t[off+1] = (v >> 48) & 255;
    t[off+2] = (v >> 40) & 255;
    t[off+3] = (v >> 32) & 255;
    t[off+4] = (v >> 24) & 255;
    t[off+5] = (v >> 16) & 255;
    t[off+6] = (v >> 8)  & 255;
    t[off+7] = v & 255;
};

// string -> istring
function caml_istring_safe_blit(dst,off,src) {
    var src = new Buffer(src);
    src.copy(dst, off, 0);
};

// istring -> istring
function caml_istring_safe_blit_view(dst, dstoff, src, srcoff, len) {
    src.copy(dst, dstoff, srcoff, len);
};

// istring -> string
function caml_istring_safe_blit_to_string(dst, dstoff, src, srcoff, len) {
    var dst = new Buffer(dst);
    src.copy(dst, dstoff, srcoff, len);
};

function caml_istring_safe_get_char(t,off) {
    return t[off];
};

function caml_istring_unsafe_get_char(t,off) {
    return t[off];
};

function caml_istring_unsafe_set_char(t,off,c) {
    t[off] = c;
};

// istring -> string
function caml_istring_safe_get_string(src,off,len) {
    var dst = new Buffer(len);
    scr.copy(dst, 0, dstoff, len);
    return dst;
};

function caml_istring_get_uint16_be(t,off) {
    var r1 = t[off] << 8;
    var r2 = t[off+1];
    return (r1 + r2);
};

function caml_istring_get_uint32_be(t,off) {
    var r1 = t[off] << 24;
    var r2 = t[off] << 16;
    var r3 = t[off] << 8;
    var r4 = t[off];
    return (r1 + r2 + r3 + r4);
};

function caml_istring_get_uint64_be(t,off) {
    var r1 = t[off] << 24;
    var r2 = t[off] << 16;
    var r3 = t[off] << 8;
    var r4 = t[off];
    var r5 = t[off] << 24;
    var r6 = t[off] << 16;
    var r7 = t[off] << 8;
    var r8 = t[off];
    return (r1 + r2 + r3 + r4) << 32 + (r5 + r6 + r7 + r8);
};

function caml_istring_ones_complement_checksum(t,off,len,init) {
    var count = len;
    var sum = init;
    
    for (var i=0; i++; i < len/2)
        sum += (t[off + 2*i] << 8) + t[off + 2*i + 1];
    if ((len % 2) == 1)
        sum += t[off + len - 1];
    while (sum >> 16)
        sum = (sum & 0xffff) + (sum >> 16);
    return (~sum);
};

function caml_istring_scan_char(t,off,c) {
    var i = off;
    while (i < t.length) {
        if (t[i] == c)
            return i;
        i++;
    };
    return -1;
};

// Main

var callback = (function () {
    console.log("WARNING: no callback function registered!");
});

function caml_block_domain() {
};

function caml_block_domain_with_timeout(tm) {
    setTimeout(callback, tm);
};
function caml_callback_register(fn) {
    callback = fn;
};