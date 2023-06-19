open Functoria
open Mirage_impl_time
open Mirage_impl_mclock
open Mirage_impl_stack
open Mirage_impl_dns

type happy_eyeballs = Happy_eyeballs

let happy_eyeballs = Type.v Happy_eyeballs

let generic_happy_eyeballs aaaa_timeout connect_delay connect_timeout
    resolve_timeout resolve_retries timer_interval =
  let packages =
    [ package "happy-eyeballs-mirage" ~min:"0.6.0" ~max:"1.0.0" ]
  in
  let keys =
    let cons_if_some v l = match v with Some x -> x :: l | None -> l in
    cons_if_some aaaa_timeout []
    |> cons_if_some connect_delay
    |> cons_if_some resolve_timeout
    |> cons_if_some resolve_retries
    |> cons_if_some timer_interval
    |> List.map Key.v
  in
  let connect _info modname = function
    | [ _time; _mclock; stack; dns ] ->
        let pp_optional_argument ~name ppf = function
          | None -> ()
          | Some key -> Fmt.pf ppf "?%s:%a " name Key.serialize_call (Key.v key)
        in
        Fmt.str {ocaml|%s.connect_device %a%a%a%a%a%a %s %s|ocaml} modname
          (pp_optional_argument ~name:"aaaa_timeout")
          aaaa_timeout
          (pp_optional_argument ~name:"connect_delay")
          connect_delay
          (pp_optional_argument ~name:"connect_timeout")
          connect_timeout
          (pp_optional_argument ~name:"resolve_timeout")
          resolve_timeout
          (pp_optional_argument ~name:"resolve_retries")
          resolve_retries
          (pp_optional_argument ~name:"timer_interval")
          timer_interval dns stack
    | _ -> assert false
  in
  impl ~keys ~packages ~connect "Happy_eyeballs_mirage.Make"
    (time @-> mclock @-> stackv4v6 @-> dns_client @-> happy_eyeballs)
