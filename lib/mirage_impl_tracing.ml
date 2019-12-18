open Functoria
open Mirage_impl_misc
open Rresult

module Key = Mirage_key

type tracing = job
let tracing = job

let mprof_trace ~size () =
  let unix_trace_file = "trace.ctf" in
  let key = Key.tracing_size size in
  impl @@ object
    inherit base_configurable
    method ty = job
    method name = "mprof_trace"
    method module_name = "MProf"
    method! keys = [ Key.abstract key ]
    method! packages =
      Key.match_ Key.(value target) @@ function
      | #Mirage_key.mode_xen ->
        [ package ~max:"1.0.0" "mirage-profile";
          package ~max:"1.0.0" ~min:"0.9.0" "mirage-profile-xen" ]
      | #Mirage_key.mode_solo5 -> []
      | #Mirage_key.mode_unix ->
        [ package ~max:"1.0.0" "mirage-profile";
          package ~max:"1.0.0" "mirage-profile-unix" ]
    method! build _ =
      match query_ocamlfind ["lwt.tracing"] with
      | Error _ | Ok [] ->
        R.error_msg "lwt.tracing module not found. Hint:\
                     opam pin add lwt https://github.com/mirage/lwt.git#tracing"
      | Ok _ -> Ok ()
    method! connect i _ _ = match get_target i with
      | #Mirage_key.mode_solo5 ->
        failwith  "tracing is not currently implemented for solo5 targets"
      | #Mirage_key.mode_unix ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
           @[<v 2> let buffer = MProf_unix.mmap_buffer ~size:%a %S in@ \
           let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in@ \
           MProf.Trace.Control.start trace_config@]"
          Key.serialize_call (Key.abstract key)
          unix_trace_file;
      | #Mirage_key.mode_xen ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
           @[<v 2> let trace_pages = MProf_xen.make_shared_buffer ~size:%a in@ \
           let buffer = trace_pages |> Io_page.to_cstruct |> Cstruct.to_bigarray in@ \
           let trace_config = MProf.Trace.Control.make buffer MProf_xen.timestamper in@ \
           MProf.Trace.Control.start trace_config;@ \
           MProf_xen.share_with ~domid:0 trace_pages@ \
           |> OS.Main.run@]"
          Key.serialize_call (Key.abstract key)
  end
