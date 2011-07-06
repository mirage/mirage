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

exception Grant_page_not_found

type num = int32                      (* Grant ref type (grant_ref_t) *)

type r = {
  num: num;                           (* Grant ref number *)
  mutable page: Bitstring.t option;   (* The memory page *)
}

type perm = RO | RW

module Raw = struct
  external nr_entries : unit -> int = "caml_gnttab_nr_entries"
  external nr_reserved : unit -> int = "caml_gnttab_reserved"
  external init : unit -> unit = "caml_gnttab_init"
  external fini : unit -> unit = "caml_gnttab_fini"
  external grant_access : num -> (string*int*int) -> int -> bool -> unit = "caml_gnttab_grant_access"
  external end_access : num -> unit = "caml_gnttab_end_access"
end

let alloc ?page (num:num) =
  { num; page }

let num gnt = gnt.num

let page gnt = 
  match gnt.page with
  |None ->
    let p = Io_page.get_free () in
    gnt.page <- Some p;
    p
  |Some p ->
    p

let free_list : r Queue.t = Queue.create ()
let free_list_condition = Lwt_condition.create ()

let put_free_entry r =
  (match r.page with |None -> () |_ -> r.page <- None);
  Queue.push r free_list;
  Lwt_condition.signal free_list_condition ()

let rec get_free_entry () =
  match Queue.is_empty free_list with
  |true ->
    Lwt_condition.wait free_list_condition >>
    get_free_entry ()
  | false ->
    return (Queue.pop free_list)

let to_string (r:r) = Int32.to_string r.num

let grant_access ~domid ~perm r =
  let page = page r in
  Raw.grant_access r.num page domid (match perm with RO -> true |RW -> false)

let end_access r =
  Raw.end_access r.num

(* Detach a string from the grant *)
let detach r =
  let page =
    match r.page with
    |None -> raise Grant_page_not_found
    |Some p -> p
  in
  Io_page.put_free page;
  r.page <- None;
  page
  
let with_grant ~domid ~perm fn =
  lwt gnt = get_free_entry () in
  grant_access ~domid ~perm gnt;
  try_lwt
    lwt res = fn gnt in
    end_access gnt;
    put_free_entry gnt;
    return res
  with exn -> begin
    end_access gnt;
    put_free_entry gnt;
    fail exn
  end

let get_n ~domid ~perm num =
  let rec gen_gnts num acc =
    match num with
    |0 -> return acc
    |n -> 
      lwt gnt = get_free_entry () in
      grant_access ~domid ~perm gnt;
      gen_gnts (n-1) (gnt :: acc)
  in gen_gnts num []

let with_grants ~domid ~perm num fn =
  let rec gen_gnts num acc =
    match num with
    |0 -> return acc
    |n -> 
      lwt gnt = get_free_entry () in
      grant_access ~domid ~perm gnt;
      gen_gnts (n-1) (gnt :: acc)
  in
  lwt gnts = gen_gnts num [] in
  try_lwt
    lwt res = fn (Array.of_list gnts) in
    List.iter end_access gnts;
    List.iter put_free_entry gnts;
    return res
  with exn -> begin
    List.iter end_access gnts;
    List.iter put_free_entry gnts;
    fail exn
  end

let _ =
    Printf.printf "gnttab_init: %d\n%!" (Raw.nr_entries () - 1);
    for i = Raw.nr_reserved () to Raw.nr_entries () - 1 do
        put_free_entry (alloc (Int32.of_int i));
    done;
    Raw.init ()
