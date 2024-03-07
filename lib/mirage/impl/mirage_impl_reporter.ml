open Functoria
module Key = Mirage_key
module Runtime_arg = Mirage_runtime_arg
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
  let logs = Runtime_arg.logs in
  let packages = [ package ~min:"2.0.0" ~max:"3.0.0" "mirage-logs" ] in
  let runtime_args = [ Runtime_arg.v logs ] in
  let connect _ modname = function
    | [ _pclock; logs ] ->
        code ~pos:__POS__
          "@[<v 2>let reporter = %s.create () in@ Mirage_runtime.set_level \
           ~default:%a %s;@ Logs.set_reporter reporter;@ Lwt.return reporter@]"
          modname pp_level default logs
    | _ -> connect_err "log" 2
  in
  impl ~packages ~runtime_args ~connect "Mirage_logs.Make" (pclock @-> reporter)

let default_reporter ?(clock = default_posix_clock) ?(level = Some Logs.Info) ()
    =
  mirage_log ~default:level () $ clock

let no_reporter =
  let connect _ _ _ = code ~pos:__POS__ "assert false" in
  impl ~connect "Mirage_runtime" reporter
