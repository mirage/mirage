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

  type 'a kind =
    | Opt : 'a * 'a Cmdliner.Arg.converter -> 'a kind
    | Flag: bool kind
    | Required : 'a Cmdliner.Arg.converter -> 'a kind

  type 'a t = {
    info   : Cmdliner.Arg.info;
    kind   : 'a kind;
  }

  let flag info = { info; kind = Flag }
  let opt conv default info = { info; kind = Opt (default, conv) }
  let required conv info = { info; kind = Required conv }
  let key ?default c i = match default with
    | None -> required c i
    | Some d -> opt c d i

  let default (type a) (t : a t) = match t.kind with
    | Opt (d,_) -> Some d
    | Flag -> Some false
    | Required _ -> None

  let kind t = t.kind
  let info t = t.info

end

module Key = struct

  type 'a t = {
    arg : 'a Arg.t;
    mutable value: 'a option;
  }

  let create arg = { arg; value = None }

  let get t = match t.value with
    | None   -> invalid_arg "Key.get: Called too early. Please delay this call after cmdliner's evaluation."
    | Some v -> v

  let default t = Arg.default t.arg

  let term (type a) (t: a t) =
    let set w = t.value <- Some w in
    let doc = Arg.info t.arg in
    let term arg = Cmdliner.Term.(pure set $ arg) in
    match Arg.kind t.arg with
    | Arg.Flag     -> term @@ Cmdliner.Arg.(value & flag doc)
    | Arg.Opt (default, desc) ->
      term @@ Cmdliner.Arg.(value & opt desc default doc)
    | Arg.Required desc ->
      term @@ Cmdliner.Arg.(required & opt (some desc) None doc)

end

let initialized = ref false
let with_argv keys s argv =
  let open Cmdliner in
  if !initialized then ()
  else
    let gather k rest = Term.(pure (fun () () -> ()) $ k $ rest) in
    let t = List.fold_right gather keys (Term.pure ()) in
    match Term.(eval ~argv (t, info s)) with
    | `Ok _ -> initialized := true; ()
    | `Error _ -> failwith "Key initialization failed"
    | `Help | `Version -> exit 0
