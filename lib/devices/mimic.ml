open Functoria.DSL
open Dns
open Stack
open Happy_eyeballs
open Misc

type mimic = Mimic

let mimic = typ Mimic

let mimic_happy_eyeballs =
  let packages = [ package "mimic-happy-eyeballs" ~min:"0.0.9" ] in
  let connect _ modname = function
    | [ _stackv4v6; happy_eyeballs; _dns_client ] ->
        code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname happy_eyeballs
    | _ -> connect_err "mimic" 3
  in
  impl ~packages ~connect "Mimic_happy_eyeballs.Make"
    (stackv4v6 @-> happy_eyeballs @-> dns_client @-> mimic)
