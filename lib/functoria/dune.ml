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

type stanza = string option
type t = string list

let stanza v = Some (String.trim v)
let stanzaf fmt = Fmt.kstr stanza fmt

let v x : t =
  List.fold_left
    (fun acc -> function None -> acc | Some f -> f :: acc)
    [] (List.rev x)

let pp_list pp = Fmt.(list ~sep:(any "\n\n") pp)
let pp ppf (t : t) = Fmt.pf ppf "%a" (pp_list Fmt.string) t
let to_string t = Fmt.to_to_string pp t ^ "\n"

(* emulate the dune compact form for lists *)
let compact_list ?(indent = 2) field ppf l =
  let all = Buffer.create 1024 in
  let line = Buffer.create 70 in
  let sep = "\n" ^ String.v ~len:indent (fun _ -> ' ') in
  let first_char = ref true in
  let first_line = ref true in
  let flush () =
    Buffer.add_buffer all line;
    Buffer.clear line;
    Buffer.add_string line sep;
    first_line := false
  in
  List.iter
    (fun w ->
      let max = if !first_line then 75 - indent - String.length field else 75 in
      let wn = String.length w in
      if wn >= 40 || Buffer.length line + wn >= max then flush ();
      if not !first_char then Buffer.add_char line ' ';
      first_char := false;
      Buffer.add_string line w)
    l;
  flush ();
  Fmt.pf ppf "%s" (Buffer.contents all)

let config ~config_file ~packages =
  let pkgs =
    match packages with
    | [] -> ""
    | pkgs ->
        let pkgs =
          List.fold_left
            (fun acc pkg ->
              let pkgs = String.Set.of_list (Package.libraries pkg) in
              String.Set.union pkgs acc)
            String.Set.empty pkgs
          |> String.Set.elements
        in
        Fmt.str "\n  (libraries %s)" (String.concat ~sep:" " pkgs)
  in
  let rename_config =
    let config_file = Fpath.base config_file in
    let ext = Fpath.get_ext config_file in
    let name = Fpath.rem_ext config_file |> Fpath.to_string in
    if name = "config" then None
    else stanzaf "(rule (copy %s config%s))" (Fpath.to_string config_file) ext
  in
  let includes =
    [ (* stanzaf "(subdir dist (include ../%a/dune.dist))" Fpath.pp gen_dir *) ]
  in
  let config_exe =
    stanzaf
      {|
(executable
 (name config)
 (enabled_if (= %%{context_name} "default"))
 (modules config)%s)
|}
      pkgs
  in
  [ rename_config; config_exe ] @ includes

let project = v [ stanza "(lang dune 3.0)\n(using directory-targets 0.1)" ]
let workspace = v [ stanza "(lang dune 3.0)\n(context default)" ]

let lib ~packages name =
  let pkgs =
    match packages with
    | [] -> ""
    | pkgs ->
        let pkgs =
          List.fold_left
            (fun acc pkg ->
              let pkgs = String.Set.of_list (Package.libraries pkg) in
              String.Set.union pkgs acc)
            String.Set.empty pkgs
          |> String.Set.elements
        in
        String.concat ~sep:" " pkgs
  in
  let dune =
    stanzaf
      {|
(library
  (name %s)
  (libraries %s)
  (modules (:standard \ config)))
|}
      name pkgs
  in
  [ dune ]

let directory_target ~config_file ~context_file gen_dir =
  let context_file = Fpath.normalize context_file in
  let dune =
    stanzaf
      {|
 (rule
  (targets (dir %a))
  (mode promote)
  (enabled_if (= %%{context_name} "default"))
  (deps ./config.exe %a)
  (action (run ./config.exe configure -f %a --init-app --context-file %a)))

(rule (copy %a/main.exe main.exe))
|}
      Fpath.pp gen_dir Fpath.pp context_file Fpath.pp context_file Fpath.pp
      config_file Fpath.pp gen_dir
  in
  [ dune ]
