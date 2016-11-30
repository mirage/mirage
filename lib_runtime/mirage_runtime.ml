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

type log_threshold = [`All | `Src of string] * Logs.level

let set_level ~default l =
  let srcs = Logs.Src.list () in
  let default =
    try snd @@ List.find (function (`All, _) -> true | _ -> false) l
    with Not_found -> default
  in
  Logs.set_level (Some default);
  List.iter (function
      | (`All, _) -> ()
      | (`Src src, level) ->
        try
          let s = List.find (fun s -> Logs.Src.name s = src) srcs in
          Logs.Src.set_level s (Some level)
        with Not_found ->
          Fmt.(pf stdout) "%a %s is not a valid log source.\n%!"
            Fmt.(styled `Yellow string) "Warning:" src
    ) l

module Arg = struct

  include Functoria_runtime.Arg

  let make of_string pp: _ Cmdliner.Arg.converter =
    let parser s = match of_string s with
      | Some ip -> `Ok ip
      | None -> `Error ("Can't parse ip address: "^s)
    in
    parser, pp

  module type S = sig
    type t
    val of_string : string -> t option
    val pp_hum : Format.formatter -> t -> unit
  end

  let of_module (type t) (module M:S with type t = t) =
    make M.of_string M.pp_hum

  let ip = of_module (module Ipaddr)
  let ipv4_address = of_module (module Ipaddr.V4)
  let ipv4 =
    let serialize fmt (prefix, ip) =
      Format.fprintf fmt "(Ipaddr.V4.Prefix.of_address_string_exn \"%s\")"
      @@ Ipaddr.V4.Prefix.to_address_string prefix ip
    in
    let parse str =
      match Ipaddr.V4.Prefix.of_address_string str with
      | None -> `Error (str ^ " is not a valid IPv4 address and netmask")
      | Some n -> `Ok n
    in
    parse, serialize

  let ipv6 = of_module (module Ipaddr.V6)
  let ipv6_prefix = of_module (module Ipaddr.V6.Prefix)

  let log_threshold =
    let enum = [
      "error"  , Logs.Error;
      "warning", Logs.Warning;
      "info"   , Logs.Info;
      "debug"  , Logs.Debug;
    ] in
    let level_of_string x =
      try List.assoc x enum
      with Not_found -> Fmt.kstrf failwith "%s is not a valid log level" x
    in
    let string_of_level x =
      try fst @@ List.find (fun (_, y) -> x = y) enum
      with Not_found -> "warning"
    in
    let parser str =
      match Astring.String.cut ~sep:":" str with
      | None            -> `Ok (`All    , level_of_string str)
      | Some ("*", str) -> `Ok (`All    , level_of_string str)
      | Some (src, str) -> `Ok (`Src src, level_of_string str)
    in
    let serialize ppf = function
      | `All  , l -> Fmt.string ppf (string_of_level l)
      | `Src s, l -> Fmt.pf ppf "%s:%s" s (string_of_level l)
    in
    parser, serialize

end

include
  (Functoria_runtime: module type of Functoria_runtime with module Arg := Arg)
