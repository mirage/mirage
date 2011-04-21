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

module Prettyprint = struct

  open Printf

  (* A rough-n-ready hexdump from a string *)
  let hexdump s = 
    let open Buffer in
    let buf1 = create 64 in
    let buf2 = create 64 in
    let lines1 = ref [] in
    let lines2 = ref [] in
    for i = 0 to String.length s - 1 do
      if i <> 0 && (i mod 8) = 0 then begin
        lines1 := contents buf1 :: !lines1;
        lines2 := contents buf2 :: !lines2;
        reset buf1;
        reset buf2;
      end;
    let pchar c =
      let s = String.make 1 c in if Char.escaped c = s then s else "." in
      add_string buf1 (sprintf " %02X" (int_of_char (String.get s i)));
      add_string buf2 (sprintf " %s" (pchar (String.get s i)));
    done;
    if length buf1 > 0 then lines1 := contents buf1 :: !lines1;
    if length buf2 > 0 then lines2 := contents buf2 :: !lines2;
    reset buf1;
    add_char buf1 '\n';
    List.iter2 (fun l1 l2 ->
      add_string buf1 (sprintf "   %-24s   |   %-16s   \n" l1 l2);
    ) (List.rev !lines1) (List.rev !lines2);
    contents buf1

  let byte = sprintf "%u"
  let uint16 = sprintf "%u"
  let uint32 = sprintf "%lu"
  let uint64 = sprintf "%Lu"

