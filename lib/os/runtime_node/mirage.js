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

// Missing ocaml functions

function caml_ml_output_char(vchannel, ch) {
    console.log("caml_ml_output_char is not implemented");
}
