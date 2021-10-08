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

type t = { bin : (Fpath.t * Fpath.t) list; etc : Fpath.t list }

let v ?(bin = []) ?(etc = []) () = { bin; etc }

let empty = v ()

let dump ppf t =
  let bin ppf t = Fmt.Dump.(list (pair Fpath.pp Fpath.pp)) ppf t.bin in
  let etc ppf t = Fmt.Dump.(list Fpath.pp) ppf t.etc in
  Fmt.Dump.record [ bin; etc ] ppf t

let pp ppf t =
  let pp_bin ppf (src, dst) =
    Fmt.pf ppf "\n  \"%a\" {\"%a\"}" Fpath.pp src Fpath.pp dst
  in
  let pp_etc ppf file =
    Fmt.pf ppf "\n  \"%a\" {\"%s\"}" Fpath.pp file Fpath.(basename file)
  in
  let bins = List.map (Fmt.to_to_string pp_bin) t.bin in
  let etcs = List.map (Fmt.to_to_string pp_etc) t.etc in
  Fmt.pf ppf "bin: [%s%s]\n" (String.concat "" bins)
    (match bins with [] -> "" | _ -> "\n");
  Fmt.pf ppf "etc: [%s%s]" (String.concat "" etcs)
    (match etcs with [] -> "" | _ -> "\n")

let pp_opam ppf t =
  let pp_bin ppf (src, dst) =
    Fmt.pf ppf {|"cp" "dist/%a" "%%{bin}%%/%a"|} Fpath.pp src Fpath.pp dst
  in
  let pp_etc ppf etc = Fmt.pf ppf {|"cp" "dist/%a" "%%{etc}%%"|} Fpath.pp etc in
  Fmt.pf ppf "\n%a\n"
    (Fmt.list ~sep:(Fmt.any "\n") (fun ppf -> Fmt.pf ppf "  [ %a ]" pp_bin))
    t.bin;
  match t.etc with
  | [] -> ()
  | _ ->
      Fmt.pf ppf "%a\n"
        (Fmt.list ~sep:(Fmt.any "\n") (fun ppf -> Fmt.pf ppf "  [ %a ]" pp_etc))
        t.etc

let promote_artifact ~build_dir ~context_name ~src ~dst =
  Dune.stanzaf
    {|
(rule
 (mode (promote (until-clean)))
 (target %a)
 (enabled_if (= %%{context_name} "%s"))
 (action
  (copy %a %%{target}))
)
|}
    Fpath.pp dst context_name Fpath.pp
    Fpath.(build_dir // src)

let dune ~build_dir ~context_name t =
  let bin_rules =
    List.map
      (fun (src, dst) -> promote_artifact ~build_dir ~context_name ~src ~dst)
      t.bin
  in
  let etc_rules =
    List.map
      (fun etc -> promote_artifact ~build_dir ~context_name ~src:etc ~dst:etc)
      t.etc
  in
  Dune.v (bin_rules @ etc_rules)

let union_etc x y = Fpath.Set.(elements (union (of_list x) (of_list y)))

let union_bin x y = x @ y

let union x y = { bin = union_bin x.bin y.bin; etc = union_etc x.etc y.etc }
