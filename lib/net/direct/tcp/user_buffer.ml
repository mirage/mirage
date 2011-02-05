(*
 * Copyright (c) 2010 http://github.com/barko 00336ea19fcb53de187740c490f764f4
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

(* A bounded queue to receive data segments and let readers block on 
   receiving them. Also supports a monitor that is informed when the
   queue size changes *)
module Rx = struct
  
  type t = {
    q: OS.Istring.View.t Lwt_sequence.t; 
    writers: unit Lwt.u Lwt_sequence.t;
    readers: OS.Istring.View.t Lwt.u Lwt_sequence.t;
    mutable watcher: int32 Lwt_mvar.t option;
    mutable max_size: int32;
    mutable cur_size: int32;
  }
  
  let create ~max_size =
    let q = Lwt_sequence.create () in
    let writers = Lwt_sequence.create () in
    let readers = Lwt_sequence.create () in
    let watcher = None in
    let cur_size = 0l in
    { q; writers; readers; max_size; cur_size; watcher }
  
  let notify_size_watcher t =
    match t.watcher with
    |None -> return ()
    |Some w -> Lwt_mvar.put w t.cur_size
    
  let add_r t s =
    if t.cur_size > t.max_size then
      let th,u = Lwt.task () in
      let node = Lwt_sequence.add_r u t.writers in
      Lwt.on_cancel th (fun _ -> Lwt_sequence.remove node);
      (* Update size before blocking, which may push cur_size above max_size *)
      t.cur_size <- Int32.(add t.cur_size (of_int (OS.Istring.View.length s)));
      notify_size_watcher t >>
      lwt () = th in
      ignore(Lwt_sequence.add_r s t.q);
      return ()
    else begin
      (match Lwt_sequence.take_opt_l t.readers with
      |None ->
        t.cur_size <- Int32.(add t.cur_size (of_int (OS.Istring.View.length s)));
        ignore(Lwt_sequence.add_r s t.q);
        notify_size_watcher t
      |Some u -> 
        return (Lwt.wakeup u s)
      );
    end
      
  let take_l t =
    if Lwt_sequence.is_empty t.q then begin
      let th,u = Lwt.task () in
      let node = Lwt_sequence.add_r u t.readers in
      Lwt.on_cancel th (fun _ -> Lwt_sequence.remove node);
      th
    end else begin
      let s = Lwt_sequence.take_l t.q in
      t.cur_size <- Int32.(sub t.cur_size (of_int (OS.Istring.View.length s)));
      notify_size_watcher t >>
      if t.cur_size < t.max_size then begin
        match Lwt_sequence.take_opt_l t.writers with
        |None -> ()
        |Some w -> Lwt.wakeup w ()
      end;
      return s
    end
  
  let cur_size t = t.cur_size
  let max_size t = t.max_size
  
  let monitor t mvar =
    t.watcher <- Some mvar
  
  let set_max_size t new_max_size =
    if new_max_size > t.max_size then (
      (* the new max size is bigger than the current one, wake up
         writers (if any) until queue is full or all writers have
         written *)
      let rec loop () =
        if t.cur_size < t.max_size then
          match Lwt_sequence.take_opt_l t.writers with
          |Some w -> Lwt.wakeup w (); loop ()
          |None -> ()
      in
      (* commit to the new length before waking up writers, because
         writers might again increase the max length *)
      t.max_size <- new_max_size;
      loop ()
    )
    else if new_max_size > 0l then
      t.max_size <- new_max_size
end

(* The transmit queue simply advertises how much data is allowed to be
   written, and a wakener for when it is full. It is up to the application
   to decide how to throttle or breakup its data production with this
   information.
*)
module Tx = struct

  type t = {
    wnd: Window.t;
    writers: unit Lwt.u Lwt_sequence.t;
  }

  let create ~wnd = 
    let writers = Lwt_sequence.create () in
    { wnd; writers }

  (* Check how many bytes are available to write *)
  let available t = 
    Window.tx_wnd t.wnd

  (* Wait until at least sz bytes are available *)
  let rec wait_for t sz =
    if (available t) >= sz then begin
      return ()
    end
    else begin
      let th,u = Lwt.task () in
      let node = Lwt_sequence.add_r u t.writers in
      Lwt.on_cancel th (fun _ -> Lwt_sequence.remove node);
      th >>
      wait_for t sz
    end

  (* Indicate that more bytes are available for waiting writers.
     Note that sz does not take window scaling into account, and so
     should be passed as unscaled (i.e. from the wire) here.
     Window will internally scale it up. *)
  let free t sz =
    Window.set_tx_wnd t.wnd sz;
    match Lwt_sequence.take_opt_l t.writers with
    |None -> ()
    |Some w -> Lwt.wakeup w ()
   
end
