(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_io, modified for MirageOS
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (C) 2009 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

open Lwt

module IO(Channel:Mlnet.Channel) = struct

exception Channel_closed of string

(* Minimum size for buffers: *)
let min_buffer_size = 16

let check_buffer_size fun_name buffer_size =
  if buffer_size < min_buffer_size then
    Printf.ksprintf invalid_arg "Lwt_io.%s: too small buffer size (%d)" fun_name buffer_size
  else if buffer_size > Sys.max_string_length then
    Printf.ksprintf invalid_arg "Lwt_io.%s: too big buffer size (%d)" fun_name buffer_size
  else
    ()

let default_buffer_size = ref 4096

let close_fd fd =
  try
    Channel.close fd;
    return ()
  with exn ->
    fail exn

(* +-----------------------------------------------------------------+
   | Types                                                           |
   +-----------------------------------------------------------------+ *)

type input
type output

type 'a mode = Input | Output

let input : input mode = Input
let output : output mode = Output

(* A channel state *)
type 'mode state =
  | Busy_primitive
      (* A primitive is running on the channel *)

  | Busy_atomic of 'mode channel
      (* An atomic operations is being performed on the channel. The
         argument is the temporary atomic wrapper. *)

  | Idle
      (* The channel is unused *)

  | Closed
      (* The channel has been closed *)

  | Invalid
      (* The channel is a temporary channel created for an atomic
         operation which has terminated. *)

(* A wrapper, which ensures that io operations are atomic: *)
and 'mode channel = {
  mutable state : 'mode state;

  channel : 'mode _channel;
  (* The real channel *)

  mutable queued : unit Lwt.u Lwt_sequence.t;
  (* Queued operations *)
}

and 'mode _channel = {
  mutable buffer : string;
  mutable length : int;

  mutable ptr : int;
  (* Current position *)

  mutable max : int;
  (* Position of the end of data int the buffer. It is equal to
     [length] for output channels. *)

  abort_waiter : int Lwt.t;
  (* Thread which is wakeup with an exception when the channel is
     closed. *)
  abort_wakener : int Lwt.u;

  mutable auto_flushing : bool;
  (* Wether the auto-flusher is currently running or not *)

  main : 'mode channel;
  (* The main wrapper *)

  close : unit Lwt.t;
  (* Close function *)

  mode : 'mode mode;
  (* The channel mode *)

  mutable offset : int64;
  (* Number of bytes really read/written *)

  typ : typ;
  (* Type of the channel. *)
}

and typ =
  | Type_normal of (string -> int -> int -> int Lwt.t) 
      (* The channel has been created with [make]. The first argument
         is the refill/flush function *)
  | Type_string
      (* The channel has been created with [of_string]. *)

type input_channel = input channel
type output_channel = output channel

type direct_access = {
  da_buffer : string;
  mutable da_ptr : int;
  mutable da_max : int;
  da_perform : unit -> int Lwt.t;
}

let mode wrapper = wrapper.channel.mode

(* +-----------------------------------------------------------------+
   | Creations, closing, locking, ...                                |
   +-----------------------------------------------------------------+ *)

module Outputs = Weak.Make(struct
                             type t = output_channel
                             let hash = Hashtbl.hash
                             let equal = ( == )
                           end)

(* Table of all opened output channels. On exit they are all
   flushed: *)
let outputs = Outputs.create 32

let position wrapper =
  let ch = wrapper.channel in
  match ch.mode with
    | Input ->
        Int64.sub ch.offset (Int64.of_int (ch.max - ch.ptr))
    | Output ->
        Int64.add ch.offset (Int64.of_int ch.ptr)

let name ch = match ch.mode with
  | Input -> "input"
  | Output -> "output"

let closed_channel ch = Channel_closed(name ch)
let invalid_channel ch = Failure(Printf.sprintf "temporary atomic %s channel no more valid" (name ch))

(* Flush/refill the buffer. No race condition could happen because
   this function is always called atomically: *)
let perform_io ch = match ch.main.state with
  | Busy_primitive | Busy_atomic _ -> begin
      match ch.typ with
        | Type_normal(perform_io) ->
            let ptr, len = match ch.mode with
              | Input ->
                  (* Size of data in the buffer *)
                  let size = ch.max - ch.ptr in
                  (* If there are still data in the buffer, keep them: *)
                  if size > 0 then String.unsafe_blit ch.buffer ch.ptr ch.buffer 0 size;
                  (* Update positions: *)
                  ch.ptr <- 0;
                  ch.max <- size;
                  (size, ch.length - size)
              | Output ->
                  (0, ch.ptr) in
            lwt n = pick [ch.abort_waiter; perform_io ch.buffer ptr len] in
            (* Never trust user functions... *)
            if n < 0 || n > len then
              fail (Failure (Printf.sprintf "Lwt_io: invalid result of the [%s] function(request=%d,result=%d)"
                               (match ch.mode with Input -> "read" | Output -> "write") len n))
            else begin
              (* Update the global offset: *)
              ch.offset <- Int64.add ch.offset (Int64.of_int n);
              (* Update buffer positions: *)
              begin match ch.mode with
                | Input ->
                    ch.max <- ch.max + n
                | Output ->
                    (* Shift remaining data: *)
                    let len = len - n in
                    String.unsafe_blit ch.buffer n ch.buffer 0 len;
                    ch.ptr <- len
              end;
              return n
            end

        | Type_string -> begin
            match ch.mode with
              | Input ->
                  return 0
              | Output ->
                  fail (Failure "cannot flush a channel created with Lwt_io.of_string")
          end
    end

  | Closed ->
      fail (closed_channel ch)

  | Invalid ->
      fail (invalid_channel ch)

  | Idle ->
      assert false

