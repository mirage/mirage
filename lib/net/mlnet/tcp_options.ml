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

(* TCP options parsing *)

module I = OS.Istring.View

type t =
  |MSS of int                      (* RFC793 *)
  |Window_size_shift of int        (* RFC1323 2.2 *)
  |SACK_ok                         (* RFC2018 *)
  |SACK of (int32 * int32) array   (* RFC2018 *)
  |Timestamp of (int32 * int32)    (* RFC1323 3.2 *)
  |Unknown of (int * string)       (* RFC793 *)

type ts = t list

let rec parse v off acc =
  match I.to_byte v off with
  |0 -> acc             (* End of options *)
  |1 -> parse v (off+1) acc  (* NOOP *)
  |2 -> parse v (off+4) (MSS (I.to_uint16_be v (off+2)) :: acc)
  |3 -> parse v (off+3) (Window_size_shift (I.to_byte v (off+2)) :: acc)
  |4 -> parse v (off+2) (SACK_ok :: acc)
  |5 ->
    let len = I.to_byte v (off+1) in
    let num = (len - 2) / 8 in
    let blocks = Array.init num (fun i ->
      (I.to_uint32_be v (off+2+(i*4))), (I.to_uint32_be v (off+4+(i*4)))) in
    parse v (off+2+len) (SACK blocks :: acc)
  |8 ->
    let r = (I.to_uint32_be v (off+2)), (I.to_uint32_be v (off+6)) in
    parse v (off+10) (Timestamp r :: acc) 
  |x ->
    let len = I.to_byte v (off+1) in
    let r = Unknown (x,(I.to_string v (off+2) len)) in
    parse v (off+2+len) (r::acc)

let marshal ts = 
  let open OS.Istring.View in
  (fun env ->
    (* Write type, length, apply function, return total length *)
    let set_tl off t l fn =
      set_byte env off t;
      set_byte env (off+1) l;
      fn (off+2);
      l in
    (* Walk through the options and write them to the view *)
    let rec write off = function
    |hd :: tl -> begin
      match hd with
      |MSS sz ->
         set_tl off 2 4 (fun off ->
           set_uint16_be env off sz;
         )
      |Window_size_shift shift ->
         set_tl off 3 3 (fun off ->
           set_byte env off shift;
         );
      |SACK_ok ->
         set_tl off 4 2 (fun off -> ())
      |SACK acks ->
         let len = Array.length acks * 8 + 2 in
         set_tl off 5 len (fun off ->
           Array.iteri (fun i (l,r) -> 
             set_uint32_be env (i*8+off) l;
             set_uint32_be env (i*8+off+4) r;
           ) acks
         )
      |Timestamp (a,b) ->
         set_tl off 8 10 (fun off ->
           set_uint32_be env off a;
           set_uint32_be env (off+4) b
         )
      |Unknown (t,v) ->
         set_tl off t (String.length v + 2) (fun off ->
           set_string env off v
         )
    end
    |[] ->
      (* Write end of options field *)
      set_byte env off 0;
      0
    in
    ignore(write 0 ts)
  )

let of_packet (tcp:Mpl.Tcp.o) =
  if tcp#options_length = 0 then []
  else parse tcp#options_sub_view 0 []

let to_string = function
  |MSS m -> Printf.sprintf "MSS=%d" m
  |Window_size_shift b -> Printf.sprintf "Window>>%d" b
  |SACK_ok -> "SACK_ok"
  |SACK x -> Printf.(sprintf "SACK=(%s)" (String.concat ","
    (List.map (fun (l,r) -> sprintf "%lu,%lu" l r) (Array.to_list x))))
  |Timestamp (a,b) -> Printf.sprintf "Timestamp(%lu,%lu)" a b
  |Unknown (t,_) -> Printf.sprintf "%d?" t

let prettyprint s =
  Printf.sprintf "[ %s ]" (String.concat "; " (List.map to_string s))
