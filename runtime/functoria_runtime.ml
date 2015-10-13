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

module Arg = struct

  type info = {
    doc  : string option;
    docs : string;
    docv : string option;
    names: string list;
    env  : string option;
  }

  let info ?(docs="UNIKERNEL PARAMETERS") ?docv ?doc ?env names =
    { doc; docs; docv; names; env }

  let cmdliner_of_info { docs; docv; doc; env; names } =
    let env = match env with
      | Some s -> Some (Cmdliner.Arg.env_var s)
      | None   -> None
    in
    Cmdliner.Arg.info ~docs ?docv ?doc ?env names

  type 'a kind =
    | Opt : 'a Cmdliner.Arg.converter -> 'a kind
    | Flag: bool kind

  type 'a t = {
    default: 'a;
    info   : info;
    kind   : 'a kind;
  }

  let flag info = { default = false; info; kind = Flag }
  let opt conv default info = { default; info; kind = Opt conv }
  let default t = t.default
  let kind t = t.kind
  let cmdliner_info t = cmdliner_of_info t.info

end

module Key = struct

  type 'a t = {
    name: string;
    arg : 'a Arg.t;
    mutable value: 'a option;
  }

  let create name arg = { name; arg; value = None }

  let get t = match t.value with
    | None   -> Arg.default t.arg
    | Some v -> v

  let term (type a) (t: a t) =
    let set w = t.value <- Some w in
    let default = Arg.default t.arg in
    let doc = Arg.cmdliner_info t.arg in
    let term arg = Cmdliner.Term.(pure set $ arg) in
    match Arg.kind t.arg with
    | Arg.Flag     -> term @@ Cmdliner.Arg.(value & flag doc)
    | Arg.Opt desc -> term @@ Cmdliner.Arg.(value & opt desc default doc)

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