let refill = perform_io
let flush_partial = perform_io

let rec flush_total oc =
  if oc.ptr > 0 then
    lwt _ = flush_partial oc in
    flush_total oc
  else
    return ()

let safe_flush_total oc =
  try_lwt
    flush_total oc
  with
      _ -> return ()

let deepest_wrapper ch =
  let rec loop wrapper =
    match wrapper.state with
      | Busy_atomic wrapper ->
          loop wrapper
      | _ ->
          wrapper
  in
  loop ch.main

let auto_flush oc =
  lwt () = Lwt.pause () in
  let wrapper = deepest_wrapper oc in
  match wrapper.state with
    | Busy_primitive ->
        (* The channel is used, cancel auto flushing. It will be
           restarted when the channel returns to the [Idle] state: *)
        oc.auto_flushing <- false;
        return ()

    | Busy_atomic _ ->
        (* Cannot happen since we took the deepest wrapper: *)
        assert false

    | Idle ->
        oc.auto_flushing <- false;
        wrapper.state <- Busy_primitive;
        lwt () = safe_flush_total oc in
        if wrapper.state = Busy_primitive then
          wrapper.state <- Idle;
        if not (Lwt_sequence.is_empty wrapper.queued) then
          wakeup (Lwt_sequence.take_l wrapper.queued) ();
        return ()

    | Closed | Invalid ->
        return ()

(* A ``locked'' channel is a channel in the state [Busy_primitive] or
   [Busy_atomic] *)

let unlock wrapper = match wrapper.state with
  | Busy_primitive | Busy_atomic _ ->
      wrapper.state <- Idle;
      if not (Lwt_sequence.is_empty wrapper.queued) then
        wakeup (Lwt_sequence.take_l wrapper.queued) ();
      (* Launches the auto-flusher: *)
      let ch = wrapper.channel in
      if (* Launch the auto-flusher only if the channel is not busy: *)
        (wrapper.state = Idle &&
            (* Launch the auto-flusher only for output channel: *)
            ch.mode = Output &&
            (* Do not launch two auto-flusher: *)
            not ch.auto_flushing &&
            (* Do not launch the auto-flusher if operations are queued: *)
            Lwt_sequence.is_empty wrapper.queued) then begin
        ch.auto_flushing <- true;
        ignore (auto_flush ch)
      end

  | Closed | Invalid ->
      (* Do not change channel state if the channel has been closed *)
      if not (Lwt_sequence.is_empty wrapper.queued) then
        wakeup (Lwt_sequence.take_l wrapper.queued) ()

  | Idle ->
      (* We must never unlock an unlocked channel *)
      assert false

(* Wrap primitives into atomic io operations: *)
let primitive f wrapper = match wrapper.state with
  | Idle ->
      wrapper.state <- Busy_primitive;
      try_lwt
        f wrapper.channel
      finally
        unlock wrapper;
        return ()

  | Busy_primitive | Busy_atomic _ ->
      let (res, w) = task () in
      let node = Lwt_sequence.add_r w wrapper.queued in
      Lwt.on_cancel res (fun _ -> Lwt_sequence.remove node);
      lwt () = res in
      begin match wrapper.state with
        | Closed ->
            (* The channel has been closed while we were waiting *)
            unlock wrapper;
            fail (closed_channel wrapper.channel)

        | Idle ->
            wrapper.state <- Busy_primitive;
            try_lwt
              f wrapper.channel
            finally
              unlock wrapper;
              return ()

        | Invalid ->
            fail (invalid_channel wrapper.channel)

        | Busy_primitive | Busy_atomic _ ->
            assert false
      end

  | Closed ->
      fail (closed_channel wrapper.channel)

  | Invalid ->
      fail (invalid_channel wrapper.channel)

