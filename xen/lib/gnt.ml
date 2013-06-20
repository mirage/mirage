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

open Lwt

type interface = unit

let interface_open () = ()
let interface_close () = ()

let finally_ f g = try let res = f () in g (); res with exn -> g (); raise exn

type grant_table_index = int32
let grant_table_index_of_int32 x = x
let int32_of_grant_table_index x = x
let string_of_grant_table_index = Int32.to_string
let grant_table_index_of_string = Int32.of_string

let console = 0l (* public/grant_table.h:GNTTAB_RESERVED_CONSOLE *)
let xenstore = 1l (* public/grant_table.h:GNTTAB_RESERVED_XENSTORE *)

type h (* mapped grant *)

module Raw = struct
  external nr_entries : unit -> int = "caml_gnttab_nr_entries"
  external nr_reserved : unit -> int = "caml_gnttab_reserved"
  external init : unit -> unit = "caml_gnttab_init"
  external fini : unit -> unit = "caml_gnttab_fini"
  external grant_access : grant_table_index -> Io_page.t -> int -> bool -> unit = "caml_gnttab_grant_access"
  external end_access : grant_table_index -> unit = "caml_gnttab_end_access"
  external map_grant : grant_table_index -> Io_page.t -> int -> bool -> h option = "caml_gnttab_map"
  external unmap_grant : h -> bool = "caml_gnttab_unmap"
end

module Gnttab = struct
  type interface = unit

  let interface_open () = ()
  let interface_close () = ()

  type grant = {
    domid: int;
    ref: grant_table_index;
  }

  module Local_mapping = struct
    type t = {
      h : h;
      buf: Io_page.t;
    }

    let to_buf t = t.buf
  end

  let map () grant writeable =
    let buf = Io_page.get () in
    match Raw.map_grant grant.ref buf grant.domid (not writeable) with
    | None -> None
    | Some h ->
      Some (Local_mapping.({h; buf}))

  let mapv () grants writeable = failwith "mapv unimplemented"

  let unmap_exn () t =
    if not (Raw.unmap_grant t.Local_mapping.h)
    then failwith "failed to unmap grant: still in use?"

  let with_mapping interface grant writeable fn =
    let mapping = map interface grant writeable in
    try_lwt fn mapping
    finally match mapping with
    | None -> Lwt.return ()
    | Some mapping -> Lwt.return (unmap_exn interface mapping)
end

module Gntshr = struct
  exception Grant_table_full

  type interface = unit

  let interface_open () = ()
  let interface_close () = ()

  type share = {
		refs: grant_table_index list;
		(** List of grant references which have been shared with a foreign domain. *)
		mapping: Io_page.t
		(** Mapping of the shared memory. *)
	}

  let free_list : grant_table_index Queue.t = Queue.create ()
  let free_list_waiters = Lwt_sequence.create ()

  let put r =
    Queue.push r free_list;
    match Lwt_sequence.take_opt_l free_list_waiters with
    |None -> ()
    |Some u -> Lwt.wakeup u ()

  let num_free_grants () = Queue.length free_list

  let rec get () =
    match Queue.is_empty free_list with
    |true ->
      let th, u = Lwt.task () in
      let node = Lwt_sequence.add_r u free_list_waiters  in
      Lwt.on_cancel th (fun () -> Lwt_sequence.remove node);
      th >> get ()
    | false ->
      return (Queue.pop free_list)

  let get_n num =
    let rec gen_gnts num acc =
      match num with
      |0 -> return acc
      |n ->
        lwt gnt = get () in
        gen_gnts (n-1) (gnt :: acc)
    in gen_gnts num []

  let get_nonblock () =
    try Some (Queue.pop free_list) with Queue.Empty -> None

  let get_n_nonblock num =
    let rec aux acc num = match num with
      | 0 -> List.rev acc
      | n ->
        (match get_nonblock () with
         | Some p -> aux (p::acc) (n-1)
         (* If we can't have enough, we push them back in the queue. *)
         | None -> List.iter (fun gntref -> Queue.push gntref free_list) acc; [])
    in aux [] num

  let with_ref f =
    lwt gnt = get () in
    try_lwt f gnt
    finally Lwt.return (put gnt)

  let with_refs n f =
    lwt gnts = get_n n in
    try_lwt f gnts
    finally Lwt.return (List.iter put gnts)

  let grant_access ~domid ~writeable gntref page =
    Raw.grant_access gntref page domid (not writeable)

  let end_access gntref =
    Raw.end_access gntref

  let with_grant ~domid ~writeable gnt page fn =
    grant_access ~domid ~writeable gnt page;
    try_lwt fn ()
    finally Lwt.return (end_access gnt)

  let with_grants ~domid ~writeable gnts pages fn =
    try_lwt
      List.iter (fun (gnt, page) ->
          grant_access ~domid ~writeable gnt page) (List.combine gnts pages);
      fn ()
    finally
      Lwt.return (List.iter end_access gnts)

  let share_pages_exn interface domid count writeable =
    (* First allocate a list of n pages. *)
    let page = Io_page.get ~pages_per_block:count () in
    let pages = Io_page.to_pages page in
    let gntrefs = get_n_nonblock count in
    if gntrefs = [] then raise Grant_table_full
    else
      begin
        List.iter2 (fun g p -> grant_access ~domid ~writeable g p) gntrefs pages;
        { refs = gntrefs; mapping = page }
      end

  let share_pages interface domid count writeable =
    try Some (share_pages_exn interface domid count writeable) with _ -> None

  let munmap_exn interface { refs; _ } =
    List.iter end_access refs
end

let suspend () =
  Raw.fini ()

let resume () =
  Raw.init ()

let _ =
    Printf.printf "gnttab_init: %d\n%!" (Raw.nr_entries () - 1);
    for i = Raw.nr_reserved () to Raw.nr_entries () - 1 do
        Gntshr.put (Int32.of_int i);
    done;
    Raw.init ()


