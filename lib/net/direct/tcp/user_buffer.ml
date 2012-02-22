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
open Printf

(* A bounded queue to receive data segments and let readers block on 
   receiving them. Also supports a monitor that is informed when the
   queue size changes *)
module Rx = struct
  
  type t = {
    q: Bitstring.t Lwt_sequence.t; 
    writers: unit Lwt.u Lwt_sequence.t;
    readers: Bitstring.t Lwt.u Lwt_sequence.t;
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
      t.cur_size <- Int32.(add t.cur_size (of_int (Bitstring.bitstring_length s / 8)));
      notify_size_watcher t >>
      lwt () = th in
      ignore(Lwt_sequence.add_r s t.q);
      return ()
    else begin
      (match Lwt_sequence.take_opt_l t.readers with
      |None ->
        t.cur_size <- Int32.(add t.cur_size (of_int (Bitstring.bitstring_length s / 8)));
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
      t.cur_size <- Int32.(sub t.cur_size (of_int (Bitstring.bitstring_length s / 8)));
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
    txq: Segment.Tx.q;
    buffer: Bitstring.t Lwt_sequence.t;
    max_size: int32;
    mutable bufbytes: int32;
  }

  let create ~max_size ~wnd ~txq = 
    let buffer = Lwt_sequence.create () in
    let writers = Lwt_sequence.create () in
    let bufbytes = 0l in
    { wnd; writers; txq; buffer; max_size; bufbytes }

  let len data = 
    Int32.of_int (Bitstring.bitstring_length data / 8)

  (* Check how many bytes are available to write to output buffer *)
  let available t = 
    let a = Int32.sub t.max_size t.bufbytes in
    match a < (Int32.of_int (Window.tx_mss t.wnd)) with
    | true -> 0l
    | false -> a

  (* Check how many bytes are available to write to wire*)
  let available_cwnd t = 
    Window.tx_available t.wnd

  (* Wait until at least sz bytes are available in the window *)
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

  let rec clear_buffer t = 
    let rec addon_more curr_data l =
      match Lwt_sequence.take_opt_l t.buffer with
      | None ->
          (* printf "out at 1\n%!";*)
	  Bitstring.concat (List.rev curr_data)
      | Some s ->
          let s_len = len s in
          match s_len > l with
          | true -> 
              (*printf "out at 2 %lu %lu\n%!" s_len l;*)
              let _ = Lwt_sequence.add_l s t.buffer in
              Bitstring.concat (List.rev curr_data)
          | false -> 
	      t.bufbytes <- Int32.sub t.bufbytes s_len;
              addon_more (s::curr_data) (Int32.sub l s_len)
    in
    let get_pkt_to_send () =
      let avail_len = min (available_cwnd t) (Int32.of_int (Window.tx_mss t.wnd)) in
      let s = Lwt_sequence.take_l t.buffer in
      let s_len = len s in
      match s_len > avail_len with
      | true -> 
          (* not enough opened up - return pkt to buffer *)
          let _ = Lwt_sequence.add_l s t.buffer in
          None
      | false -> 
          match s_len < avail_len with
          | true -> 
	      t.bufbytes <- Int32.sub t.bufbytes s_len;
	      Some (addon_more (s::[]) (Int32.sub avail_len s_len))
          | false -> 
	      t.bufbytes <- Int32.sub t.bufbytes s_len;
	      Some s
    in
    match Lwt_sequence.is_empty t.buffer with
    | true -> return ()
    | false -> 
        match get_pkt_to_send () with
        | None -> return ()
        | Some pkt -> 
            Segment.Tx.output t.txq pkt >>
            clear_buffer t



  let write t data =
    let l = len data in
    let mss = Int32.of_int (Window.tx_mss t.wnd) in
    match Lwt_sequence.is_empty t.buffer && l = mss with
    | false -> 
	t.bufbytes <- Int32.add t.bufbytes l;
        let _ = Lwt_sequence.add_r data t.buffer in
	if t.bufbytes < mss then
          return ()
	else
	  clear_buffer t
    | true -> 
	let avail_len = available_cwnd t in
        match avail_len < l with
	| true -> 
	    t.bufbytes <- Int32.add t.bufbytes l;
            let _ = Lwt_sequence.add_r data t.buffer in
            return ()
	| false -> 
            Segment.Tx.output t.txq data


  let write_nodelay t data =
    let l = len data in
    match Lwt_sequence.is_empty t.buffer with
    | false -> 
	t.bufbytes <- Int32.add t.bufbytes l;
        let _ = Lwt_sequence.add_r data t.buffer in
        return ()
    | true -> 
	let avail_len = available_cwnd t in
        match avail_len < l with
	| true -> 
	    t.bufbytes <- Int32.add t.bufbytes l;
            let _ = Lwt_sequence.add_r data t.buffer in
            return ()
	| false -> 
            Segment.Tx.output t.txq data


  let inform_app t = 
    match Lwt_sequence.take_opt_l t.writers with
    | None -> return ()
    | Some w ->
	Lwt.wakeup w ();
	return ()

  (* Indicate that more bytes are available for waiting writers.
     Note that sz does not take window scaling into account, and so
     should be passed as unscaled (i.e. from the wire) here.
     Window will internally scale it up. *)
  let free t sz =
    clear_buffer t >>
    inform_app t
   
end