(* Wrap a sequence of io operations into an atomic operation: *)
let atomic f wrapper = match wrapper.state with
  | Idle ->
      let tmp_wrapper = { state = Idle;
                          channel = wrapper.channel;
                          queued = Lwt_sequence.create () } in
      wrapper.state <- Busy_atomic tmp_wrapper;
      try_lwt
        f tmp_wrapper
      finally
        (* The temporary wrapper is no more valid: *)
        tmp_wrapper.state <- Invalid;
        unlock wrapper;
        return ()

  | Busy_primitive | Busy_atomic _ ->
      let (res, w) = task () in
      let node = Lwt_sequence.add_r w wrapper.queued in
      Lwt.on_cancel res (fun _ -> Lwt_sequence.remove node);
      lwt () = res in
      begin match wrapper.state with
        | Closed ->
            (* The channel has been closed while we were waiting *)
            unlock wrapper;
            fail (closed_channel wrapper.channel)

        | Idle ->
            let tmp_wrapper = { state = Idle;
                                channel = wrapper.channel;
                                queued = Lwt_sequence.create () } in
            wrapper.state <- Busy_atomic tmp_wrapper;
            try_lwt
              f tmp_wrapper
            finally
              tmp_wrapper.state <- Invalid;
              unlock wrapper;
              return ()

        | Invalid ->
            fail (invalid_channel wrapper.channel)

        | Busy_primitive | Busy_atomic _ ->
            assert false
      end

  | Closed ->
      fail (closed_channel wrapper.channel)

  | Invalid ->
      fail (invalid_channel wrapper.channel)

let rec abort wrapper = match wrapper.state with
  | Busy_atomic tmp_wrapper ->
      (* Close the depest opened wrapper: *)
      abort tmp_wrapper
  | Closed ->
      (* Double close, just returns the same thing as before *)
      wrapper.channel.close
  | Invalid ->
      fail (invalid_channel wrapper.channel)
  | Idle | Busy_primitive ->
      wrapper.state <- Closed;
      (* Abort any current real reading/writing operation on the
         channel: *)
      wakeup_exn wrapper.channel.abort_wakener (closed_channel wrapper.channel);
      wrapper.channel.close

let close wrapper =
  let channel = wrapper.channel in
  if channel.main != wrapper then
    fail (Failure "Lwt_io.close: cannot close a channel obtained via Lwt_io.atomic")
  else
    match channel.mode with
      | Input ->
          (* Just close it now: *)
          abort wrapper
      | Output ->
          try_lwt
            (* Performs all pending actions, flush the buffer, then
               close it: *)
            primitive (fun channel -> safe_flush_total channel >> abort wrapper) wrapper
          with _ ->
            abort wrapper

(*
let () =
  (* Flush all opened ouput channels on exit: *)
  Lwt_main.at_exit
    (fun () ->
       let wrappers = Outputs.fold (fun x l -> x :: l) outputs [] in
       Lwt_list.iter_p
         (fun wrapper ->
            try_lwt
              primitive safe_flush_total wrapper
            with _ ->
              return ())
         wrappers)
*)

external unsafe_output : 'a channel -> output channel = "%identity"

let make ?buffer_size ?(close=return) ~mode perform_io =
  let buffer =
    String.create (match buffer_size with
                     | None ->
                         !default_buffer_size
                     | Some size ->
                         check_buffer_size "Lwt_io.make" size;
                         size)
  and abort_waiter, abort_wakener = Lwt.wait () in
  let rec ch = {
    buffer = buffer;
    length = String.length buffer;
    ptr = 0;
    max = (match mode with
             | Input -> 0
             | Output -> String.length buffer);
    close = close ();
    abort_waiter = abort_waiter;
    abort_wakener = abort_wakener;
    main = wrapper;
    auto_flushing = false;
    mode = mode;
    offset = 0L;
    typ = Type_normal perform_io;
  } and wrapper = {
    state = Idle;
    channel = ch;
    queued = Lwt_sequence.create ();
  } in
  if mode = Output then Outputs.add outputs (unsafe_output wrapper);
  wrapper

let of_string ~mode str =
  let length = String.length str in
  let abort_waiter, abort_wakener = Lwt.wait () in
  let rec ch = {
    buffer = str;
    length = length;
    ptr = 0;
    max = length;
    close = return ();
    abort_waiter = abort_waiter;
    abort_wakener = abort_wakener;
    main = wrapper;
    (* Auto flush is set to [true] to prevent writing functions from
       trying to launch the auto-fllushed. *)
    auto_flushing = true;
    mode = mode;
    offset = 0L;
    typ = Type_string;
  } and wrapper = {
    state = Idle;
    channel = ch;
    queued = Lwt_sequence.create ();
  } in
  wrapper

let of_fd ?buffer_size ?close ~mode fd =
  let perform_io = match mode with
    | Input -> Channel.read fd
    | Output -> Channel.write fd
  in
  make
    ?buffer_size
    ~close:(match close with
              | Some f -> f
              | None -> (fun () -> close_fd fd))
    ~mode perform_io

