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

let runtime_keys_r = ref []
let runtime_keys () = !runtime_keys_r

module Key = struct
  type 'a t = { arg : 'a Cmdliner.Term.t; mutable value : 'a option }

  let create arg = { arg; value = None }

  let get t =
    match t.value with
    | None ->
        invalid_arg
          "Key.get: Called too early. Please delay this call after cmdliner's \
           evaluation."
    | Some v -> v

  let term (type a) (t : a t) =
    let set w = t.value <- Some w in
    Cmdliner.Term.(const set $ t.arg)

  let conv of_string to_string : _ Cmdliner.Arg.conv =
    let pp ppf v = Format.pp_print_string ppf (to_string v) in
    Cmdliner.Arg.conv (of_string, pp)
end

let key t =
  let u = Key.create t in
  runtime_keys_r := Key.term u :: !runtime_keys_r;
  fun () -> Key.get u

let initialized = ref false
let help_version = 63
let argument_error = 64

let with_argv keys s argv =
  let open Cmdliner in
  if !initialized then ()
  else
    let gather k rest = Term.(const (fun () () -> ()) $ k $ rest) in
    let t = List.fold_right gather keys (Term.const ()) in
    match Cmd.(eval_value ~argv (Cmd.v (info s) t)) with
    | Ok (`Ok _) ->
        initialized := true;
        ()
    | Error _ -> exit argument_error
    | Ok `Help | Ok `Version -> exit help_version
