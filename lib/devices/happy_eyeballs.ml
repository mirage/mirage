open Functoria.DSL
open Time
open Mclock
open Stack
open Misc

type happy_eyeballs = Happy_eyeballs

let happy_eyeballs = typ Happy_eyeballs

let generic_happy_eyeballs timer_interval =
  let packages =
    [ package "happy-eyeballs-mirage" ~min:"1.1.0" ~max:"1.2.0" ]
  in
  let runtime_args = runtime_args_opt [ timer_interval ] in
  let err () = connect_err "generic_happy_eyeballs" 3 ~max:4 in
  let connect _info modname = function
    | _time :: _mclock :: stack :: rest ->
        let timer_interval, rest = pop ~err timer_interval rest in
        let () = match rest with [] -> () | _ -> err () in
        code ~pos:__POS__ {ocaml|Lwt.return (%s.create %a %s)|ocaml} modname
          (pp_opt "timer_interval") timer_interval stack
    | _ -> err ()
  in
  impl ~runtime_args ~packages ~connect "Happy_eyeballs_mirage.Make"
    (time @-> mclock @-> stackv4v6 @-> happy_eyeballs)
