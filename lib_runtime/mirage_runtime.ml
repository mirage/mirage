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
let s_arg = "UNIKERNEL ARGUMENTS"
let s_net = "NETWORK OPTIONS"
let s_log = "LOG AND MONITORING OPTIONS"
let s_disk = "DISK OPTIONS"
let s_ocaml = "COMMON OCAML RUNTIME OPTIONS"

type log_threshold = [ `All | `Src of string ] * Logs.level option

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

  let allocation_policy, allocation_policy_doc_alts =
    let enum =
      [
        ("next-fit", `Next_fit);
        ("first-fit", `First_fit);
        ("best-fit", `Best_fit);
      ]
    in
    (Arg.enum enum, Arg.doc_alts_enum enum)
end

let backtrace =
  let doc =
    "Trigger the printing of a stack backtrace when an uncaught exception \
     aborts the unikernel."
  in
  let doc = Arg.info ~docs:s_ocaml ~docv:"BOOL" ~doc [ "backtrace" ] in
  Arg.(value & opt bool true doc)

let randomize_hashtables =
  let doc = "Turn on randomization of all hash tables by default." in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"BOOL" ~doc [ "randomize-hashtables" ]
  in
  Arg.(value & opt bool true doc)

let allocation_policy =
  let doc =
    Printf.sprintf
      "The policy used for allocating in the OCaml heap. Possible values are: \
       %s. Best-fit is only supported since OCaml 4.10."
      Conv.allocation_policy_doc_alts
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"ALLOCATION" ~doc [ "allocation-policy" ]
  in
  Arg.(value & opt Conv.allocation_policy `Best_fit doc)

let minor_heap_size =
  let doc = "The size of the minor heap (in words). Default: 256k." in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"MINOR SIZE" ~doc [ "minor-heap-size" ]
  in
  Arg.(value & opt (some int) None doc)

let major_heap_increment =
  let doc =
    "The size increment for the major heap (in words). If less than or equal \
     1000, it is a percentage of the current heap size. If more than 1000, it \
     is a fixed number of words. Default: 15."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"MAJOR INCREMENT" ~doc
      [ "major-heap-increment" ]
  in
  Arg.(value & opt (some int) None doc)

let space_overhead =
  let doc =
    "The percentage of live data of wasted memory, due to GC does not \
     immediately collect unreachable blocks. The major GC speed is computed \
     from this parameter, it will work more if smaller. Default: 80."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"SPACE OVERHEAD" ~doc [ "space-overhead" ]
  in
  Arg.(value & opt (some int) None doc)

let max_space_overhead =
  let doc =
    "Heap compaction is triggered when the estimated amount of wasted memory \
     exceeds this (percentage of live data). If above 1000000, compaction is \
     never triggered. Default: 500."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"MAX SPACE OVERHEAD" ~doc
      [ "max-space-overhead" ]
  in
  Arg.(value & opt (some int) None doc)

let gc_verbosity =
  let doc =
    "GC messages on standard error output. Sum of flags. Check GC module \
     documentation for details."
  in
  let doc = Arg.info ~docs:s_ocaml ~docv:"VERBOSITY" ~doc [ "gc-verbosity" ] in
  Arg.(value & opt (some int) None doc)

let gc_window_size =
  let doc =
    "The size of the window used by the major GC for smoothing out variations \
     in its workload. Between 1 adn 50, default: 1."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"WINDOW SIZE" ~doc [ "gc-window-size" ]
  in
  Arg.(value & opt (some int) None doc)

let custom_major_ratio =
  let doc =
    "Target ratio of floating garbage to major heap size for out-of-heap \
     memory held by custom values. Default: 44."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"CUSTOM MAJOR RATIO" ~doc
      [ "custom-major-ratio" ]
  in
  Arg.(value & opt (some int) None doc)

let custom_minor_ratio =
  let doc =
    "Bound on floating garbage for out-of-heap memory held by custom values in \
     the minor heap. Default: 100."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"CUSTOM MINOR RATIO" ~doc
      [ "custom-minor-ratio" ]
  in
  Arg.(value & opt (some int) None doc)

let custom_minor_max_size =
  let doc =
    "Maximum amount of out-of-heap memory for each custom value allocated in \
     the minor heap. Default: 8192 bytes."
  in
  let doc =
    Arg.info ~docs:s_ocaml ~docv:"CUSTOM MINOR MAX SIZE" ~doc
      [ "custom-minor-max-size" ]
  in
  Arg.(value & opt (some int) None doc)

let logs =
  let docs = s_log in
  let logs = Arg.list Conv.log_threshold in
  let doc =
    "Be more or less verbose. $(docv) must be of the form \
     $(b,*:info,foo:debug) means that that the log threshold is set to \
     $(b,info) for every log sources but the $(b,foo) which is set to \
     $(b,debug)."
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
let with_argv = Functoria_runtime.with_argv ~sections:[ s_arg; s_net; s_log; s_disk; s_ocaml ]
let runtime_args = Functoria_runtime.runtime_args
let register = Functoria_runtime.register
let argument_error = Functoria_runtime.argument_error
let help_version = Functoria_runtime.help_version