let buffered ch =
  match ch.channel.mode with
    | Input -> ch.channel.max - ch.channel.ptr
    | Output -> ch.channel.ptr

let buffer_size ch = ch.channel.length

let resize_buffer wrapper len =
  if len < min_buffer_size then invalid_arg "Lwt_io.resize_buffer";
  match wrapper.channel.typ with
    | Type_string ->
        fail (Failure "Lwt_io.resize_buffer: cannot resize the buffer of a channel created with Lwt_io.of_string")
    | Type_normal _ ->
        primitive begin fun ch ->
          match ch.mode with
            | Input ->
                let unread_count = ch.max - ch.ptr in
                (* Fail if we want to decrease the buffer size and there is
                   too much unread data in the buffer: *)
                if len < unread_count then
                  fail (Failure "Lwt_io.resize_buffer: cannot decrease buffer size")
                else begin
                  let buffer = String.create len in
                  String.unsafe_blit ch.buffer ch.ptr buffer 0 unread_count;
                  ch.buffer <- buffer;
                  ch.length <- len;
                  ch.ptr <- 0;
                  ch.max <- unread_count;
                  return ()
                end
            | Output ->
                (* If we decrease the buffer size, flush the buffer until
                   the number of buffered bytes fits into the new buffer: *)
                let rec loop () =
                  if ch.ptr > len then
                    lwt _ = flush_partial ch in
                    loop ()
                  else
                    return ()
                in
                lwt () = loop () in
                let buffer = String.create len in
                String.unsafe_blit ch.buffer 0 buffer 0 ch.ptr;
                ch.buffer <- buffer;
                ch.length <- len;
                ch.max <- len;
                return ()
        end wrapper

(* +-----------------------------------------------------------------+
   | Byte-order                                                      |
   +-----------------------------------------------------------------+ *)

module ByteOrder =
struct
  module type S = sig
    val pos16_0 : int
    val pos16_1 : int
    val pos32_0 : int
    val pos32_1 : int
    val pos32_2 : int
    val pos32_3 : int
    val pos64_0 : int
    val pos64_1 : int
    val pos64_2 : int
    val pos64_3 : int
    val pos64_4 : int
    val pos64_5 : int
    val pos64_6 : int
    val pos64_7 : int
  end

  module LE =
  struct
    let pos16_0 = 0
    let pos16_1 = 1
    let pos32_0 = 0
    let pos32_1 = 1
    let pos32_2 = 2
    let pos32_3 = 3
    let pos64_0 = 0
    let pos64_1 = 1
    let pos64_2 = 2
    let pos64_3 = 3
    let pos64_4 = 4
    let pos64_5 = 5
    let pos64_6 = 6
    let pos64_7 = 7
  end

  module BE =
  struct
    let pos16_0 = 1
    let pos16_1 = 0
    let pos32_0 = 3
    let pos32_1 = 2
    let pos32_2 = 1
    let pos32_3 = 0
    let pos64_0 = 7
    let pos64_1 = 6
    let pos64_2 = 5
    let pos64_3 = 4
    let pos64_4 = 3
    let pos64_5 = 2
    let pos64_6 = 1
    let pos64_7 = 0
  end
end

