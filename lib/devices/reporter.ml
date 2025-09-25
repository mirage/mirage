open Functoria.DSL

type reporter = job

let reporter = Functoria.job

let pp_level ppf = function
  | Some Logs.Error -> Fmt.string ppf "(Some Logs.Error)"
  | Some Logs.Warning -> Fmt.string ppf "(Some Logs.Warning)"
  | Some Logs.Info -> Fmt.string ppf "(Some Logs.Info)"
  | Some Logs.Debug -> Fmt.string ppf "(Some Logs.Debug)"
  | Some Logs.App -> Fmt.string ppf "(Some Logs.App)"
  | None -> Fmt.string ppf "None"

let default_reporter ?(level = Some Logs.Info) () =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-logs" ] in
  let runtime_args = [ Runtime_arg.v Runtime_arg.logs ] in
  let connect _ modname = function
    | [ logs ] ->
        code ~pos:__POS__
          "@[<v 2>let reporter = %s.create () in@ Mirage_runtime.set_level \
           ~default:%a %s;@ Logs.set_reporter reporter;@ Lwt.return reporter@]"
          modname pp_level level logs
    | _ -> Misc.connect_err "log" 1
  in
  impl ~packages ~runtime_args ~connect "Mirage_logs" reporter

let no_reporter =
  let connect _ _ _ = code ~pos:__POS__ "assert false" in
  impl ~connect "Mirage_runtime" reporter
