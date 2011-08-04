(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

exception Unparsable of string * Bitstring.bitstring

val ( |> ) : 'a -> ('a -> 'b) -> 'b
val ( >> ) : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c
val ( ||> ) : 'a list -> ('a -> 'b) -> 'b list
val ( +++ ) : int32 -> int32 -> int32
val ( &&& ) : int32 -> int32 -> int32
val ( ||| ) : int32 -> int32 -> int32
val ( ^^^ ) : int32 -> int32 -> int32
val ( <<< ) : int32 -> int -> int32
val ( >>> ) : int32 -> int -> int32
val join : string -> string list -> string
val stop : 'a * 'b -> 'a
type domain_name = string list
type int16 = int
type ipv4 = int32
val ipv4_to_string : int32 -> string
type byte = char
val byte : int -> byte
val int_of_byte : char -> int
val int32_of_byte : char -> int32
val int32_of_int : int -> int32
type bytes = string
val bytes_to_hex_string : char array -> string array
val bytes_of_bitstring : Bitstring.bitstring -> string
val ipv4_addr_of_bytes : string -> int32
type label = L of string * int | P of int * int | Z of int
val parse_charstr : string * int * int -> string * (string * int * int)
val parse_label : int -> Bitstring.bitstring -> label * (string * int * int)
val parse_name : (int, label) Hashtbl.t -> int -> Bitstring.bitstring -> string list * Bitstring.bitstring
type rr_type =
    [ `A
    | `A6
    | `AAAA
    | `AFSDB
    | `APL
    | `ATMA
    | `CERT
    | `CNAME
    | `DNAME
    | `DNSKEY
    | `DS
    | `EID
    | `GID
    | `GPOS
    | `HINFO
    | `IPSECKEY
    | `ISDN
    | `KEY
    | `KM
    | `LOC
    | `MB
    | `MD
    | `MF
    | `MG
    | `MINFO
    | `MR
    | `MX
    | `NAPTR
    | `NIMLOC
    | `NS
    | `NSAP
    | `NSAP_PTR
    | `NSEC
    | `NULL
    | `NXT
    | `OPT
    | `PTR
    | `PX
    | `RP
    | `RRSIG
    | `RT
    | `SIG
    | `SINK
    | `SOA
    | `SPF
    | `SRV
    | `SSHFP
    | `TXT
    | `UID
    | `UINFO
    | `UNSPEC
    | `Unknown of int * bytes
    | `WKS
    | `X25 ]
val int_of_rr_type : rr_type -> int
val rr_type_of_int : int -> rr_type
val string_of_rr_type : rr_type -> string
type rr_rdata =
    [ `A of int32
    | `AAAA of bytes
    | `AFSDB of int16 * domain_name
    | `CNAME of domain_name
    | `HINFO of string * string
    | `ISDN of string
    | `MB of domain_name
    | `MD of domain_name
    | `MF of domain_name
    | `MG of domain_name
    | `MINFO of domain_name * domain_name
    | `MR of domain_name
    | `MX of int16 * domain_name
    | `NS of domain_name
    | `PTR of domain_name
    | `RP of domain_name * domain_name
    | `RT of int16 * domain_name
    | `SOA of
        domain_name * domain_name * int32 * int32 * int32 * int32 * int32
    | `SRV of int16 * int16 * int16 * domain_name
    | `TXT of string list
    | `UNKNOWN of int * bytes
    | `UNSPEC of bytes
    | `WKS of int32 * byte * string
    | `X25 of string ]
val string_of_rdata : [> `A of int32 | `NS of string list ] -> string
val parse_rdata : (int, label) Hashtbl.t -> int -> rr_type -> Bitstring.bitstring ->
  [> `A of int32
   | `CNAME of string list
   | `HINFO of string * string
   | `MINFO of string list * string list
   | `MX of int * string list
   | `NS of string list
   | `PTR of string list
   | `SOA of string list * string list * int32 * int32 * int32 * int32 * int32
   | `TXT of 'a
   | `UNKNOWN of int * string
   | `WKS of int32 * byte * string ]
type rr_class = [ `CH | `CS | `HS | `IN ]
val int_of_rr_class : rr_class -> int
val rr_class_of_int : int -> rr_class
val string_of_rr_class : rr_class -> string
type rsrc_record = {
  rr_name : domain_name;
  rr_class : rr_class;
  rr_ttl : int32;
  rr_rdata : rr_rdata;
}
val rr_to_string : rsrc_record -> string
val parse_rr : (int, label) Hashtbl.t -> int -> Bitstring.bitstring -> rsrc_record * (string * int * int)
type q_type =
    [ `A
    | `A6
    | `AAAA
    | `AFSDB
    | `ANY
    | `APL
    | `ATMA
    | `AXFR
    | `CERT
    | `CNAME
    | `DLV
    | `DNAME
    | `DNSKEY
    | `DS
    | `EID
    | `GID
    | `GPOS
    | `HINFO
    | `IPSECKEY
    | `ISDN
    | `KEY
    | `KM
    | `LOC
    | `MAILA
    | `MAILB
    | `MB
    | `MD
    | `MF
    | `MG
    | `MINFO
    | `MR
    | `MX
    | `NAPTR
    | `NIMLOC
    | `NS
    | `NSAP
    | `NSAP_PTR
    | `NSEC
    | `NULL
    | `NXT
    | `OPT
    | `PTR
    | `PX
    | `RP
    | `RRSIG
    | `RT
    | `SIG
    | `SINK
    | `SOA
    | `SPF
    | `SRV
    | `SSHFP
    | `TA
    | `TXT
    | `UID
    | `UINFO
    | `UNSPEC
    | `Unknown of int * bytes
    | `WKS
    | `X25 ]
val int_of_q_type : q_type -> int
val q_type_of_int : int -> q_type
val string_of_q_type : q_type -> string
type q_class = [ `ANY | `CH | `CS | `HS | `IN | `NONE ]
val int_of_q_class : q_class -> int
val q_class_of_int : int -> q_class
val string_of_q_class : q_class -> string
type question = { q_name : domain_name; q_type : q_type; q_class : q_class; }
val question_to_string : question -> string
val parse_question : (int, label) Hashtbl.t -> int -> Bitstring.bitstring -> question * (string * int * int)
type qr = [ `Answer | `Query ]
val qr_of_bool : bool -> [> `Answer | `Query ]
val bool_of_qr : [< `Answer | `Query ] -> bool
type opcode = [ `Answer | `Notify | `Query | `Reserved | `Status | `Update ]
val opcode_of_int : int -> [> `Answer | `Notify | `Query | `Reserved | `Status | `Update ]
val int_of_opcode : [> `Answer | `Notify | `Query | `Reserved | `Status | `Update ] -> int
type rcode =
    [ `BadAlg
    | `BadKey
    | `BadMode
    | `BadName
    | `BadTime
    | `BadVers
    | `FormErr
    | `NXDomain
    | `NXRRSet
    | `NoError
    | `NotAuth
    | `NotImp
    | `NotZone
    | `Refused
    | `ServFail
    | `YXDomain
    | `YXRRSet ]
val rcode_of_int :
  int ->
  [> `BadAlg
   | `BadKey
   | `BadMode
   | `BadName
   | `BadTime
   | `BadVers
   | `FormErr
   | `NXDomain
   | `NXRRSet
   | `NoError
   | `NotAuth
   | `NotImp
   | `NotZone
   | `Refused
   | `ServFail
   | `YXDomain
   | `YXRRSet ]
val int_of_rcode :
  [> `BadAlg
   | `BadKey
   | `BadMode
   | `BadName
   | `BadTime
   | `BadVers
   | `FormErr
   | `NXDomain
   | `NXRRSet
   | `NoError
   | `NotAuth
   | `NotImp
   | `NotZone
   | `Refused
   | `ServFail
   | `YXDomain
   | `YXRRSet ] ->
  int
type detail = {
  qr : qr;
  opcode : opcode;
  aa : bool;
  tc : bool;
  rd : bool;
  ra : bool;
  rcode : rcode;
}
val detail_to_string : detail -> string
val parse_detail : string * int * int -> detail
val build_detail : detail -> Bitstring.bitstring
type dns = {
  id : int16;
  detail : Bitstring.t;
  questions : question list;
  answers : rsrc_record list;
  authorities : rsrc_record list;
  additionals : rsrc_record list;
}
val dns_to_string : dns -> string
val parse_dns : (int, label) Hashtbl.t -> Bitstring.bitstring -> dns
val marshal : dns -> Bitstring.bitstring
