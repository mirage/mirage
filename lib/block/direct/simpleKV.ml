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

(* A simple read-only block filesystem *)
open Lwt
open Printf

type file = {
  name: string;
  offset: int64;
  len: int64;
}

let create ~(id:string) ~(vbd:OS.Devices.blkif) : OS.Devices.kv_ro Lwt.t =
(*  printf "SimpleKV.create: creating %s from VBD %s\n%!" id vbd#id; *)
  (* Attach and parse the index file *)
  let files = Hashtbl.create 7 in
  let rec read_page off =
    lwt page = vbd#read_page off in
    let rec parse_page num =
      let loff = num * 512 in
      let bs = Bitstring.subbitstring page (loff * 8) (512 * 8) in
      bitmatch bs with
      | { 0xDEADBEEFl:32; offset:64; len:64; namelen:32:bind(Int32.to_int namelen * 8); name:namelen:string } ->
          if Int64.rem offset 512L <> 0L then
            fail (Failure (sprintf "unaligned offset file found: offset=%Lu" offset))
          else begin
            Hashtbl.add files name { name; offset; len };
            (* printf "SimpleKV: %s INIT: Read file: %s %Lu[%Lu]\n%!" id name offset len; *)
            if num = 7 then
              read_page (Int64.add off 4096L)
            else
              parse_page (num+1)
          end
      | { _ } ->
(*          printf "SimpleKV: %s init done (%d files)\n%!" id (Hashtbl.length files); *)
          return ()
    in
    parse_page 0 in
  read_page 0L >>
  return (object
    method iter_s fn =
      let files = Hashtbl.fold (fun k v a -> k :: a) files [] in
      Lwt_list.iter_s fn files

    method size name =
      try return (Some (Hashtbl.find files name).len)
      with Not_found -> return None

    method read filename =
      try
      (* Strip out any leading / character *)
      let filename =
        if String.length filename > 0 && filename.[0] = '/' then
          String.sub filename 1 (String.length filename - 1)
        else 
          filename 
      in
      (* printf "SimpleKV.read %s\n%!" filename; *)
      let file = Hashtbl.find files filename in
      let pos = ref 0L in
      (* Return a stream for the file *)
      return (Some (Lwt_stream.from (fun () ->
        if !pos < file.len then begin
          (* Still data to read *)
          (* printf "SimpleKV.read %s offset=%Lu pos=%Lu %!" filename file.offset !pos; *)
          lwt p = vbd#read_page (Int64.add file.offset !pos) in
          match (Int64.add !pos 4096L) < file.len with
          |true -> (* Read full page *)
             (* printf "full page\n%!"; *)
             pos := Int64.add !pos 4096L;
             return (Some p)
          |false -> (* EOF, short read *)
             (* printf "short page\n%!"; *)
             let p' = Bitstring.subbitstring p 0 ((Int64.to_int (Int64.sub file.len !pos)) * 8) in
             pos := file.len; 
             return (Some p')
        end else begin
          (* printf "SimpleKV.read CLOSE: %s\n%!" filename; *)
          return None
        end
      )))
      with
      | Not_found ->
(*          printf "SimpleKV: file %s not found\n%!" filename; *)
          return None
   end )

let _ =
  let plug_mvar = Lwt_mvar.create_empty () in
  let unplug_mvar = Lwt_mvar.create_empty () in
  (* KV_RO provider *)
  let provider = object(self)
    method id = "Direct.SimpleKV"
    method plug = plug_mvar
    method unplug = unplug_mvar
    method create ~deps ~cfg id =
      let open OS.Devices in
      (* One dependency: a Blkif entry to mount *)
      match deps with 
      |[{node=Blkif vbd} as ent] ->
(*         printf "SimpleKV.provider: %s depends on vbd %s\n%!" id ent.id; *)
         lwt t = create ~id ~vbd in
         return OS.Devices.({
           provider=self;
           id=self#id;
           depends=deps;
           node=KV_RO t 
         })
      |_ -> raise_lwt (Failure "bad deps")
    end
  in
  OS.Devices.new_provider provider;
(*
  OS.Main.at_enter (fun () ->
    let fs = ref [] in
    lwt env = OS.Env.argv () in
    Array.iteri (fun i -> function
      |"-simple_kv_ro" -> begin
         match Regexp.Re.(split_delim (from_string ":") env.(i+1)) with
         |[p_id;p_dep_id] ->
           let p_dep_ids=[p_dep_id] in
           fs := ({OS.Devices.p_dep_ids; p_cfg=[]; p_id}) :: !fs
         |_ -> failwith "Direct.SimpleKV: bad -simple_kv_ro flag, must be id:dep_id"
      end
      |_ -> ()) env;
    Lwt_list.iter_s (Lwt_mvar.put plug_mvar) !fs
  )

*) ()
