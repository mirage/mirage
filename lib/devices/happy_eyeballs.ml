open Functoria.DSL

type happy_eyeballs = Happy_eyeballs

let happy_eyeballs = typ Happy_eyeballs

let generic_happy_eyeballs ?group ?aaaa_timeout ?connect_delay ?connect_timeout
    ?resolve_timeout ?resolve_retries ?timer_interval () =
  let packages =
    [ package "happy-eyeballs-mirage" ~min:"2.0.0" ~max:"3.0.0" ]
  in
  let aaaa_timeout = Runtime_arg.he_aaaa_timeout ?group aaaa_timeout
  and connect_delay = Runtime_arg.he_connect_delay ?group connect_delay
  and connect_timeout = Runtime_arg.he_connect_timeout ?group connect_timeout
  and resolve_timeout = Runtime_arg.he_resolve_timeout ?group resolve_timeout
  and resolve_retries = Runtime_arg.he_resolve_retries ?group resolve_retries
  and timer_interval = Runtime_arg.he_timer_interval ?group timer_interval in
  let runtime_args =
    Runtime_arg.
      [
        v aaaa_timeout;
        v connect_delay;
        v connect_timeout;
        v resolve_timeout;
        v resolve_retries;
        v timer_interval;
      ]
  in
  let connect _info modname = function
    | [
        stack;
        aaaa_timeout;
        connect_delay;
        connect_timeout;
        resolve_timeout;
        resolve_retries;
        timer_interval;
      ] ->
        code ~pos:__POS__
          {ocaml|%s.connect_device ?aaaa_timeout:%s ?connect_delay:%s
?connect_timeout:%s ?resolve_timeout:%s ?resolve_retries:%s ?timer_interval:%s %s|ocaml}
          modname aaaa_timeout connect_delay connect_timeout resolve_timeout
          resolve_retries timer_interval stack
    | _ -> Misc.connect_err "generic_happy_eyeballs" 7
  in
  impl ~runtime_args ~packages ~connect "Happy_eyeballs_mirage.Make"
    (Stack.stackv4v6 @-> happy_eyeballs)
