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

let setup_log default style =
  let logs = Key.logs in
  impl @@ object
    inherit base_configurable
    method ty = job
    method name = "mirage_set_log"
    method module_name = "Mirage_runtime"
    method! keys = [ Key.abstract logs ]
    method! deps = [abstract style]
    method! connect _ modname _ =
      Fmt.strf
        "@[<v 2>\
         %s.set_level ~default:%a %a;@ \
         Lwt.return_unit@]"
        modname pp_level default pp_key logs
  end

let pp_style ppf = function
  | `Ansi_tty -> Fmt.string ppf "`Ansi_tty"
  | `None -> Fmt.string ppf "`None"

let channel x =
  if x == Pervasives.stdout then "Fmt.stdout" else "Fmt.stderr"

let setup_style chan style = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "mirage_setup_style"
    method module_name = "Mirage_runtime"
    method! connect _ _modname _ =
      let ppf = channel chan in
      Fmt.strf
        "@[<v 2>\
         Fmt.set_style_renderer %s %a;@ \
         Lwt.return_unit@]"
        ppf pp_style style
  end

let unix_setup_style = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "mirage_setup_style"
    method module_name = "Fmt_tty"
    method! packages = Key.pure [ package ~sublibs:["tty"] "fmt" ]
    method! connect _ modname _ =
      Fmt.strf
        "@[<v 2>\
         %s.setup_std_outputs ();@ \
         Lwt.return_unit@]"
        modname
  end

let basic_reporter chan setup =
  impl @@ object
    inherit base_configurable
    method ty = reporter
    method name = "mirage_basic_reporter"
    method module_name = "Logs_fmt"
    method! packages =
      Key.pure [ package ~sublibs:["fmt"] "logs" ]
    method! deps = [abstract setup]
    method! connect _ modname _ =
      Fmt.strf
        "@[<v 2>\
         let pp_header = Fmt.(suffix (unit \" \") %s.pp_header) in@ \
         let dst = %s in@ \
         let reporter = %s.reporter ~pp_header ~dst ~app:dst () in@ \
         Logs.set_reporter reporter;@ \
         Lwt.return_unit@]"
        modname (channel chan) modname
  end

let timestamp_reporter chan setup =
  impl @@ object
    inherit base_configurable
    method ty = pclock @-> reporter
    method name = "mirage_timestamp_reporter"
    method module_name = "Mirage_timestamp_reporter.Make"
    method! packages =
      Key.pure [ package "mirage-timestamp-reporter" ]
    method! deps = [abstract setup]
    method! connect _ modname _ =
        Fmt.strf
          "@[<v 2>\
           let dst = %s in@ \
           let reporter = %s.create ~dst () in@ \
           Logs.set_reporter reporter;@ \
           Lwt.return_unit@]"
          (channel chan) modname
  end

let trace_ring_reporter ring_size setup =
  impl @@ object
    inherit base_configurable
    method ty = pclock @-> reporter
    method name = "mirage_logs"
    method module_name = "Mirage_logs.Make"
    method! packages =
      Key.pure [ package ~min:"0.3.0" ~max:"0.4.0" "mirage-logs" ]
    method! deps = [abstract setup]
    method! connect _ modname = function
      | [ pclock ; _ ] ->
        Fmt.strf
          "@[<v 2>\
           let ring_size = %a in@ \
           let reporter = %s.create ?ring_size %s in@ \
           %s.set_reporter reporter;@ \
           Lwt.return_unit@]"
          Fmt.(Dump.option int) ring_size
          modname pclock
          modname
    | _ -> failwith (connect_err "trace_ring_reporter" 1)
  end

let default_setup channel ?(level = Logs.Info) ?style () =
  let style =
    match style with
    | None ->
      match_impl Key.(value target) [
        `Unix, unix_setup_style;
        `MacOSX, unix_setup_style
      ] ~default:Functoria_app.noop
    | Some x -> setup_style channel x
  in
  setup_log level style

let default_reporter ?(timestamp = true) ?(clock=default_posix_clock)
    ?ring_size ?level ?style ?(channel = stdout) () =
  let setup = default_setup channel ?level ?style () in
  match timestamp, ring_size with
  | false, None -> basic_reporter channel setup
  | true, None -> timestamp_reporter channel setup $ clock
  | _ -> trace_ring_reporter ring_size setup $ clock

let no_reporter = Functoria_app.noop
