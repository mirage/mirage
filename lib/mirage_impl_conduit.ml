open Functoria
open Mirage_impl_conduit_connector

type conduit = Conduit
let conduit = Type Conduit

let conduit_with_connectors connectors = impl @@ object
    inherit base_configurable
    method ty = conduit
    method name = Functoria_app.Name.create "conduit" ~prefix:"conduit"
    method module_name = "Conduit_mirage"
    method! packages = Mirage_key.pure [ pkg ]
    method! deps = List.map abstract connectors

    method! connect _i _ = function
      | connectors ->
        let pp_connector = Fmt.fmt "%s >>=@ " in
        let pp_connectors = Fmt.list ~sep:Fmt.nop pp_connector in
        Fmt.strf
          "Lwt.return Conduit_mirage.empty >>=@ \
           %a\
           fun t -> Lwt.return t"
          pp_connectors connectors
  end

let conduit_direct ?(tls=false) s =
  (* TCP must be before tls in the list. *)
  let connectors = [tcp_conduit_connector $ s] in
  let connectors =
    if tls then
      connectors @ [tls_conduit_connector]
    else
      connectors
  in
  conduit_with_connectors connectors
