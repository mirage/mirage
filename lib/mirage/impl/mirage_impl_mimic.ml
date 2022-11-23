open Functoria
open Mirage_impl_dns
open Mirage_impl_stack
open Mirage_impl_happy_eyeballs

type mimic = Mimic

let mimic = Type.v Mimic

let mimic_merge =
  let packages = [ package "mimic" ] in
  let connect _ _modname = function
    | [ a; b ] -> Fmt.str "Lwt.return (Mimic.merge %s %s)" a b
    | [ x ] -> Fmt.str "%s.ctx" x
    | _ -> Fmt.str "Lwt.return Mimic.empty"
  in
  impl ~packages ~connect "Mimic.Merge" (mimic @-> mimic @-> mimic)

let mimic_happy_eyeballs =
  let packages = [ package "mimic-happy-eyeballs" ~min:"0.0.5" ] in
  let connect _ modname = function
    | [ _stackv4v6; _dns_client; happy_eyeballs ] ->
        Fmt.str {ocaml|%s.connect %s|ocaml} modname happy_eyeballs
    | _ -> assert false
  in
  impl ~packages ~connect "Mimic_happy_eyeballs.Make"
    (stackv4v6 @-> dns_client @-> happy_eyeballs @-> mimic)
