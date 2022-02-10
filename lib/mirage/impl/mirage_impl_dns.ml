type dns_client = Dns_client

let dns_client = Dns_client

(*
let dns_client ?(timeout= timeout) nameservers =
  let connect info modname = function
    | [ _random; _time; _mclock; _pclock; stackv4v6 ] ->
      Fmt.str {ocaml|%s.connect %s >|= Rresult.R.failwith_error_msg|ocaml}
        modname stackv4v6 in
*)