module Primitives =
struct

  (* This module contains all primitives operations. The operates
     without protection regarding locking, they are wrapped after into
     safe operations. *)

  (* +---------------------------------------------------------------+
     | Reading                                                       |
     +---------------------------------------------------------------+ *)

  let rec read_char ic =
    let ptr = ic.ptr in
    if ptr = ic.max then
      refill ic >>= function
        | 0 -> fail End_of_file
        | _ -> read_char ic
    else begin
      ic.ptr <- ptr + 1;
      return (String.unsafe_get ic.buffer ptr)
    end

  let read_char_opt ic =
    try_lwt
      read_char ic >|= fun ch -> Some ch
    with End_of_file ->
      return None

  let read_line ic =
    let buf = Buffer.create 128 in
    let rec loop cr_read =
      try_bind (fun _ -> read_char ic)
        (function
           | '\n' ->
               return(Buffer.contents buf)
           | '\r' ->
               if cr_read then Buffer.add_char buf '\r';
               loop true
           | ch ->
               if cr_read then Buffer.add_char buf '\r';
               Buffer.add_char buf ch;
               loop false)
        (function
           | End_of_file ->
               if cr_read then Buffer.add_char buf '\r';
               return(Buffer.contents buf)
           | exn ->
               fail exn)
    in
    read_char ic >>= function
      | '\r' -> loop true
      | '\n' -> return ""
      | ch -> Buffer.add_char buf ch; loop false

  let read_line_opt ic =
    try_lwt
      read_line ic >|= fun ch -> Some ch
    with End_of_file ->
      return None

  let unsafe_read_into ic str ofs len =
    let avail = ic.max - ic.ptr in
    if avail > 0 then begin
      let len = min len avail in
      String.unsafe_blit ic.buffer ic.ptr str ofs len;
      ic.ptr <- ic.ptr + len;
      return len
    end else begin
      refill ic >>= fun n ->
        let len = min len n in
        String.unsafe_blit ic.buffer 0 str ofs len;
        ic.ptr <- len;
        ic.max <- n;
        return len
    end

  let read_into ic str ofs len =
    if ofs < 0 || len < 0 || ofs + len > String.length str then
      fail (Invalid_argument (Printf.sprintf
                                "Lwt_io.read_into(ofs=%d,len=%d,str_len=%d)"
                                ofs len (String.length str)))
    else begin
      if len = 0 then
        return 0
      else
        unsafe_read_into ic str ofs len
    end

  let rec unsafe_read_into_exactly ic str ofs len =
    unsafe_read_into ic str ofs len >>= function
      | 0 ->
          fail End_of_file
      | n ->
          let len = len - n in
          if len = 0 then
            return ()
          else
            unsafe_read_into_exactly ic str (ofs + n) len

  let read_into_exactly ic str ofs len =
    if ofs < 0 || len < 0 || ofs + len > String.length str then
      fail (Invalid_argument (Printf.sprintf
                                "Lwt_io.read_into_exactly(ofs=%d,len=%d,str_len=%d)"
                                ofs len (String.length str)))
    else begin
      if len = 0 then
        return ()
      else
        unsafe_read_into_exactly ic str ofs len
    end

  let rec read_all ic buf =
    Buffer.add_substring buf ic.buffer ic.ptr (ic.max - ic.ptr);
    ic.ptr <- ic.max;
    refill ic >>= function
      | 0 ->
          return (Buffer.contents buf)
      | n ->
          read_all ic buf

  let read count ic =
    match count with
      | None ->
          read_all ic (Buffer.create 512)
      | Some len ->
          let str = String.create len in
          lwt real_len = unsafe_read_into ic str 0 len in
          if real_len < len then
            return (String.sub str 0 real_len)
          else
            return str

  let read_value ic =
    let header = String.create 20 in
    lwt () = unsafe_read_into_exactly ic header 0 20 in
    let bsize = Marshal.data_size header 0 in
    let buffer = String.create (20 + bsize) in
    String.unsafe_blit header 0 buffer 0 20 ;
    lwt () = unsafe_read_into_exactly ic buffer 20 bsize in
    return (Marshal.from_string buffer 0)

  (* +---------------------------------------------------------------+
     | Writing                                                       |
     +---------------------------------------------------------------+ *)

  let flush = flush_total

  let rec write_char oc ch =
    let ptr = oc.ptr in
    if ptr < oc.length then begin
      oc.ptr <- ptr + 1;
      String.unsafe_set oc.buffer ptr ch;
      return ()
    end else
      lwt _ = flush_partial oc in
      write_char oc ch

  let rec unsafe_write_from oc str ofs len =
    let avail = oc.length - oc.ptr in
    if avail >= len then begin
      String.unsafe_blit str ofs oc.buffer oc.ptr len;
      oc.ptr <- oc.ptr + len;
      return 0
    end else begin
      String.unsafe_blit str ofs oc.buffer oc.ptr avail;
      oc.ptr <- oc.length;
      lwt _ = flush_partial oc in
      let len = len - avail in
      if oc.ptr = 0 then begin
        if len = 0 then
          return 0
        else
          (* Everything has been written, try to write more: *)
          unsafe_write_from oc str (ofs + avail) len
      end else
        (* Not everything has been written, just what is
           remaining: *)
        return len
    end

  let write_from oc str ofs len =
    if ofs < 0 || len < 0 || ofs + len > String.length str then
      fail (Invalid_argument (Printf.sprintf
                                "Lwt_io.write_from(ofs=%d,len=%d,str_len=%d)"
                                ofs len (String.length str)))
    else begin
      if len = 0 then
        return 0
      else
        unsafe_write_from oc str ofs len >>= fun remaining -> return (len - remaining)
    end

  let rec unsafe_write_from_exactly oc str ofs len =
    unsafe_write_from oc str ofs len >>= function
      | 0 ->
          return ()
      | n ->
          unsafe_write_from_exactly oc str (ofs + len - n) n

  let write_from_exactly oc str ofs len =
    if ofs < 0 || len < 0 || ofs + len > String.length str then
      fail (Invalid_argument (Printf.sprintf
                                "Lwt_io.write_from_exactly(ofs=%d,len=%d,str_len=%d)"
                                ofs len (String.length str)))
    else begin
      if len = 0 then
        return ()
      else
        unsafe_write_from_exactly oc str ofs len
    end

  let write oc str =
    unsafe_write_from_exactly oc str 0 (String.length str)

  let write_line oc str =
    lwt () = unsafe_write_from_exactly oc str 0 (String.length str) in
    write_char oc '\n'

  let write_value oc ?(flags=[]) x =
    write oc (Marshal.to_string x flags)

  (* +---------------------------------------------------------------+
     | Low-level access                                              |
     +---------------------------------------------------------------+ *)

  let rec read_block_unsafe ic size f =
    if ic.max - ic.ptr < size then
      refill ic >>= function
        | 0 ->
            fail End_of_file
        | _ ->
            read_block_unsafe ic size f
    else begin
      let ptr = ic.ptr in
      ic.ptr <- ptr + size;
      f ic.buffer ptr
    end

  let rec write_block_unsafe oc size f =
    if oc.max - oc.ptr < size then
      lwt _ = flush_partial oc in
      write_block_unsafe oc size f
    else begin
      let ptr = oc.ptr in
      oc.ptr <- ptr + size;
      f oc.buffer ptr
    end

  let block ch size f =
    if size < 0 || size > min_buffer_size then
      fail (Invalid_argument(Printf.sprintf "Lwt_io.block(size=%d)" size))
    else
      if ch.max - ch.ptr >= size then begin
        let ptr = ch.ptr in
        ch.ptr <- ptr + size;
        f ch.buffer ptr
      end else
        match ch.mode with
          | Input ->
              read_block_unsafe ch size f
          | Output ->
              write_block_unsafe ch size f

  let perform token da ch =
    if !token then begin
      if da.da_max <> ch.max || da.da_ptr < ch.ptr || da.da_ptr > ch.max then
        fail (Invalid_argument "Lwt_io.direct_access.perform")
      else begin
        ch.ptr <- da.da_ptr;
        lwt count = perform_io ch in
        da.da_ptr <- ch.ptr;
        da.da_max <- ch.max;
        return count
      end
    end else
      fail (Failure "Lwt_io.direct_access.perform: this function can not be called outside Lwt_io.direct_access")

  let direct_access ch f =
    let token = ref true in
    let rec da = {
      da_ptr = ch.ptr;
      da_max = ch.max;
      da_buffer = ch.buffer;
      da_perform = (fun _ -> perform token da ch);
    } in
    lwt x = f da in
    token := false;
    if da.da_max <> ch.max || da.da_ptr < ch.ptr || da.da_ptr > ch.max then
      fail (Failure "Lwt_io.direct_access: invalid result of [f]")
    else begin
      ch.ptr <- da.da_ptr;
      return x
    end

  module MakeNumberIO(ByteOrder : ByteOrder.S) =
  struct
    open ByteOrder

    (* +-------------------------------------------------------------+
       | Reading numbers                                             |
       +-------------------------------------------------------------+ *)

    let get buffer ptr = Char.code (String.unsafe_get buffer ptr)

    let read_int ic =
      read_block_unsafe ic 4
        (fun buffer ptr ->
           let v0 = get buffer (ptr + pos32_0)
           and v1 = get buffer (ptr + pos32_1)
           and v2 = get buffer (ptr + pos32_2)
           and v3 = get buffer (ptr + pos32_3) in
           let v = v0 lor (v1 lsl 8) lor (v2 lsl 16) lor (v3 lsl 24) in
           if v3 land 0x80 = 0 then
             return v
           else
             return (v - (1 lsl 32)))

    let read_int16 ic =
      read_block_unsafe ic 2
        (fun buffer ptr ->
           let v0 = get buffer (ptr + pos16_0)
           and v1 = get buffer (ptr + pos16_1) in
           let v = v0 lor (v1 lsl 8) in
           if v1 land 0x80 = 0 then
             return v
           else
             return (v - (1 lsl 16)))

    let read_int32 ic =
      read_block_unsafe ic 4
        (fun buffer ptr ->
           let v0 = get buffer (ptr + pos32_0)
           and v1 = get buffer (ptr + pos32_1)
           and v2 = get buffer (ptr + pos32_2)
           and v3 = get buffer (ptr + pos32_3) in
           return (Int32.logor
                     (Int32.logor
                        (Int32.of_int v0)
                        (Int32.shift_left (Int32.of_int v1) 8))
                     (Int32.logor
                        (Int32.shift_left (Int32.of_int v2) 16)
                        (Int32.shift_left (Int32.of_int v3) 24))))

    let read_int64 ic =
      read_block_unsafe ic 8
        (fun buffer ptr ->
           let v0 = get buffer (ptr + pos64_0)
           and v1 = get buffer (ptr + pos64_1)
           and v2 = get buffer (ptr + pos64_2)
           and v3 = get buffer (ptr + pos64_3)
           and v4 = get buffer (ptr + pos64_4)
           and v5 = get buffer (ptr + pos64_5)
           and v6 = get buffer (ptr + pos64_6)
           and v7 = get buffer (ptr + pos64_7) in
           return (Int64.logor
                     (Int64.logor
                        (Int64.logor
                           (Int64.of_int v0)
                           (Int64.shift_left (Int64.of_int v1) 8))
                        (Int64.logor
                           (Int64.shift_left (Int64.of_int v2) 16)
                           (Int64.shift_left (Int64.of_int v3) 24)))
                     (Int64.logor
                        (Int64.logor
                           (Int64.shift_left (Int64.of_int v4) 32)
                           (Int64.shift_left (Int64.of_int v5) 40))
                        (Int64.logor
                           (Int64.shift_left (Int64.of_int v6) 48)
                           (Int64.shift_left (Int64.of_int v7) 56)))))

    let read_float32 ic = read_int32 ic >>= fun x -> return (Int32.float_of_bits x)
    let read_float64 ic = read_int64 ic >>= fun x -> return (Int64.float_of_bits x)

    (* +-------------------------------------------------------------+
       | Writing numbers                                             |
       +-------------------------------------------------------------+ *)

    let set buffer ptr x = String.unsafe_set buffer ptr (Char.unsafe_chr x)

    let write_int oc v =
      write_block_unsafe oc 4
        (fun buffer ptr ->
           set buffer (ptr + pos32_0) v;
           set buffer (ptr + pos32_1) (v lsr 8);
           set buffer (ptr + pos32_2) (v lsr 16);
           set buffer (ptr + pos32_3) (v asr 24);
           return ())

    let write_int16 oc v =
      write_block_unsafe oc 2
        (fun buffer ptr ->
           set buffer (ptr + pos16_0) v;
           set buffer (ptr + pos16_1) (v lsr 8);
           return ())

    let write_int32 oc v =
      write_block_unsafe oc 4
        (fun buffer ptr ->
           set buffer (ptr + pos32_0) (Int32.to_int v);
           set buffer (ptr + pos32_1) (Int32.to_int (Int32.shift_right v 8));
           set buffer (ptr + pos32_2) (Int32.to_int (Int32.shift_right v 16));
           set buffer (ptr + pos32_3) (Int32.to_int (Int32.shift_right v 24));
           return ())

    let write_int64 oc v =
      write_block_unsafe oc 8
        (fun buffer ptr ->
           set buffer (ptr + pos64_0) (Int64.to_int v);
           set buffer (ptr + pos64_1) (Int64.to_int (Int64.shift_right v 8));
           set buffer (ptr + pos64_2) (Int64.to_int (Int64.shift_right v 16));
           set buffer (ptr + pos64_3) (Int64.to_int (Int64.shift_right v 24));
           set buffer (ptr + pos64_4) (Int64.to_int (Int64.shift_right v 32));
           set buffer (ptr + pos64_5) (Int64.to_int (Int64.shift_right v 40));
           set buffer (ptr + pos64_6) (Int64.to_int (Int64.shift_right v 48));
           set buffer (ptr + pos64_7) (Int64.to_int (Int64.shift_right v 56));
           return ())

    let write_float32 oc v = write_int32 oc (Int32.bits_of_float v)
    let write_float64 oc v = write_int64 oc (Int64.bits_of_float v)
  end

