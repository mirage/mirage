open Functoria.DSL
open Ip
open Mclock
open Misc
open Random
open Time

type 'a tcp = TCP
type tcpv4v6 = v4v6 tcp

let tcp = Functoria.Type.Type TCP
let tcpv4v6 : tcpv4v6 typ = tcp

(* this needs to be a function due to the value restriction. *)
let tcp_direct_func ip time clock random =
  let packages_v =
    Key.(if_ is_unix)
      (right_tcpip_library ~sublibs:[ "tcp" ; "tcp-unix" ] "tcpip")
      (right_tcpip_library ~sublibs:[ "tcp" ; "tcp-direct" ] "tcpip")
  in
  let connect _ modname = function
    | [ ip; _time; _clock; _random ] ->
        code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> connect_err "tcp" 4
  in
  let extra_deps = [ dep ip ; dep time ; dep clock ; dep random ] in
  impl ~extra_deps ~packages_v ~connect "Tcp" tcp

let tcp_impl ?(mclock = default_monotonic_clock) ?(time = default_time)
    ?(random = default_random) ip =
  tcp_direct_func ip time mclock random
