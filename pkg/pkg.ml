#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let metas = [
  Pkg.meta_file ~install:false "pkg/META.functoria";
  Pkg.meta_file ~install:false "pkg/META.functoria-runtime";
]

let opams =
  let install = false in
  [
    Pkg.opam_file ~install ~lint_deps_excluding:(Some ["ounit";"oUnit"]) "functoria.opam" ;
    Pkg.opam_file ~install ~lint_deps_excluding:None "functoria-runtime.opam"
  ]

let () =
  Pkg.describe ~metas ~opams "functoria" @@ fun c ->
  match Conf.pkg_name c with
  | "functoria" ->
    Ok [
      Pkg.lib "pkg/META.functoria" ~dst:"META";
      Pkg.lib "functoria.opam" ~dst:"opam" ;
      Pkg.mllib "lib/functoria.mllib";
      Pkg.mllib "app/functoria-app.mllib";
      Pkg.test  "tests/test_functoria_command_line"
    ]
  | "functoria-runtime" ->
    Ok [
      Pkg.lib "pkg/META.functoria-runtime" ~dst:"META" ;
      Pkg.lib "functoria-runtime.opam" ~dst:"opam" ;
      Pkg.mllib "runtime/functoria-runtime.mllib"
    ]
  | other ->
    R.error_msgf "unknown package name: %s" other