end

(* +-----------------------------------------------------------------+
   | Primitive operations                                            |
   +-----------------------------------------------------------------+ *)

let read_char wrapper =
  let channel = wrapper.channel in
  let ptr = channel.ptr in
  (* Speed-up in case a character is available in the buffer. It
     increases performances by 10x. *)
  if wrapper.state = Idle && ptr < channel.max then begin
    channel.ptr <- ptr + 1;
    return (String.unsafe_get channel.buffer ptr)
  end else
    primitive Primitives.read_char wrapper

let read_char_opt wrapper =
  let channel = wrapper.channel in
  let ptr = channel.ptr in
  if wrapper.state = Idle && ptr < channel.max then begin
    channel.ptr <- ptr + 1;
    return (Some(String.unsafe_get channel.buffer ptr))
  end else
    primitive Primitives.read_char_opt wrapper

let read_line ic = primitive Primitives.read_line ic
let read_line_opt ic = primitive Primitives.read_line_opt ic
let read ?count ic = primitive (fun ic -> Primitives.read count ic) ic
let read_into ic str ofs len = primitive (fun ic -> Primitives.read_into ic str ofs len) ic
let read_into_exactly ic str ofs len = primitive (fun ic -> Primitives.read_into_exactly ic str ofs len) ic
let read_value ic = primitive Primitives.read_value ic

