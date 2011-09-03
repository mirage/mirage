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

type id = string

(** An 'a provider lets us listen for new device ids, and create/destroy them *)
type 'a provider = <
  id: string;             (* Human-readable name of provider *)
  create: id -> 'a Lwt.t; (* Create a device from an id *)
  destroy: 'a -> unit;    (* Destroy a device *)
  plug: id Lwt_mvar.t;    (* Read this mvar when new devices show up *)
  unplug: id Lwt_mvar.t;  (* Read this mvar for when devices are unplugged *)
>

(** Loop to read a value from an mvar and apply function to it repeatedly *)
let mvar_loop mvar fn =
  while_lwt true do
     lwt x = Lwt_mvar.take mvar in
     fn x
  done

type 'a mgr = {
  devices: (id, unit Lwt.t) Hashtbl.t;
  fn: 'a mgr -> id -> 'a -> unit Lwt.t;
}
  
module Blkif = struct

  (* The providers must be registered at start-of-day before Lwt kicks off *) 
  let providers : Types.blkif provider list ref = ref []
  let new_provider p = providers := p :: !providers

  (* User registers a callback function that is passed the id and instances
     of new block devices as they arrive. When the device is unplugged, the
     device thread that is spawned on plugging is then cancelled. *)
  let manager fn =
    let mgr = { fn; devices=Hashtbl.create 1 } in
    printf "Blkif.manager: init\n%!";
    (* Listen for provider events in parallel and loop *)
    Lwt_list.iter_p (fun p ->
      printf "Blkif.manager: init threads for provider %s\n%!" p#id;
      let plug_t = mvar_loop p#plug (fun id ->
        printf "Device: plug %s from provider %s\n%!" id p#id;
        lwt dev = p#create id in
        let th,u = Lwt.task () in
        let user_t = fn mgr id dev in
        Lwt.on_cancel th (fun _ -> printf "destroy\n%!"; p#destroy dev);
        Hashtbl.add mgr.devices id (th <?> user_t);
        return ()
      ) in
      let unplug_t = mvar_loop p#unplug (fun id ->
        printf "Device: unplug %s from provider %s\n%!" id p#id;
        (try Lwt.cancel (Hashtbl.find mgr.devices id)
        with Not_found -> ());
        return ()
      ) in
      plug_t <&> unplug_t
    ) !providers >>
    return (printf "do not reach\n%!")
end
