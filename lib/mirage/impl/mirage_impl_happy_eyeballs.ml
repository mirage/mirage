open Functoria
open Mirage_impl_time
open Mirage_impl_mclock
open Mirage_impl_stack
open Mirage_impl_dns
open Mirage_impl_misc

type happy_eyeballs = Happy_eyeballs

let happy_eyeballs = Type.v Happy_eyeballs

let generic_happy_eyeballs aaaa_timeout connect_delay connect_timeout
    resolve_timeout resolve_retries timer_interval =
  let packages =
    [ package "happy-eyeballs-mirage" ~min:"0.6.0" ~max:"1.0.0" ]
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
  let connect _info modname = function
    | [ _time; _mclock; stack; dns ] ->
        code ~pos:__POS__ {ocaml|%s.connect_device%a%a%a%a%a%a %s %s|ocaml}
          modname (pp_opt "aaaa_timeout") aaaa_timeout (pp_opt "connect_delay")
          connect_delay (pp_opt "connect_timeout") connect_timeout
          (pp_opt "resolve_timeout") resolve_timeout (pp_opt "resolve_retries")
          resolve_retries (pp_opt "timer_interval") timer_interval dns stack
    | _ -> connect_err "happy_eyeballs" 4
  in
  impl ~runtime_args ~packages ~connect "Happy_eyeballs_mirage.Make"
    (time @-> mclock @-> stackv4v6 @-> dns_client @-> happy_eyeballs)
