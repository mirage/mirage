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

open Cmdliner

module Conv = struct
  type 'a t =  Flag: bool t | Opt: 'a Arg.converter -> 'a t
  let flag = Flag
  let opt x = Opt x
  let int = opt Arg.int
  let string = opt Arg.string
  let bool = opt Arg.bool
end

module Key = struct

  type 'a t = {
    doc: Arg.info;
    conv: 'a Conv.t;
    default: 'a;
    mutable value: 'a option;
  }

  let create ~doc ~default conv = { doc; default; conv; value = None }

  let get k = match k.value with
    | None -> k.default
    | Some v -> v

  let term (type a) ({ doc; conv; default } as t: a t) =
    let set w = t.value <- Some w in
    match conv with
    | Conv.Flag     -> Term.(pure set $ Arg.(value & flag doc))
    | Conv.Opt desc -> Term.(pure set $ Arg.(value & opt desc default doc))

end

let initialized = ref false
let with_argv keys s argv =
  let open Cmdliner in
  if !initialized then `Ok ()
  else
    let gather k rest = Term.(pure (fun () () -> ()) $ k $ rest) in
    let t = List.fold_right gather keys (Term.pure ()) in
    match Term.(eval ~argv (t, info s)) with
    | `Ok _ -> initialized := true; `Ok ()
    | `Error _ -> `Error "Key initialization failed"
    | `Help | `Version -> exit 0
