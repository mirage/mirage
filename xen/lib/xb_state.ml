(*
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
 *)

(* From include/xen/io/xenbus.h *)
type state =
    |Unknown
    |Initialising
    |InitWait      (* Finished early initialisation but waiting for information
                    * from the peer or hotplug scripts. *)
    |Initialised   (* Waiting for a connection from the peer *)
    |Connected
    |Closing       (* Device is being closed due to an error or an unplug event *)
    |Closed
    |Reconfiguring (* The device is being reconfigured *)
    |Reconfigured

let of_string = function
    |"0" -> Unknown
    |"1" -> Initialising
    |"2" -> InitWait
    |"3" -> Initialised
    |"4" -> Connected
    |"5" -> Closing
    |"6" -> Closed
    |"7" -> Reconfiguring
    |"8" -> Reconfigured
    |_   -> Unknown

let to_string = function 
    |Unknown -> "0"
    |Initialising -> "1"
    |InitWait -> "2"
    |Initialised -> "3"
    |Connected -> "4"
    |Closing -> "5"
    |Closed -> "6"
    |Reconfiguring -> "7"
    |Reconfigured -> "8"

let prettyprint = function
    |Unknown -> "Unknown"
    |Initialising -> "Initialising"
    |InitWait -> "InitWait"
    |Initialised -> "Initalised"
    |Connected -> "Connected"
    |Closing -> "Closing"
    |Closed -> "Closed"
    |Reconfiguring -> "Reconfiguring"
    |Reconfigured -> "Reconfigured"
