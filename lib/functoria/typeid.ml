(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

type (_, _) witness = Eq : ('a, 'a) witness | NotEq : ('a, 'b) witness

let to_bool : type a b. (a, b) witness -> bool = function
  | Eq -> true
  | NotEq -> false

module Id = struct
  type _ t = ..
end

module type ID = sig
  type t
  type _ Id.t += Tid : t Id.t

  val id : int
end

type 'a t = (module ID with type t = 'a)

let gen_id =
  let r = ref 0 in
  fun () ->
    incr r;
    !r

let gen () (type s) =
  let module M = struct
    type t = s
    type _ Id.t += Tid : t Id.t

    let id = gen_id ()
  end in
  (module M : ID with type t = s)

let witness : type r s. r t -> s t -> (r, s) witness =
 fun r s ->
  let module R = (val r : ID with type t = r) in
  let module S = (val s : ID with type t = s) in
  match R.Tid with S.Tid -> Eq | _ -> NotEq

let equal a b = to_bool @@ witness a b
let pp (type a) ppf ((module M) : a t) = Fmt.int ppf M.id
let id (type a) ((module M) : a t) = M.id
