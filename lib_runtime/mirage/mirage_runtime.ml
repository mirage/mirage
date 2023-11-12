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
include Functoria_runtime

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
end

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
