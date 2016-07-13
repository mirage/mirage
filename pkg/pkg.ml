#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let opams =
  let lint_deps_excluding = Some ["ounit"; "oUnit"] in
  [Pkg.opam_file ~lint_deps_excluding "opam"]

let () =
  Pkg.describe ~opams "functoria" @@ fun c ->
  Ok [
    Pkg.mllib "lib/functoria.mllib";
    Pkg.mllib "app/functoria-app.mllib";
    Pkg.mllib "runtime/functoria-runtime.mllib";
    Pkg.test ~run:false "tests/test_functoria_command_line";
  ]
