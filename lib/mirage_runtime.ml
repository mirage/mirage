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

let tuntap_help =
  "If using a tap device, is tun/tap enabled and have you permissions?"
let string_of_network_init_error name = function
  | `Unknown msg -> "\n\n"^name^": "^msg^"\n"^tuntap_help^"\n\n"
  | `Unimplemented -> "\n\n"^name^": operation unimplemented\n\n"
  | `Disconnected -> "\n\n"^name^": disconnected\n\n"
  | _ ->  "\n\n"^name^": unknown error\n\n"

module Configvar = struct
  type _ desc =
    | String : string desc
    | Ipaddrv4 : Ipaddr.V4.t desc
    | Ipaddrv6 : Ipaddr.V6.t desc
    | Ipaddrprefixv6 : Ipaddr.V6.Prefix.t desc
    | List : 'a desc -> 'a list desc
    | Dhcporstaticv4 : [ `DHCP | `IPv4 of Ipaddr.V4.t * Ipaddr.V4.t * Ipaddr.V4.t list ] desc

  let string = String
  let ipaddrv4 = Ipaddrv4
  let ipaddrv6 = Ipaddrv6
  let ipaddrprefixv6 = Ipaddrprefixv6
  let list d = List d
  let dhcporstaticv4 = Dhcporstaticv4

  let rec print_meta : type a. unit -> a desc -> string = fun () d ->
    match d with
    | String -> "string"
    | Ipaddrv4 -> "ipaddrv4"
    | Ipaddrv6 -> "ipaddrv6"
    | Ipaddrprefixv6 -> "ipaddrprefixv6"
    | List d -> Printf.sprintf "(list %a)" print_meta d
    | Dhcporstaticv4 -> "dhcporstaticv4"

  let rec print_ocaml : type a. a desc -> unit -> a -> string = fun d () x ->
    match d with
    | String ->
      Printf.sprintf "%S" x
    | Ipaddrv4 ->
      Printf.sprintf "(Ipaddr.V4.of_string_exn %S)" (Ipaddr.V4.to_string x)
    | Ipaddrv6 ->
      Printf.sprintf "(Ipaddr.V6.of_string_exn %S)" (Ipaddr.V6.to_string x)
    | Ipaddrprefixv6 ->
      Printf.sprintf "(Ipaddr.V6.Prefix.of_string_exn %S)" (Ipaddr.V6.Prefix.to_string x)
    | List d ->
      let rec aux () = function
        | [] -> ""
        | [x] -> print_ocaml d () x
        | x :: xs ->
          Printf.sprintf "%a; %a" (print_ocaml d) x aux xs
      in
      Printf.sprintf "[%a]" aux x
    | Dhcporstaticv4 ->
      let t = "[ `DHCP | `IPv4 of Ipaddr.V4.t * Ipaddr.V4.t * Ipaddr.V4.t list ]" in
      begin match x with
        | `DHCP -> Printf.sprintf "(`DHCP : %s)" t
        | `IPv4 (addr, nm, gws) ->
          Printf.sprintf
            "(`IPv4 (Ipaddr.V4.of_string_exn %S, Ipaddr.V4.of_string_exn %S, List.map Ipaddr.V4.of_string_exn [%s]) : %s)"
            (Ipaddr.V4.to_string addr)
            (Ipaddr.V4.to_string nm)
            (String.concat "; " (List.map (fun ip -> Printf.sprintf "%S" (Ipaddr.V4.to_string ip)) gws))
            t
      end

  module Cmdliner_aux = struct
    let rec converter : type a. a desc -> a Cmdliner.Arg.converter =
      function
      | String -> Cmdliner.Arg.string
      | Ipaddrv4 ->
        let parser s =
          match Ipaddr.V4.of_string s with
          | None -> `Error "unrecognized IPv4 address"
          | Some ip -> `Ok ip
        in
        let printer ppf x = Format.fprintf ppf "%s" (Ipaddr.V4.to_string x) in
        parser, printer
      | Ipaddrv6 ->
        let parser s =
          match Ipaddr.V6.of_string s with
          | None -> `Error "unrecognized IPv6 address"
          | Some ip -> `Ok ip
        in
        let printer ppf x = Format.fprintf ppf "%s" (Ipaddr.V6.to_string x) in
        parser, printer
      | Ipaddrprefixv6 ->
        let parser s =
          match Ipaddr.V6.Prefix.of_string s with
          | None -> `Error "unrecognized IPv6 netmask"
          | Some ip -> `Ok ip
        in
        let printer ppf x = Format.fprintf ppf "%s" (Ipaddr.V6.Prefix.to_string x) in
        parser, printer
      | List d ->
        Cmdliner.Arg.list (converter d)
      | Dhcporstaticv4 ->
        let parser s =
          try
            if String.lowercase s = "dhcp" then
              `Ok `DHCP
            else
              let p, _ = Cmdliner.Arg.list (converter Ipaddrv4) in
              let p s = match p s with `Ok x -> x | `Error _ -> failwith "parse error" in
              Scanf.sscanf s "static:%s@:%s@:%s" (fun addr nm gws ->
                  `Ok (`IPv4 (Ipaddr.V4.of_string_exn addr, Ipaddr.V4.of_string_exn nm, p gws)))
          with
          | _ ->
            `Error "parse error dhcporstaticv4"
        in
        let printer ppf = function
          | `DHCP -> Format.fprintf ppf "dhcp"
          | `IPv4 (addr, nm, gws) ->
            Format.fprintf ppf "static:%s:%s:%s"
              (Ipaddr.V4.to_string addr) (Ipaddr.V4.to_string nm)
              (String.concat "," (List.map Ipaddr.V4.to_string gws))
        in
        parser, printer

    let docs = "UNIKERNEL PARAMETERS"

    let term desc value ~doc ~name ~runtime =
      let open Cmdliner in
      let doc' = match !value with
        | None when runtime -> "REQUIRED."
        | _ -> "OPTIONAL."
      in
      let doc = String.concat " " [doc ^ "."; doc'] in
      let key_name = "key-" ^ name in
      let i = Arg.info ~docs ~docv:(String.uppercase name) ~doc [key_name] in
      let c = converter desc in
      match !value with
      | None when runtime ->
        let set w = value := Some w in
        Term.(pure set $ Arg.(required & opt (some c) None i))
      | None ->
        let set w = value := w in
        Term.(pure set $ Arg.(value & opt (some c) None i))
      | Some v ->
        let set w = value := Some w in
        Term.(pure set $ Arg.(value & opt c v i))

  end

  let rec print_human : type a. a desc -> unit -> a -> string = fun d () x ->
    let _, p = Cmdliner_aux.converter d in
    p Format.str_formatter x;
    Format.flush_str_formatter ()

  let rec parse_human : type a. a desc -> string -> a option =
    fun d s ->
      let p, _ = Cmdliner_aux.converter d in
      match p s with
      | `Ok x -> Some x
      | `Error _ -> None

end
