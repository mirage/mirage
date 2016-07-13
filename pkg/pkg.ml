#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let metas = [
  Pkg.meta_file ~install:false "pkg/META.mirage";
  Pkg.meta_file ~install:false "pkg/META.mirage-types";
  Pkg.meta_file ~install:false "pkg/META.mirage-types-lwt";
]

let opams =
  let lint_deps_excluding = None in
  let install = false in
  [
    Pkg.opam_file ~install ~lint_deps_excluding "mirage.opam";
    Pkg.opam_file ~install ~lint_deps_excluding "mirage-types.opam";
    Pkg.opam_file ~install ~lint_deps_excluding "mirage-types-lwt.opam";
  ]

let delegate = Cmd.(v "toy-github-topkg-delegate")

let () =
  Pkg.describe ~delegate ~metas ~opams "mirage" @@ fun c ->
  match Conf.pkg_name c with
  | "mirage" ->
    Ok [ Pkg.lib "pkg/META.mirage" ~dst:"META";
         Pkg.mllib "lib/mirage.mllib";
         Pkg.mllib "lib_runtime/mirage-runtime.mllib";
         Pkg.bin "lib/main" ~dst:"mirage"; ]
  | "mirage-types" ->
    Ok [ Pkg.lib "pkg/META.mirage-types" ~dst:"META";
         Pkg.lib "types/V1.mli";
         Pkg.lib "types/V1.cmi"; ]
  | "mirage-types-lwt" ->
    Ok [ Pkg.lib "pkg/META.mirage-types-lwt" ~dst:"META";
         Pkg.lib "types/V1_LWT.mli";
         Pkg.lib "types/V1_LWT.cmi"; ]
  | other ->
    R.error_msgf "unknown package name: %s" other
