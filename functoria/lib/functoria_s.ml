(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

type 'a key = 'a Functoria_key.key

type 'a value = 'a Functoria_key.value

type keys = Functoria_key.t

type info = Functoria_info.t

type package = Functoria_package.t

type 'a typ = 'a Functoria_type.t

(* functor *)

type _ impl =
  | Dev : 'ty device -> 'ty impl (* base devices *)
  | App : ('a, 'b) app -> 'b impl (* functor application *)
  | If : bool value * 'a impl * 'a impl -> 'a impl

and ('a, 'b) app = {
  f : ('a -> 'b) impl;
  (* functor *)
  x : 'a impl; (* parameter *)
}

and abstract_impl = Abstract : _ impl -> abstract_impl

and 'a device = ('a, abstract_impl) Functoria_device.t
