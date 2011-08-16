(*
 * Copyright (c) 2005-2011 Charalampos Rotsos <cr409@cl.cam.ac.uk>
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
open Net

let controller  (remote_addr, remote_port) t =
	OS.Console.log( sprintf "Connection  from %s:%d "
		(Net.Nettypes.ipv4_addr_to_string remote_addr) remote_port);
		
(*		Net.Channel.read_crlf channel >|= Bitstring.string_of_bitstring in *)
 
	let rec echo () =
  	try_lwt
			lwt res = Channel.read_crlf t in
			Channel.write_bitstring t res  Bitstring.string_of_bitstring in 
		 >> echo ()
	with Nettypes.Closed -> return ()
  in echo () 
		

let listen mgr port =
  let src = (None, port) in (* Listen on all interfaces *)
 	(* Flow.listen mgr (`TCPv4 (src, controller)) *)
  Net.Channel.listen mgr (`TCPv4 (src, controller)) 
