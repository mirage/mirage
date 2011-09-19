(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

exception Error of string

type id = string

type t = {
  id: id;
  fd: [`rw_file] Socket.fd;
}

let read_page t offset =
  Socket.(iobind (lseek t.fd) offset) >>
  let buf = String.create 4096 in (* XXX pool? *)
  lwt rd = Socket.(iobind (read t.fd buf 0) 4096) in
  return (buf,0, rd*8)

let create ~id ~filename : Devices.blkif Lwt.t =
  printf "Unix.Blkif: create %s %s\n%!" id filename;
  lwt fd =
    try_lwt
      Socket.(iobind file_open_readwrite filename)
    with Socket.Error err -> 
      printf "Blkif: failed to open VBD %s\n%!" filename;
      fail (Error err)
  in
  printf "Unix.Blkif: success\n%!";
  let t = {id; fd} in
  return (object
    method id = id
    method read_page = read_page t
    method sector_size = 4096
    method ppname = sprintf "Unix.blkif:%s(%s)" id filename
    method destroy = Socket.close t.fd
  end)

(* Register Unix.Blkif provider with the device manager *)
let _ =
  let plug_mvar = Lwt_mvar.create_empty () in
  let unplug_mvar = Lwt_mvar.create_empty () in
  let provider = object(self)
     method id = "Unix.Blkif"
     method plug = plug_mvar 
     method unplug = unplug_mvar
     method create ~deps ~cfg id =
      (* Config key "filename" decides the name of the VBD *)
      lwt filename =
        try
          return (List.assoc "filename" cfg)
        with Not_found ->
          raise_lwt (Failure "UNIX.Blkif: 'filename' configuration key not found")
      in
      lwt blkif = create ~id ~filename in
      let entry = Devices.({
        provider=self; 
        id=self#id; 
        depends=[];
        node=Blkif blkif }) in
      return entry
  end in
  Devices.new_provider provider;
  (* Iterate over the plugged in VBDs and plug them in *)
  Main.at_enter (fun () ->
    let vbds = ref [] in
    lwt env = Env.argv () in
    Array.iteri (fun i -> function
      |"-vbd" -> begin
        match Regexp.Re.(split_delim (from_string ":") env.(i+1)) with
        |[p_id;filename] ->
          let p_cfg = ["filename",filename] in
          let p_dep_ids=[] in
          printf "found vbd %s filename %s\n%!" p_id filename;
          vbds := ({Devices.p_dep_ids; p_cfg; p_id}) :: !vbds
        |_ -> failwith "Unix.Blkif: bad -vbd flag, must be id:filename"
      end
      |_ -> ()) env;
    Lwt_list.iter_s (Lwt_mvar.put plug_mvar) !vbds
  )