let flush oc = primitive Primitives.flush oc

let write_char wrapper x =
  let channel = wrapper.channel in
  let ptr = channel.ptr in
  if wrapper.state = Idle && ptr < channel.max then begin
    channel.ptr <- ptr + 1;
    String.unsafe_set channel.buffer ptr x;
    (* Fast launching of the auto flusher: *)
    if not channel.auto_flushing then begin
      channel.auto_flushing <- true;
      ignore (auto_flush channel);
      return ()
    end else
      return ()
  end else
    primitive (fun oc -> Primitives.write_char oc x) wrapper

let write oc str = primitive (fun oc -> Primitives.write oc str) oc
let write_line oc x = primitive (fun oc -> Primitives.write_line oc x) oc
let write_from oc str ofs len = primitive (fun oc -> Primitives.write_from oc str ofs len) oc
let write_from_exactly oc str ofs len = primitive (fun oc -> Primitives.write_from_exactly oc str ofs len) oc
let write_value oc ?flags x = primitive (fun oc -> Primitives.write_value oc ?flags x) oc

let block ch size f = primitive (fun ch -> Primitives.block ch size f) ch
let direct_access ch f = primitive (fun ch -> Primitives.direct_access ch f) ch

module type NumberIO = sig
  val read_int : input_channel -> int Lwt.t
  val read_int16 : input_channel -> int Lwt.t
  val read_int32 : input_channel -> int32 Lwt.t
  val read_int64 : input_channel -> int64 Lwt.t
  val read_float32 : input_channel -> float Lwt.t
  val read_float64 : input_channel -> float Lwt.t
  val write_int : output_channel -> int -> unit Lwt.t
  val write_int16 : output_channel -> int -> unit Lwt.t
  val write_int32 : output_channel -> int32 -> unit Lwt.t
  val write_int64 : output_channel -> int64 -> unit Lwt.t
  val write_float32 : output_channel -> float -> unit Lwt.t
  val write_float64 : output_channel -> float -> unit Lwt.t
