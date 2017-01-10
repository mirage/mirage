#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let metas = [
  Pkg.meta_file ~install:false "pkg/META.mirage";
  Pkg.meta_file ~install:false "pkg/META.mirage-types";
  Pkg.meta_file ~install:false "pkg/META.mirage-types-lwt";
  Pkg.meta_file ~install:false "pkg/META.mirage-runtime";
]

let opams =
  let lint_deps_excluding = None in
  let install = false in
  [
    Pkg.opam_file ~install ~lint_deps_excluding "mirage.opam";
    Pkg.opam_file ~install ~lint_deps_excluding "mirage-runtime.opam";
    Pkg.opam_file ~install ~lint_deps_excluding "mirage-types.opam";
    Pkg.opam_file ~install ~lint_deps_excluding "mirage-types-lwt.opam";
  ]

let () =
  Pkg.describe ~metas ~opams "mirage" @@ fun c ->
  match Conf.pkg_name c with
  | "mirage" ->
    Ok [ Pkg.lib "pkg/META.mirage" ~dst:"META";
         Pkg.lib "mirage.opam" ~dst:"opam";
         Pkg.mllib "lib/mirage.mllib";
         Pkg.bin "lib/mirage_cli" ~dst:"mirage"; ]
  | "mirage-runtime" ->
    Ok [ Pkg.lib "pkg/META.mirage-runtime" ~dst:"META";
         Pkg.lib "mirage-runtime.opam" ~dst:"opam";
         Pkg.mllib "lib_runtime/mirage-runtime.mllib"; ]
  | "mirage-types" ->
    Ok [ Pkg.lib "pkg/META.mirage-types" ~dst:"META";
         Pkg.lib "mirage-types.opam" ~dst:"opam";
         Pkg.lib ~exts:Exts.interface "types/mirage_types"; ]
  | "mirage-types-lwt" ->
    Ok [ Pkg.lib "pkg/META.mirage-types-lwt" ~dst:"META";
         Pkg.lib "mirage-types-lwt.opam" ~dst:"opam";
         Pkg.lib ~exts:Exts.interface "types/mirage_types_lwt"; ]
  | other ->
    R.error_msgf "unknown package name: %s" other
