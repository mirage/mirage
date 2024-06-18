open Functoria.DSL
open Time
open Mclock
open Stack
open Misc

type happy_eyeballs = Happy_eyeballs

let happy_eyeballs = typ Happy_eyeballs

let generic_happy_eyeballs aaaa_timeout connect_delay connect_timeout
    resolve_timeout resolve_retries timer_interval =
  let packages =
    [ package "happy-eyeballs-mirage" ~min:"1.1.0" ~max:"1.2.0" ]
  in
  let runtime_args =
    runtime_args_opt
      [
        aaaa_timeout;
        connect_delay;
        resolve_timeout;
        resolve_retries;
        timer_interval;
      ]
  in
  let err () = connect_err "generic_happy_eyeballs" 3 ~max:4 in
  let connect _info modname = function
    | _time :: _mclock :: stack :: rest ->
        let aaaa_timeout, rest = pop ~err aaaa_timeout rest in
        let connect_delay, rest = pop ~err connect_delay rest in
        let connect_timeout, rest = pop ~err connect_timeout rest in
        let resolve_timeout, rest = pop ~err resolve_timeout rest in
        let resolve_retries, rest = pop ~err resolve_retries rest in
        let timer_interval, rest = pop ~err timer_interval rest in
        let () = match rest with [] -> () | _ -> err () in
        code ~pos:__POS__ {ocaml|Lwt.return (%s.create %a%a%a%a%a%a %s)|ocaml}
          modname (pp_opt "aaaa_timeout") aaaa_timeout (pp_opt "connect_delay")
          connect_delay (pp_opt "connect_timeout") connect_timeout
          (pp_opt "resolve_timeout") resolve_timeout (pp_opt "resolve_retries")
          resolve_retries (pp_opt "timer_interval") timer_interval stack
    | _ -> err ()
  in
  impl ~runtime_args ~packages ~connect "Happy_eyeballs_mirage.Make"
    (time @-> mclock @-> stackv4v6 @-> happy_eyeballs)
