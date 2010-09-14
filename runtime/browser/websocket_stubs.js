/*
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

function ws_supported() {
    return ("WebSocket" in window)
}

function ws_create(url, evtch, callback) {
    if (ws_supported()) {
        var ws = new WebSocket(url);
        ws.onmessage = function (event) {
            if (window.console) console.debug("onmessage: ev_callback[%d] <- 1", evtch);
            callback(event.data);   // fill-up some ocaml buffer
            ev_callback[evtch] = 1; // wake-up the lwt threads
        };
        ws.onopen = function() {
            if (window.console) console.debug("onopen: ev_callback[%d] <- 1", evtch);
            ev_callback[evtch] = 1; // wake-up the opener
        };
        ws.onclose = function() {
            if (window.console) console.debug("onclose");
        }
        return ws;
    } else
        if (window.console) console.error("websocket is not supported on this browser");
}

function ws_send(ws, str) {
    if (ws_supported()) {
        if (typeof str == "object") str = str.toString();
        ws.send(str);
    };
}