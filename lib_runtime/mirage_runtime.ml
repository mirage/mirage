(*
 * Copyright (c) 2014 David Sheets <sheets@alum.mit.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Cmdliner

(* The order of the argument sections in the manpage can be enforced in the call to [with_argv] *)
let s_net = "NETWORK OPTIONS"
let s_dns = "DNS OPTIONS"
let s_he = "HAPPY EYEBALLS OPTIONS"
let s_ssh = "SSH OPTIONS"
let s_tls = "TLS OPTIONS"
let s_http = "HTTP OPTIONS"
let s_log = "LOG AND MONITORING OPTIONS"
let s_disk = "DISK OPTIONS"
let s_ocaml = "OCAML RUNTIME OPTIONS"

type log_threshold = [ `All | `Src of string ] * Logs.level option

(* We provisionally record backtraces until the [backtrace] runtime argument
   further below is evaluated. This ensures we get proper backtraces if someone
   calls [register_arg _ ()] too early before command line arguments are
   evaluated. *)
let () = Printexc.record_backtrace true

let set_level ~default l =
  let srcs = Logs.Src.list () in
  let default =
    try snd @@ List.find (function `All, _ -> true | _ -> false) l
    with Not_found -> default
  in
  Logs.set_level default;
  List.iter
    (function
      | `All, _ -> ()
      | `Src src, level -> (
          try
            let s = List.find (fun s -> Logs.Src.name s = src) srcs in
            Logs.Src.set_level s level
          with Not_found ->
            Format.printf "WARNING: %s is not a valid log source.\n%!" src))
    l

module Conv = struct
  let log_threshold =
    let parser str =
      let level src s =
        Result.bind (Logs.level_of_string s) (fun l -> Ok (src, l))
      in
      match String.split_on_char ':' str with
      | [ _ ] -> level `All str
      | [ "*"; lvl ] -> level `All lvl
      | [ src; lvl ] -> level (`Src src) lvl
      | _ -> Error (`Msg ("Can't parse log threshold: " ^ str))
    in
    let serialize ppf = function
      | `All, l -> Format.pp_print_string ppf (Logs.level_to_string l)
      | `Src s, l -> Format.fprintf ppf "%s:%s" s (Logs.level_to_string l)
    in
    Arg.conv (parser, serialize)
end

let logs =
  let enum =
    List.map
      (fun v -> (Logs.level_to_string v, v))
      Logs.[ None; Some App; Some Error; Some Warning; Some Info; Some Debug ]
  in
  let docs = s_log in
  let logs = Arg.list Conv.log_threshold in
  let doc =
    Printf.sprintf
      "Be more or less verbose. $(docv) must be of the form \
       $(b,*:info,foo:debug) means that that the log threshold is set to \
       $(b,info) for every log sources but the $(b,foo) which is set to \
       $(b,debug). The log level must be %s."
      (Arg.doc_alts_enum enum)
  in
  let doc = Arg.info ~docv:"LEVEL" ~doc ~docs [ "l"; "logs" ] in
  Arg.(value & opt logs [] doc)

(** {3 Blocks} *)

let disk =
  let doc =
    Arg.info ~docs:s_disk
      ~doc:
        "Name of the docteur disk (for Solo5 targets, the name must contains \
         only alpanumeric characters)."
      [ "disk" ]
  in
  Arg.(value & opt string "disk" doc)

let analyze =
  let doc =
    Arg.info ~docs:s_disk
      ~doc:"Analyze at the boot time the given docteur disk." [ "analyze" ]
  in
  Arg.(value & opt bool true doc)

(** {3 Initial delay} *)

let delay =
  let doc =
    Arg.info ~docs:Cmdliner.Manpage.s_common_options
      ~doc:"Delay n seconds before starting up" [ "delay" ]
  in
  Arg.(value & opt int 0 doc)

(** {3 Name} *)

let name_k =
  let doc =
    Arg.info ~docs:Cmdliner.Manpage.s_common_options
      ~doc:
        "Runtime name of the unikernel. Accessible with `Mirage_runtime.name` \
         (), used for example by syslog"
      ~absent:
        "defaults to the configuration-time name (first argument to \
         `Mirage.register`)"
      [ "name" ]
  in
  Arg.(value & opt (some' string) None doc)

let _name : string option ref = ref None
let set_name s = _name := Some s

let name =
  let r = Functoria_runtime.register_arg name_k in
  fun () ->
    match (r (), !_name) with
    | Some x, _ -> x
    | None, Some x -> x
    | None, None -> "no-name"

(* Hooks *)

let exit_hooks = ref []
let enter_iter_hooks = ref []
let leave_iter_hooks = ref []
let run t = List.iter (fun f -> f ()) !t
let add f t = t := f :: !t

let run_exit_hooks () =
  Lwt_list.iter_s
    (fun hook -> Lwt.catch (fun () -> hook ()) (fun _ -> Lwt.return_unit))
    !exit_hooks

let run_enter_iter_hooks () = run enter_iter_hooks
let run_leave_iter_hooks () = run leave_iter_hooks
let at_exit f = add f exit_hooks
let at_leave_iter f = add f leave_iter_hooks
let at_enter_iter f = add f enter_iter_hooks

let with_argv =
  Functoria_runtime.with_argv
    ~sections:
      [
        Manpage.s_arguments;
        Manpage.s_options;
        s_http;
        s_ssh;
        s_tls;
        s_he;
        s_dns;
        s_net;
        s_log;
        s_disk;
        s_ocaml;
      ]

let runtime_args = Functoria_runtime.runtime_args
let register = Functoria_runtime.register_arg
let register_arg = Functoria_runtime.register_arg
let argument_error = Functoria_runtime.argument_error
let help_version = Functoria_runtime.help_version
