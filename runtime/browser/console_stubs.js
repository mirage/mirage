/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
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

// Need to have a node whose ID is console_window to hold all the consoles

var nb_console = 0;

function console_create() {
		nb_console++;
    var new_console = document.createElement('div');
		new_console.id = "console_"+nb_console;
    var con = document.getElementById("console_window");
    if (con) con.appendChild(new_console);
    return new_console;
}

function console_write(con, data, off, len) {
    if (typeof data == "object")
      data = data.toString();
    text = data.substring(off, off+len);
    con.innerHTML += "<pre>"+text+"</pre>";
    if (window.console) console.log(con.id + ": " + text);
}
