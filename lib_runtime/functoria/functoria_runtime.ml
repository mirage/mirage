(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

let runtime_args_r = ref []
let runtime_args () = !runtime_args_r

module Arg = struct
  type 'a t = { arg : 'a Cmdliner.Term.t; mutable value : 'a option }

  let create arg = { arg; value = None }

  let get t =
    match t.value with
    | None ->
        invalid_arg
          "Called too early. Please delay this call to after the start \
           function of the unikernel."
    | Some v -> v

  let term (type a) (t : a t) =
    let set w = t.value <- Some w in
    Cmdliner.Term.(const set $ t.arg)
end

let initialized = ref false

let register_arg t =
  if !initialized then
    invalid_arg
      "The function register_arg was called to late. Please call register_arg \
       before the start function is executed (e.g. in a top-level binding).";
  let u = Arg.create t in
  runtime_args_r := Arg.term u :: !runtime_args_r;
  fun () -> Arg.get u

let register = register_arg
let help_version = 63
let argument_error = 64

let with_argv ?sections keys s argv =
  let open Cmdliner in
  if !initialized then ()
  else
    let gather k rest = Term.(const (fun () () -> ()) $ k $ rest) in
    let t = List.fold_right gather keys (Term.const ()) in
    let exits =
      [
        Cmd.Exit.info ~doc:"on success." Cmd.Exit.ok;
        Cmd.Exit.info ~doc:"on Solo5 internal error." 1;
        Cmd.Exit.info ~doc:"on showing this help." help_version;
        Cmd.Exit.info ~doc:"on any argument parsing error." argument_error;
        Cmd.Exit.info
          ~doc:
            "on unexpected internal errors (bugs) while processing the boot \
             parameters."
          Cmd.Exit.internal_error;
        Cmd.Exit.info ~doc:"on OCaml uncaught exception." 255;
      ]
    in
    let man = Option.map (List.map (fun s -> `S s)) sections in
    match Cmd.(eval_value ~argv (Cmd.v (info ?man ~exits s) t)) with
    | Ok (`Ok _) ->
        initialized := true;
        ()
    | Error `Parse -> exit argument_error
    | Error `Term ->
        print_endline
          "Hint: To pass a space, it needs to be escaped twice: \
           \027[1m--hello='Hello,\\ world!'\027[m";
        print_endline
          "      Another possibility is: \027[1m--hello='\"Hello, \
           world!\"'\027[m";
        exit argument_error
    | Error `Exn -> exit Cmd.Exit.internal_error
    | Ok `Help | Ok `Version -> exit help_version
