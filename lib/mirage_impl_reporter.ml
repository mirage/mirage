open Functoria
module Key = Mirage_key
open Mirage_impl_pclock
open Mirage_impl_misc

type reporter = job
let reporter = job

let pp_level ppf = function
  | Logs.Error    -> Fmt.string ppf "Logs.Error"
  | Logs.Warning  -> Fmt.string ppf "Logs.Warning"
  | Logs.Info     -> Fmt.string ppf "Logs.Info"
  | Logs.Debug    -> Fmt.string ppf "Logs.Debug"
  | Logs.App      -> Fmt.string ppf "Logs.App"

let mirage_log ?ring_size ~default =
  let logs = Key.logs in
  impl @@ object
    inherit base_configurable
    method ty = pclock @-> reporter
    method name = "mirage_logs"
    method module_name = "Mirage_logs.Make"
    method! packages = Key.pure [ package ~min:"0.3.0" "mirage-logs"]
    method! keys = [ Key.abstract logs ]
    method! connect _ modname = function
      | [ pclock ] ->
        Fmt.strf
          "@[<v 2>\
           let ring_size = %a in@ \
           let reporter = %s.create ?ring_size %s in@ \
           Mirage_runtime.set_level ~default:%a %a;@ \
           %s.set_reporter reporter;@ \
           Lwt.return reporter"
          Fmt.(Dump.option int) ring_size
          modname pclock
          pp_level default
          pp_key logs
          modname
    | _ -> failwith (connect_err "log" 1)
  end

let default_reporter
    ?(clock=default_posix_clock) ?ring_size ?(level=Logs.Info) () =
  mirage_log ?ring_size ~default:level $ clock

let no_reporter = impl @@ object
    inherit base_configurable
    method ty = reporter
    method name = "no_reporter"
    method module_name = "Mirage_runtime"
    method! connect _ _ _ = "assert false"
  end
