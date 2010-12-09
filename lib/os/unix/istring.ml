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

  (* Allocate an istring, via malloc *)
  external alloc: int -> t = "caml_istring_alloc"

  (* Free an istring allocated via malloc *)
  external free: t -> unit = "caml_istring_free"

  (* Get total size of an istring buffer.  *)
  external size: t -> int = "caml_istring_size" "noalloc"

  (* Get and set valid size of an istring buffer. *)
  external valid: t -> int = "caml_istring_valid" "noalloc"
  external incr_valid: t -> int -> int -> unit = "caml_istring_incr_valid" "noalloc"
  
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
  external blit_istring: t -> int -> t -> int -> int -> unit = "caml_istring_safe_blit_view"

  (* Get character.
     Cannot be noalloc as it can raise an exception
   *)
  external to_char: t -> int -> char = "caml_istring_safe_get_char"

  (* Get an OCaml string slice. *)
  external to_string: t -> int -> int -> string = "caml_istring_safe_get_string"

  (* Get a big-endian uint16 out of the view *)
  external to_uint16_be: t -> int -> int = "caml_istring_get_uint16_be"

  (* Get a big-endian uint32 out of the view *)
  external to_uint32_be: t -> int -> int32 = "caml_istring_get_uint32_be"

  (* Get a big-endian uint64 out of the view *)
  external to_uint64_be: t -> int -> int64 = "caml_istring_get_uint64_be"
end

module View = struct
  open Printf

  (* A view into a portion of an istring *)
  type t = { 
    i: Raw.t;          (* Reference to immutable string *)
    off: int;          (* Start offset within the istring *)
    mutable pos: int;  (* Unmarshal position within view. TODO: move to MPL *)
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

  (* Increment a view reference count, and decrement it as 
     a GC finaliser *)
  let ref_wrap t =
    Raw.incr t.i;
    Gc.finalise (fun x -> Raw.decr t.i) t;
    t

  (* Generate a new view onto a raw istring *)
  let t i len = 
    ref_wrap { i; off=0; pos=0; len }

  (* Get length of the view *)
  let length t = t.len
  (* Get total valid size of buffer *)
  let valid t = Raw.valid t.i

  (* Generate a sub-view.
     TODO: validate len (autogenerated in MPL right now, so partly safe) 
   *)
  let sub t off len =
    ref_wrap { t with off=t.off+off; len=len; pos=0 }

  (* Copy a view. *)
  let copy t = 
    eprintf "copy: off=%d len=%d pos=%d\n%!" t.off t.len t.pos;
    ref_wrap { i=t.i; off=t.off; len=t.len; pos=t.pos }

  (** Marshal functions *)

  let set_string t off src =
    Raw.blit t.i (t.off+off) src;
    Raw.incr_valid t.i t.off (String.length src)

  let set_byte t off (v:byte) =
    Raw.set_byte t.i (t.off+off) v;
    Raw.incr_valid t.i t.off 1

  let set_uint16_be t off (v:uint16) =
    Raw.set_uint16_be t.i (t.off+off) v;
    Raw.incr_valid t.i t.off 2
    
  let set_uint32_be t off v =
    Raw.set_uint32_be t.i (t.off+off) v;
    Raw.incr_valid t.i t.off 4

  let set_uint64_be t off v =
    Raw.set_uint64_be t.i (t.off+off) v;
    Raw.incr_valid t.i t.off 8

  (* Append an OCaml string into the view *)
  let append_string t src =
    set_string t t.len src;
    t.len <- String.length src + t.len

  (* Append another view into this view *)
  let append_view dst src =
    Raw.blit_istring dst.i (dst.off+dst.len) src.i src.off src.len;
    dst.len <- src.len + dst.len;
    Raw.incr_valid dst.i dst.off src.len

  (* Append a byte to the view *)
  let append_byte t (v:byte) =
    set_byte t t.len v;
    t.len <- t.len + 1

  (* Append a uint16 to the view *)
  let append_uint16_be t (v:uint16) =
    set_uint16_be t t.len v;
    t.len <- t.len + 2

  (* Append a uint32 to the view *)
  let append_uint32_be t v =
    set_uint32_be t t.len v;
    t.len <- t.len + 4

  (* Append a uint64 to the view *)
  let append_uint64_be t v =
    set_uint64_be t t.len v;
    t.len <- t.len + 8

  (** Type cast functions *)

  (* Get a single character from the view *)
  let to_char t off =
    Raw.to_char t.i (t.off+off)

  (* Copy out an OCaml string from the view *)
  let to_string t off len =
    Raw.to_string t.i (t.off+off) len

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

  (* Unmarshalling position functions *)

  (* Skip forward a number of bytes, extending length if needed *)
  let skip t x =
    t.pos <- t.pos + x;
    if t.pos > t.len then t.len <- t.len + x

  (* Remaining bytes in the current view *)
  let remaining env = env.len - env.pos

  (* Current unmarshal position in view *)
  let pos env =
    env.pos

  (* Unmarshal a byte *)
  let unmarshal_byte t =
    let v = to_byte t t.pos in
    t.pos <- t.pos + 1;
    v

  (* Unmarshal a uint16 *)
  let unmarshal_uint16_be t =     
    let v = to_uint16_be t t.pos in
    t.pos <- t.pos + 2;
    v

  (* Unmarshal a uint32 *)
  let unmarshal_uint32_be t =     
    let v = to_uint32_be t t.pos in
    t.pos <- t.pos + 4;
    v

  (* Unmarshal a uint64 *)
  let unmarshal_uint64_be t =     
    let v = to_uint64_be t t.pos in
    t.pos <- t.pos + 8;
    v

end
