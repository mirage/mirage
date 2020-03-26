open Functoria
module Key = Mirage_key
open Mirage_impl_pclock
open Mirage_impl_misc

type reporter = job

let reporter = job

let pp_level ppf = function
  | Logs.Error -> Fmt.string ppf "Logs.Error"
  | Logs.Warning -> Fmt.string ppf "Logs.Warning"
  | Logs.Info -> Fmt.string ppf "Logs.Info"
  | Logs.Debug -> Fmt.string ppf "Logs.Debug"
  | Logs.App -> Fmt.string ppf "Logs.App"

let mirage_log ?ring_size ~default =
  let logs = Key.logs in
  let packages = [ package ~min:"1.2.0" ~max:"2.0.0" "mirage-logs" ] in
  let keys = [ Key.v logs ] in
  let connect _ modname = function
    | [ _pclock ] ->
        Fmt.strf
          "@[<v 2>let ring_size = %a in@ let reporter = %s.create ?ring_size \
           () in@ Mirage_runtime.set_level ~default:%a %a;@ %s.set_reporter \
           reporter;@ Lwt.return reporter"
          Fmt.(Dump.option int)
          ring_size modname pp_level default pp_key logs modname
    | _ -> failwith (connect_err "log" 1)
  in
  impl ~packages ~keys ~connect "Mirage_logs.Make" (pclock @-> reporter)

let default_reporter ?(clock = default_posix_clock) ?ring_size
    ?(level = Logs.Info) () =
  mirage_log ?ring_size ~default:level $ clock

let no_reporter =
  let connect _ _ _ = "assert false" in
  impl ~connect "Mirage_runtime" reporter