end

module MakeNumberIO(ByteOrder : ByteOrder.S) =
struct
  module Primitives = Primitives.MakeNumberIO(ByteOrder)

  let read_int ic = primitive Primitives.read_int ic
  let read_int16 ic = primitive Primitives.read_int16 ic
  let read_int32 ic = primitive Primitives.read_int32 ic
  let read_int64 ic = primitive Primitives.read_int64 ic
  let read_float32 ic = primitive Primitives.read_float32 ic
  let read_float64 ic = primitive Primitives.read_float64 ic

  let write_int oc x = primitive (fun oc -> Primitives.write_int oc x) oc
  let write_int16 oc x = primitive (fun oc -> Primitives.write_int16 oc x) oc
  let write_int32 oc x = primitive (fun oc -> Primitives.write_int32 oc x) oc
  let write_int64 oc x = primitive (fun oc -> Primitives.write_int64 oc x) oc
  let write_float32 oc x = primitive (fun oc -> Primitives.write_float32 oc x) oc
  let write_float64 oc x = primitive (fun oc -> Primitives.write_float64 oc x) oc
end

module LE = MakeNumberIO(ByteOrder.LE)
module BE = MakeNumberIO(ByteOrder.BE)

type byte_order = Little_endian | Big_endian

external get_system_byte_order : unit -> byte_order = "lwt_unix_system_byte_order"

let system_byte_order = get_system_byte_order ()

(* +-----------------------------------------------------------------+
   | Other                                                           |
   +-----------------------------------------------------------------+ *)

let read_chars ic = Lwt_stream.from (fun _ -> read_char_opt ic)
let write_chars oc chars = Lwt_stream.iter_s (fun char -> write_char oc char) chars
let read_lines ic = Lwt_stream.from (fun _ -> read_line_opt ic)
let write_lines oc lines = Lwt_stream.iter_s (fun line -> write_line oc line) lines

let zero =
  make
    ~mode:input
    ~buffer_size:min_buffer_size
    (fun str ofs len -> String.fill str ofs len '\x00'; return len)

let null =
  make
    ~mode:output
    ~buffer_size:min_buffer_size
    (fun str ofs len -> return len)

let open_connection ?buffer_size sockaddr =
  lwt fd = Channel.connect sockaddr in
  try_lwt
    return (make ?buffer_size
              ~close:(fun _ -> close_fd fd)
              ~mode:input (Channel.read fd),
            make ?buffer_size
              ~close:(fun _ -> close_fd fd)
              ~mode:output (Channel.write fd))
  with exn ->
    lwt () = close_fd fd in
    fail exn

let with_connection ?buffer_size sockaddr f =
  lwt ic, oc = open_connection sockaddr in
  try_lwt
    f (ic, oc)
  finally
    close ic <&> close oc

let make_stream f ic =
  (* Gc.finalise Channel.close ic; XXX TODO *)
  Lwt_stream.from (fun _ ->
                     lwt x = f ic in
                     if x = None then
                       lwt () = close ic in
                       return x
                     else
                       return x)

let hexdump_stream oc stream = write_lines oc (Lwt_stream.hexdump stream)
let hexdump oc buf = hexdump_stream oc (Lwt_stream.of_string buf)

let set_default_buffer_size size =
  check_buffer_size "set_default_buffer_size" size;
  default_buffer_size := size
let default_buffer_size _ = !default_buffer_size

end
