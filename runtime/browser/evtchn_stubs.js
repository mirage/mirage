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

var NR_EVENTS=128;
var ev_fds = new Array(NR_EVENTS);
var ev_callback = new Array(NR_EVENTS);

function caml_evtchn_init() {
    if (window.console) console.debug("ev_callback init");
    for (i=0; i++; i<NR_EVENTS) {
        ev_callback[i] = 0;
    };
    return ev_callback;
}

function evtchn_block_domain(tm) {
	  if (window.console) console.debug("block(%d)", tm);
    if (tm >= 0)
        setTimeout("ocamljs$caml_named_value('evtchn_run')(0)", tm * 1000);
}

function evtchn_activate() {
    ocamljs$caml_named_value('evtchn_run')(0)
}