#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  Pkg.describe "functoria" @@ fun c ->
  Ok [
    Pkg.mllib "lib/functoria.mllib";
    Pkg.mllib "app/functoria-app.mllib";
    Pkg.mllib "runtime/functoria-runtime.mllib";
    Pkg.test ~run:false "tests/test_functoria_command_line";
  ]
