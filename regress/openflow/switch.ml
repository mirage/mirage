(* 
 * Copyright (c) 2011 Charalampos Rotsos <cr409@cl.cam.ac.uk>
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
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

open Lwt
open Printf

let resolve t = Lwt.on_success t (fun _ -> ())

module OP = Openflow.Ofpacket
module OS = Openflow.Switch
(* module OE = OS.Event *)

let pp = Printf.printf
let sp = Printf.sprintf




let init controller sw =
  pp "init switch";
  Net.Manager.create_raw (fun mgr interface id ->
      OS.add_port sw mgr interface;
      pp "Created raw socket";
      return ()
    );
  Net.Manager.create_raw (fun mgr interface id ->
      OS.add_port sw mgr interface; 
      return (pp "Created raw socket")
    );
  return () 

let main () =
  Log.info "OF switch" "starting switch";
  Net.Manager.create (fun mgr interface id ->
      let port = 6633 in 
      OS.listen mgr (None, port) init
      >> return (Log.info "OF Controller" "done!")
    );

  pp "Mian terminates\n" ; 
	return () 

