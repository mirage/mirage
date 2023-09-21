open Functoria
module Key = Mirage_key
open Mirage_impl_pclock
open Mirage_impl_misc

type reporter = job

let reporter = job

let pp_level ppf = function
  | Some Logs.Error -> Fmt.string ppf "(Some Logs.Error)"
  | Some Logs.Warning -> Fmt.string ppf "(Some Logs.Warning)"
  | Some Logs.Info -> Fmt.string ppf "(Some Logs.Info)"
  | Some Logs.Debug -> Fmt.string ppf "(Some Logs.Debug)"
  | Some Logs.App -> Fmt.string ppf "(Some Logs.App)"
  | None -> Fmt.string ppf "None"

let mirage_log ~default () =
  let logs = Key.logs in
  let packages = [ package ~min:"2.0.0" ~max:"3.0.0" "mirage-logs" ] in
  let keys = [ Key.v logs ] in
  let connect _ modname = function
    | [ _pclock ] ->
        Fmt.str
          "@[<v 2>let reporter = %s.create () in@ Mirage_runtime.set_level \
           ~default:%a %a;@ Logs.set_reporter reporter;@ Lwt.return reporter@]"
          modname pp_level default pp_key logs
    | _ -> failwith (connect_err "log" 1)
  in
  impl ~packages ~keys ~connect "Mirage_logs.Make" (pclock @-> reporter)

let default_reporter ?(clock = default_posix_clock) ?(level = Some Logs.Info) ()
    =
  mirage_log ~default:level () $ clock

let no_reporter =
  let connect _ _ _ = "assert false" in
  impl ~connect "Mirage_runtime" reporter
