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

module Raw = struct
  type t

  (* Allocate an istring, via malloc *)
  external alloc: int -> t = "caml_alloc_istring"

  (* Get total size of an istring buffer *)
  external size: t -> int = "caml_istring_size" "noalloc"

  (* Get character *)
  external get: t -> int -> char = "caml_istring_safe_get"

  (* Blit string to istring *)
  external blit: t -> int -> string -> unit = "caml_istring_safe_blit" "noalloc"
end

module View = struct

  (* A view into a portion of an istring *)
  type t = { 
    i: Raw.t;          (* Reference to immutable string *)
    off: int;           (* Start offset within the istring *)
    mutable len: int;  (* Valid size of istring relative to offset *)
  }

  (* Get length of the view *)
  let length t =
    t.len

  (* Get a single character from the view *)
  let get t off =
    if off > t.len then raise (Invalid_argument "index out of bounds");
    Raw.get t.i (t.off+off)

  (* Append an ocaml string into the view *)
  let append t src =
    Raw.blit t.i t.off src;
    t.len <- String.length src + t.len

end

