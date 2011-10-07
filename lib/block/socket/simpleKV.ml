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

(** A blocking (so not for heavy use) read-only filesystem interface. *)

open Lwt
open Printf
open OS.Socket

(* The state is just the root directory which is mapped through *)
type t = {
  id: string;
  root: string;
}

let create ~id ~root =
  return (object
    method read filename =
      let fullname = sprintf "%s/%s" root filename in
      (* Open the FD using the manager bindings *)
      match file_open_readonly fullname with
      | Err x -> return None
      | Retry -> assert false 
      | OK fd ->
        (* Construct a stream that reads pages of istrings *)
        return (Some (Lwt_stream.from (fun () ->
          let str = String.create 4096 in
          lwt len = iobind (fun fd -> OS.Socket.read fd str 0 4096) fd in
          match len with
          | 0 -> close fd; return None
          | len -> return (Some (str, 0, len*8))
        )))

    method iter_s fn =
      match opendir root with
      | Err x -> fail (Failure x)
      | Retry -> assert false
      | OK dir -> begin
          let rec loop () =
            match readdir dir with
            |Err x -> return ()
            |Retry -> loop ()
            |OK fname -> fn fname >>= loop
          in
          try_lwt
            loop ()
          finally (match closedir dir with
            | Err x -> fail (Error x)
            | OK () -> return ()
            | Retry -> assert false)
      end

    method size filename =
      let fullname = sprintf "%s/%s" root filename in
      match file_size fullname with
      | Err x -> return None
      | Retry -> assert false
      | OK sz -> return (Some sz)
  end)

let _ =
  let plug_mvar = Lwt_mvar.create_empty () in
  let unplug_mvar = Lwt_mvar.create_empty () in
  (* KV_RO provider *)
  let provider = object(self)
    method id = "RO.Socket"
    method plug = plug_mvar
    method unplug = unplug_mvar
    method create ~deps ~cfg id =
      (* Configuration key "root" defines where to map the K/V filesystem *)
      lwt root = 
        try
          return (List.assoc "root" cfg)
        with Not_found ->
          raise_lwt (Failure "RO.socket: 'root' configuration key not found")
      in
      lwt t = create ~id ~root in
      return OS.Devices.({
        provider=self;
        id=self#id;
        depends=[];
        node=KV_RO t })
    end
  in
  OS.Devices.new_provider provider;
  OS.Main.at_enter (fun () ->
    let fs = ref [] in
    lwt env = OS.Env.argv () in
    Array.iteri (fun i -> function
      |"-simple_kv_ro" -> begin
         match Regexp.Re.(split_delim (from_string ":") env.(i+1)) with
         |[p_id;root] -> 
           let p_cfg = ["root",root] in
           fs := ({OS.Devices.p_dep_ids=[]; p_cfg; p_id}) :: !fs
         |_ -> failwith "Socket.RO: bad -simple_kv_ro flag, must be id:root_dir"
      end
      |_ -> ()) env;
    Lwt_list.iter_s (Lwt_mvar.put plug_mvar) !fs
  )

