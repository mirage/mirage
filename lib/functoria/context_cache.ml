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

open Astring
open Action.Infix

let src = Logs.Src.create "functoria.cache" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

type t = string array

let empty = [| "" |]

let is_empty t = t = empty

let write file argv =
  Log.info (fun m ->
      m "Preserving arguments in %a:@ %a" Fpath.pp file
        Fmt.Dump.(array string)
        argv);
  (* Only keep args *)
  let args = List.tl (Array.to_list argv) in
  let args = List.map String.Ascii.escape args in
  let args = String.concat ~sep:"\n" args ^ "\n" in
  Action.write_file file args

let read file =
  Log.info (fun l -> l "reading cache %a" Fpath.pp file);
  Action.is_file file >>= function
  | false -> Action.ok empty
  | true -> (
      Action.read_file file >>= fun args ->
      let args = String.cuts ~sep:"\n" args in
      (* remove trailing '\n' *)
      let args = List.rev (List.tl (List.rev args)) in
      (* Add an empty command *)
      let args = "" :: args in
      let args = Array.of_list args in
      try
        let args =
          Array.map
            (fun x ->
              match String.Ascii.unescape x with
              | Some s -> s
              | None -> Fmt.failwith "%S: cannot parse" x)
            args
        in
        Action.ok args
      with Failure e -> Action.error e )

let peek t term =
  match Cmdliner.Term.eval_peek_opts ~argv:t term with
  | Some c, _ | _, `Ok c -> Some c
  | _ ->
      Fmt.failwith "Invalid cached configuration. Please run configure again."

let merge t term =
  let cache =
    match peek t term with None -> Key.empty_context | Some c -> c
  in
  let f term = Key.merge_context ~default:cache term in
  Cmdliner.Term.(pure f $ term)

let peek_output t = Cli.peek_output t

let file ~name args =
  match args.Cli.context_file with
  | Some f -> f
  | None ->
      let dir = Fpath.parent args.Cli.config_file in
      Fpath.(normalize (dir / (name ^ ".context")))
