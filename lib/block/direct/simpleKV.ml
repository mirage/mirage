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
            printf "Read file: %s %Lu[%Lu]\n%!" name offset len;
            if num = 7 then
              read_page (Int64.add off 8L)
            else
              parse_page (num+1)
          end
      | { _ } -> return ()
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
      let file = Hashtbl.find files filename in
      printf "SimpleKV.read: %s offset %Lu\n%!" filename file.offset;
      let cur_seg = ref None in
      let pos = ref 0L in
      let rec readfn () =
        (* Check if we have an active segment *)
        match !cur_seg with
        |Some page ->
          (* Traversing an existing segment, so get next in element *)
          let r =
            (* If this is the end of the file, might need to be a partial view *)
            let pos' = Int64.add !pos 4096L in
            if pos' > file.len then begin
              let sz = Int64.sub file.len !pos in
              pos := Int64.add !pos sz;
              cur_seg := None;
              Bitstring.subbitstring page 0 (Int64.to_int sz * 8)
            end else begin
              pos := pos';
              cur_seg := None;
              page
            end
          in
          return (Some r)
        |None ->
          if !pos >= file.len then begin
            return None (* EOF *)
          end else begin
            (* Need to retrieve more data, get another page *)
            (* TODO readv instead of one page at a time *)
            lwt page = vbd#read_page (Int64.add file.offset !pos) in
            cur_seg := Some page;
            readfn ()
          end
        in
        return (Some (Lwt_stream.from readfn))
      with
      | Not_found -> return None
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
         printf "dep %s\n%!" ent.id;
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

