module Key = Mirage_key
open Functoria
open Mirage_impl_misc
open Rresult

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
      | `Xen | `Qubes -> [ package "mirage-profile"; package "mirage-profile-xen" ]
      | `Virtio | `Hvt | `Muen | `Genode -> []
      | `Unix | `MacOSX -> [ package "mirage-profile"; package "mirage-profile-unix" ]
    method! build _ =
      match query_ocamlfind ["lwt.tracing"] with
      | Error _ | Ok [] ->
        R.error_msg "lwt.tracing module not found. Hint:\
                     opam pin add lwt https://github.com/mirage/lwt.git#tracing"
      | Ok _ -> Ok ()
    method! connect i _ _ = match get_target i with
      | `Virtio | `Hvt | `Muen | `Genode -> failwith  "tracing is not currently implemented for solo5 targets"
      | `Unix | `MacOSX ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
           @[<v 2> let buffer = MProf_unix.mmap_buffer ~size:%a %S in@ \
           let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in@ \
           MProf.Trace.Control.start trace_config@]"
          Key.serialize_call (Key.abstract key)
          unix_trace_file;
      | `Xen | `Qubes ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
           @[<v 2> let trace_pages = MProf_xen.make_shared_buffer ~size:%a in@ \
           let buffer = trace_pages |> Io_page.to_cstruct |> Cstruct.to_bigarray in@ \
           let trace_config = MProf.Trace.Control.make buffer MProf_xen.timestamper in@ \
           MProf.Trace.Control.start trace_config;@ \
           MProf_xen.share_with (module Gnt.Gntshr) (module OS.Xs) ~domid:0 trace_pages@ \
           |> OS.Main.run@]"
          Key.serialize_call (Key.abstract key)
  end
