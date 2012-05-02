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

type r = int32 (* Grant ref number *)

type perm = RO | RW

module Raw = struct
  external nr_entries : unit -> int = "caml_gnttab_nr_entries"
  external nr_reserved : unit -> int = "caml_gnttab_reserved"
  external init : unit -> unit = "caml_gnttab_init"
  external fini : unit -> unit = "caml_gnttab_fini"
  external grant_access : r -> (string*int*int) -> int -> bool -> unit = "caml_gnttab_grant_access"
  external end_access : r -> unit = "caml_gnttab_end_access"
end

let to_int32 x = x
let of_int32 x = x
let to_string (r:r) = Int32.to_string (to_int32 r)

let free_list : r Queue.t = Queue.create ()
let free_list_waiters = Lwt_sequence.create ()

let iter_option f = function
  | None -> ()
  | Some x -> f x

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

let with_ref f =
  lwt gnt = get () in
  try_lwt
    lwt res = f gnt in
    put gnt;
    return res
  with exn -> begin
    put gnt;
    fail exn
  end

let with_refs n f =
  lwt gnts = get_n n in
  try_lwt
    lwt res = f gnts in
    List.iter put gnts;
    return res
  with exn -> begin
    List.iter put gnts;
    fail exn
  end

let grant_access ~domid ~perm r page =
  Raw.grant_access r (Io_page.to_bitstring page) domid (match perm with RO -> true |RW -> false)

let end_access r =
  Raw.end_access r

let with_grant ~domid ~perm gnt page fn =
  grant_access ~domid ~perm gnt page;
  try_lwt
    lwt res = fn () in
    end_access gnt;
    return res
  with exn -> begin
    end_access gnt;
    fail exn
  end

let with_grants ~domid ~perm gnts pages fn =
  try_lwt
    List.iter (fun (gnt, page) -> grant_access ~domid ~perm gnt page) (List.combine gnts pages);
    lwt res = fn () in
    List.iter end_access gnts;
    return res
  with exn -> begin
    List.iter end_access gnts;
    fail exn
  end

let _ =
    Printf.printf "gnttab_init: %d\n%!" (Raw.nr_entries () - 1);
    for i = Raw.nr_reserved () to Raw.nr_entries () - 1 do
        put (Int32.of_int i);
    done;
    Raw.init ()
