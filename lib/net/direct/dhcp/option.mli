(*
 * Copyright (c) 2006-2011 Anil Madhavapeddy <anil@recoil.org>
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
 *
 *)

type msg =
    [ `Broadcast
    | `Client_id
    | `DNS_server
    | `Domain_name
    | `Domain_search
    | `End
    | `Host_name
    | `Interface_mtu
    | `Lease_time
    | `Max_size
    | `Message
    | `Message_type
    | `Name_server
    | `Netbios_name_server
    | `Pad
    | `Parameter_request
    | `Requested_ip
    | `Router
    | `Server_identifier
    | `Subnet_mask
    | `Time_offset
    | `Time_server
    | `Unknown of char ]
type op =
    [ `Ack
    | `Decline
    | `Discover
    | `Inform
    | `Nak
    | `Offer
    | `Release
    | `Request
    | `Unknown of char ]
type t =
    [ `Broadcast of Nettypes.ipv4_addr
    | `Client_id of string
    | `DNS_server of Nettypes.ipv4_addr list
    | `Domain_name of string
    | `Domain_search of string
    | `End
    | `Host_name of string
    | `Interface_mtu of int
    | `Lease_time of int32
    | `Max_size of int
    | `Message of string
    | `Message_type of op
    | `Name_server of Nettypes.ipv4_addr list
    | `Netbios_name_server of Nettypes.ipv4_addr list
    | `Pad
    | `Parameter_request of msg list
    | `Requested_ip of Nettypes.ipv4_addr
    | `Router of Nettypes.ipv4_addr list
    | `Server_identifier of Nettypes.ipv4_addr
    | `Subnet_mask of Nettypes.ipv4_addr
    | `Time_offset of string
    | `Time_server of Nettypes.ipv4_addr list
    | `Unknown of char * string ]
val msg_to_string : msg -> string
val op_to_string : op -> string
val t_to_string : t -> string
val ipv4_addr_to_bytes : Nettypes.ipv4_addr -> string
val ipv4_addr_of_bytes : string -> Nettypes.ipv4_addr
module Marshal :
  sig
    val t_to_code : msg -> int
    val to_byte : msg -> string
    val uint32_to_bytes : int32 -> string
    val uint16_to_bytes : int -> string
    val size : int -> string
    val ip_list : msg -> Nettypes.ipv4_addr list -> string list
    val ip_one : msg -> Nettypes.ipv4_addr -> string list
    val str : msg -> string -> string list
    val uint32 : msg -> int32 -> string list
    val uint16 : msg -> int -> string list
    val to_bytes : t -> string
    val options : op -> t list -> string
  end
module Unmarshal :
  sig
    exception Error of string
    val msg_of_code : char -> msg
    val of_bytes : string -> t list
  end
module Packet :
  sig
    type p = { op : op; opts : t list; }
    val of_bytes : string -> p
    val to_bytes : p -> string
    val prettyprint : p -> string
    val find : p -> (t -> 'a option) -> 'a option
    val findl : p -> (t -> 'a list option) -> 'a list
  end