end
module Raw = struct
  type t

  (* Allocate an istring 4k page *)
  external alloc: unit -> t = "caml_istring_alloc_page"

  (* Get total size of an istring buffer.  *)
  external size: t -> int = "caml_istring_size" "noalloc"

  (* Increment and decrement reference count *)
  external incr: t -> unit = "caml_istring_ref_incr" "noalloc"
  external decr: t -> unit = "caml_istring_ref_decr" "noalloc"

  (* Set character. 
     Cannot be noalloc as it can raise an exception.
  *)
  external set_byte: t -> int -> int -> unit = "caml_istring_safe_set_byte"

  (* Set uint16 big endian. *)
  external set_uint16_be: t -> int -> int -> unit = "caml_istring_set_uint16_be"

  (* Set uint32 big endian. *)
  external set_uint32_be: t -> int -> int32 -> unit = "caml_istring_set_uint32_be"

  (* Set uint64 big endian. *)
  external set_uint64_be: t -> int -> int64 -> unit = "caml_istring_set_uint64_be"

  (* Blit OCaml string to istring.
     Cannot be noalloc as it can raise an exception *)
  external blit: t -> int -> string -> unit = "caml_istring_safe_blit"

  (* Blit istring to istring.
     Cannot be noalloc as it can raise an exception *)
  external blit_to_istring: t -> int -> t -> int -> int -> unit = "caml_istring_safe_blit_view"

  (* Blit istring to string.
     Cannot be noalloc as it can raise an exception *)
  external blit_to_string: string -> int -> t -> int -> int -> unit = "caml_istring_safe_blit_to_string"

  (* Get character.
     Cannot be noalloc as it can raise an exception
   *)
  external to_char: t -> int -> char = "caml_istring_safe_get_char"

  external unsafe_to_char: t -> int -> char = "caml_istring_unsafe_get_char"

  external unsafe_set_char: t -> int -> char -> unit = "caml_istring_unsafe_set_char"

  (* Get an OCaml string slice. *)
  external to_string: t -> int -> int -> string = "caml_istring_safe_get_string"

  (* Get a big-endian uint16 out of the view *)
  external to_uint16_be: t -> int -> int = "caml_istring_get_uint16_be"

  (* Get a big-endian uint32 out of the view *)
  external to_uint32_be: t -> int -> int32 = "caml_istring_get_uint32_be"

  (* Get a big-endian uint64 out of the view *)
  external to_uint64_be: t -> int -> int64 = "caml_istring_get_uint64_be"

  (* One's complement checksum, RFC1071 *)
  external ones_complement_checksum: t -> int -> int -> int32 -> int = "caml_istring_ones_complement_checksum"

  (* Scan for a character from a specified offset.
     Return (-1) if not found, or else the index within the raw buffer *)
  external scan_char: t -> int -> char -> int = "caml_istring_scan_char"
end

open Printf

(* A view into a portion of an istring *)
type t = { 
  i: Raw.t;          (* Reference to immutable string *)
  off: int;          (* Start offset within the istring *)
  mutable len: int;  (* Valid size of istring relative to offset *)
}
and 'a data =
[
  | `Sub of (t -> 'a)
  | `Str of string
  | `Frag of t
  | `None
]

type byte = int
type uint16 = int

(* Finaliser function for a view that decrements the ref count *)
let final t = 
  Raw.decr t.i

(* Generate a new view onto a raw istring *)
let t ?(off=0) i len = 
  let v = { i; off; len } in
  Raw.incr i;
  Gc.finalise final v;
  v

(* Get length of the view *)
let length t = t.len

(* Generate a sub-view *)
let sub t off len =
  let off = t.off+off in
  if off >= Raw.size t.i then
    raise (Invalid_argument "Istring.sub out of bounds");
  let v = { t with off; len } in
  Raw.incr t.i;
  Gc.finalise final v;
  v

(* Copy a view. *)
let copy t = 
  let v = { i=t.i; off=t.off; len=t.len } in
  Raw.incr t.i;
  Gc.finalise final v;
  v

let off t = t.off
let raw t = t.i

(** Marshal functions *)

let set_string t off src =
  Raw.blit t.i (t.off+off) src

let set_byte t off (v:byte) =
  Raw.set_byte t.i (t.off+off) v

let set_char t off (v:char) =
  Raw.set_byte t.i (t.off+off) (Char.code v)

let set_uint16_be t off (v:uint16) =
  Raw.set_uint16_be t.i (t.off+off) v
    
let set_uint32_be t off v =
  Raw.set_uint32_be t.i (t.off+off) v

let set_uint64_be t off v =
  Raw.set_uint64_be t.i (t.off+off) v

let set_view dst off src =
  Raw.blit_to_istring dst.i (dst.off+off) src.i src.off src.len

(** Type cast functions *)

(* Get a single character from the view *)
let to_char t off =
  Raw.to_char t.i (t.off+off)

(* Copy out an OCaml string from the view *)
let to_string t off len =
  Raw.to_string t.i (t.off+off) len

(* Blit to an OCaml string from the view *)
let blit_to_string dst off t off len =
  Raw.blit_to_string dst off t.i (t.off+off) len

(* Get a single byte from the view, as an OCaml int *)
let to_byte t off : byte =
  int_of_char (to_char t off)

(* Get a uint16 out of the view. *)
let to_uint16_be t off : uint16 =
  Raw.to_uint16_be t.i (t.off+off)

(* Get a uint32 out of the view. *)
let to_uint32_be t off =
  Raw.to_uint32_be t.i (t.off+off)

(* Get a uint64 out of the view. *)
let to_uint64_be t off =
  Raw.to_uint64_be t.i (t.off+off)

(* Skip forward a number of bytes, extending length if needed *)
let seek t pos =
  if pos > t.len then
    t.len <- pos

let ones_complement_checksum t len initial =
  Raw.ones_complement_checksum t.i t.off len initial

(* Scan for a character from an offset.
   Return (-1) if not found, or index within view if it is found *)
let scan_char t off c =
  match Raw.scan_char t.i (t.off+off) c with
    | (-1) -> (-1)
    | r -> r - t.off

(* Sequences of istrings are held as a sequence internally *)
type ts = t Lwt_sequence.t

(* Copy a set of views into an OCaml string.
   TODO: this should be hidden behind a String-like module
   that hides the grungy copying.
*)
let ts_to_string ts =
  let len = Lwt_sequence.fold_l (fun view acc -> length view + acc) ts 0 in
  let buf = String.create len in
  let _ = Lwt_sequence.fold_l (fun view off ->
    let viewlen = length view in
    blit_to_string buf off view 0 viewlen;
    off + viewlen
  ) ts 0 in
  buf

open Lwt

(* Converts a Lwt_stream of views into a view sequence *) 
let ts_of_stream s =
  let ts = Lwt_sequence.create () in
  Lwt_stream.iter (fun v -> ignore(Lwt_sequence.add_r v ts)) s >>
  return ts

(* Converts an Lwt_stream into an OCaml string *)
let string_of_stream s =
  ts_of_stream s >|= ts_to_string
