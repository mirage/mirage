(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
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

open Bitstring
let sp = Printf.sprintf

exception Unparsable of string * bitstring

let (|>) x f = f x (* pipe *)
let (>>) f g x = g (f x) (* functor pipe *)
let (||>) l f = List.map f l (* element-wise pipe *)

let (&&&) x y = Int32.logand x y
let (|||) x y = Int32.logor x y
let (^^^) x y = Int32.logxor x y
let (<<<) x y = Int32.shift_left x y
let (>>>) x y = Int32.shift_right_logical x y

let join c l = List.fold_left (fun x y -> y ^ c ^ x) "" l
let stop (x, bits) = x (* drop remainder to stop parsing and demuxing *) 

type domain_name = string
type int16 = int

type byte = char
let byte (i:int) : byte = Char.chr i
let int_of_byte b = int_of_char b
let int32_of_byte b = b |> int_of_char |> Int32.of_int

type bytes = string
let bytes_to_hex_string bs = 
  bs |> Array.map (fun b -> sp "%02x." (int_of_byte b))
let bytes_of_bitstring bits = string_of_bitstring bits
let ipv4_addr_of_bytes bs = 
  ((bs.[0] |> int32_of_byte <<< 24) ||| (bs.[1] |> int32_of_byte <<< 16) 
    ||| (bs.[2] |> int32_of_byte <<< 8) ||| (bs.[3] |> int32_of_byte))

type label = 
  | L of string * int (* string *)
  | P of int * int (* pointer *)
  | Z of int (* zero; terminator *)

let parse_charstr bits = 
  bitmatch bits with
    | { len: 8; str: (len*8): string; bits: -1: bitstring }
      -> str, bits

let bitstring_offset bits = 
  let (_, offset, _) = bits in offset

let parse_label base bits = 
  let cur = bitstring_offset bits in
  let offset = (cur-base)/8 in
  (bitmatch bits with
    | { length: 8: check(length != 0 && length < 64); 
        name: (length*8): string; data: -1: bitstring } 
      -> (L (name, offset), data)
    | { 0b0_11: 2; ptr: 14; bits: -1: bitstring } 
      -> (P (ptr, offset), bits)
    | { 0: 8; bits: -1: bitstring } 
      -> (Z offset, bits)
    | { _ } -> raise(Unparsable ("parse_label", bits))
  )

let parse_name names base bits = 
  (* what. a. mess. *)
  let rec aux offsets name bits = 
    match parse_label base bits with
      | (L (n, o) as label, data) 
        -> Hashtbl.add names o label;
          offsets |> List.iter (fun off -> (
            Hashtbl.add names off label
          ));
          aux (o :: offsets) (n :: name) data 
      | (P (p, _), data) 
        -> let ns = (Hashtbl.find_all names p 
                        |> List.filter (fun n ->
                          match n with L _ -> true | _ -> false)
                        |> List.rev)
           in
           offsets |> List.iter (fun off ->
             ns |> List.iter (fun n -> Hashtbl.add names off n)
           );
           ((ns |> List.rev
             ||> (fun n -> match n with 
                 | L (nm,_) -> nm
                 | _ -> raise(Unparsable ("parse_name", bits)))) 
            @ name), data
      | (Z o as zero, data)
        -> Hashtbl.add names o zero;
          (name, data)
  in 
  let name, bits = aux [] [] bits in
  (join "." name, bits)


type resource = [
| `Hostinfo  of string * string
| `Domain    of domain_name
| `Mailbox   of domain_name * domain_name
| `Exchange  of int * domain_name
| `Data      of bytes
| `Text      of string list
| `Authority of domain_name * domain_name * int32 * int32 * int32 * int32 * int32
| `Address   of int32
| `Services  of int32 * byte * bytes
]

let parse_resource names base t bits = 
  match t with
    | `HINFO -> let (cpu, bits) = parse_charstr bits in
                let os = bits |> parse_charstr |> stop in
                `Hostinfo (cpu, os)
    | `MB | `MD | `MF | `MG | `MR | `NS
    | `CNAME | `PTR -> `Domain (bits |> parse_name names base |> stop)
    | `MINFO -> let (rm, bits) = parse_name names base bits in
                let em = bits |> parse_name names base |> stop in
                `Mailbox (rm, em)
    | `MX -> (bitmatch bits with
        | { preference: 16; bits: -1: bitstring } 
          -> `Exchange (preference, bits |> parse_name names base |> stop)
    )
    | `NULL -> `Data (string_of_bitstring bits)    
    | `TXT -> let names, _ = 
                let rec aux ns bits = 
                  let n, bits = parse_name names base bits in
                  aux (n :: ns) bits
                in
                aux [] bits
              in
              `Text names
    | `SOA -> let mn, bits = parse_name names base bits in
              let rn, bits = parse_name names base bits in 
              (bitmatch bits with
                | { serial: 32; refresh: 32; retry: 32; expire: 32;
                    minimum: 32 }
                  -> `Authority (mn, rn, 
                                 serial, refresh, retry, expire, minimum)
              )
    | `A -> `Address (bits |> bytes_of_bitstring |> ipv4_addr_of_bytes)
    | `WKS -> (bitmatch bits with
        | { addr: 32; proto: 8; bitmap: -1: string } 
          -> `Services (addr, proto |> byte, bitmap)
    )

type rr_type = [
| `A | `NS | `MD | `MF | `CNAME | `SOA | `MB | `MG
| `MR | `NULL | `WKS | `PTR | `HINFO | `MINFO | `MX | `TXT
]

let int_of_rr_type : rr_type -> int = function
  | `A     ->  1
  | `NS    ->  2
  | `MD    ->  3
  | `MF    ->  4
  | `CNAME ->  5
  | `SOA   ->  6
  | `MB    ->  7
  | `MG    ->  8
  | `MR    ->  9
  | `NULL  -> 10
  | `WKS   -> 11
  | `PTR   -> 12
  | `HINFO -> 13
  | `MINFO -> 14
  | `MX    -> 15
  | `TXT   -> 16
and rr_type_of_int : int -> rr_type = function
  |  1     -> `A
  |  2     -> `NS
  |  3     -> `MD
  |  4     -> `MF
  |  5     -> `CNAME
  |  6     -> `SOA
  |  7     -> `MB
  |  8     -> `MG
  |  9     -> `MR
  | 10     -> `NULL
  | 11     -> `WKS
  | 12     -> `PTR
  | 13     -> `HINFO
  | 14     -> `MINFO
  | 15     -> `MX
  | 16     -> `TXT
  | _      -> invalid_arg "rr_type_of_int"
and string_of_rr_type:rr_type -> string = function
  | `A     ->  "A"
  | `NS    ->  "NS"
  | `MD    ->  "MD"
  | `MF    ->  "MF"
  | `CNAME ->  "CNAME"
  | `SOA   ->  "SOA"
  | `MB    ->  "MB"
  | `MG    ->  "MG"
  | `MR    ->  "MR"
  | `NULL  -> "NULL"
  | `WKS   -> "WKS"
  | `PTR   -> "PTR"
  | `HINFO -> "HINFO"
  | `MINFO -> "MINFO"
  | `MX    -> "MX"
  | `TXT   -> "TXT"

type rr_class = [ `IN | `CS | `CH | `HS ]

let int_of_rr_class : rr_class -> int = function
  | `IN -> 1
  | `CS -> 2
  | `CH -> 3
  | `HS -> 4
and rr_class_of_int : int -> rr_class = function
  | 1   -> `IN
  | 2   -> `CS
  | 3   -> `CH
  | 4   -> `HS
  | _   -> invalid_arg "rr_class_of_int"
and string_of_rr_class : rr_class -> string = function
  | `IN -> "IN"
  | `CS -> "CS"
  | `CH -> "CH"
  | `HS -> "HS"

type rsrc_record = {
  rr_name  : domain_name;
  rr_type  : rr_type;
  rr_class : rr_class;
  rr_ttl   : int32;
  rr_rdata : resource;
}

let parse_rr names base bits =
  let name, bits = parse_name names base bits in
  bitmatch bits with
    | { t: 16; c: 16; ttl: 32; 
        rdlen: 16; rdata: (rdlen*8): bitstring;
        data: -1: bitstring } 
      -> { rr_name = name;
           rr_type = rr_type_of_int t;
           rr_class = rr_class_of_int c;
           rr_ttl = ttl;
           rr_rdata = parse_resource names base (rr_type_of_int t) rdata;
         }, data
    | { _ } -> raise (Unparsable ("parse_rr", bits))

type q_type = [ rr_type | `AXFR | `MAILB | `MAILA | `ANY ]
let int_of_q_type : q_type -> int = function
  | `AXFR         -> 252
  | `MAILB        -> 253
  | `MAILA        -> 254
  | `ANY          -> 255
  | #rr_type as t -> int_of_rr_type t
and q_type_of_int : int -> q_type = function
  | 252           -> `AXFR
  | 253           -> `MAILB
  | 254           -> `MAILA
  | 255           -> `ANY
  | n             -> (rr_type_of_int n :> q_type)
and string_of_q_type:q_type -> string = function
  | `AXFR         -> "AXFR"
  | `MAILB        -> "MAILB"
  | `MAILA        -> "MAILA"
  | `ANY          -> "ANY"
  | #rr_type as t -> string_of_rr_type t

type q_class = [ rr_class | `ANY ]

let int_of_q_class : q_class -> int = function
  | `ANY           -> 255
  | #rr_class as c -> int_of_rr_class c
and q_class_of_int : int -> q_class = function
  | 255            -> `ANY
  | n              -> (rr_class_of_int n :> q_class)
and string_of_q_class : q_class -> string = function
  | `ANY           -> "ANY"
  | #rr_class as c -> string_of_rr_class c

type question = {
  q_name  : domain_name;
  q_type  : q_type;
  q_class : q_class;
}

let parse_question names base bits = 
  let n, bits = parse_name names base bits in
  bitmatch bits with
    | { t: 16; c: 16; data: -1: bitstring }
      -> { q_name = n;
           q_type = q_type_of_int t;
           q_class = q_class_of_int c;
         }, data
    | { _ } -> raise (Unparsable ("parse_question", bits))

type qr = [ | `Query | `Answer ]
let qr_of_bool = function
  | false -> `Query
  | true -> `Answer
let bool_of_qr = function
  | `Query -> false
  | `Answer -> true

type opcode = [ qr | `Status | `Reserved | `Notify | `Update ]
let opcode_of_int = function
  | 0 -> `Query
  | 1 -> `Answer
  | 2 -> `Status
  | 3 -> `Reserved
  | 4 -> `Notify
  | 5 -> `Update
  | _ -> failwith "dnspacket: unknown opcode"
let int_of_opcode = function
  | `Query -> 0
  | `Answer -> 1
  | `Status -> 2
  | `Reserved -> 3
  | `Notify -> 4
  | `Update -> 5
  | _ -> failwith "dnspacket: unknown opcode"

type rcode = 
| NoError  | FormErr
| ServFail | NXDomain | NotImp  | Refused
| YXDomain | YXRRSet  | NXRRSet | NotAuth
| NotZone  | BadVers  | BadKey  | BadTime
| BadMode  | BadName  | BadAlg 
let rcode_of_int = function
  | 0 -> NoError
  | 1 -> FormErr
  | 2 -> ServFail
  | 3 -> NXDomain
  | 4 -> NotImp
  | 5 -> Refused
  | 6 -> YXDomain
  | 7 -> YXRRSet
  | 8 -> NXRRSet
  | 9 -> NotAuth
  | 10 -> NotZone
  
  | 16-> BadVers
  | 17-> BadKey
  | 18-> BadTime
  | 19-> BadMode
  | 20-> BadName
  | 21-> BadAlg
  | _ -> failwith "dnspacket: unknown rcode"
let int_of_rcode = function
  | NoError -> 0
  | FormErr -> 1
  | ServFail -> 2
  | NXDomain -> 3
  | NotImp -> 4
  | Refused -> 5
  | YXDomain -> 6
  | YXRRSet -> 7
  | NXRRSet -> 8
  | NotAuth -> 9
  | NotZone -> 10
  
  | BadVers -> 16
  | BadKey -> 17
  | BadTime -> 18
  | BadMode -> 19
  | BadName -> 20
  | BadAlg -> 21
  | _ -> failwith "dnspacket: unknown rcode"

type detail = {
  qr: qr;
  opcode: opcode;
  aa: bool; 
  tc: bool; 
  rd: bool; 
  ra: bool;
  rcode: rcode;
}

let parse_detail bits = 
  bitmatch bits with
    | { qr:1; opcode:4; aa:1; tc:1; rd:1; ra:1; z:3; rcode:4 } 
      -> { qr=qr_of_bool qr; opcode=opcode_of_int opcode; 
           aa; tc; rd; ra; 
           rcode=rcode_of_int rcode }

let build_detail d = 
  (BITSTRING {
    (bool_of_qr d.qr):1; (int_of_opcode d.opcode):4; 
    d.aa:1; d.tc:1; d.rd:1; d.ra:1; (* z *) 0:3;
    (int_of_rcode d.rcode):4
  })
    
type dns = {
  id          : int16;
  detail      : Bitstring.t;
  questions   : question list;
  answers     : rsrc_record list;
  authorities : rsrc_record list;
  additionals : rsrc_record list;
}

let parse_dns names bits = 
  let parsen pf ns b n bits = 
    let rec aux rs n bits = 
      match n with
        | 0 -> rs, bits
        | _ -> let r, bits = pf ns b bits in 
               aux (r :: rs) (n-1) bits
    in
    aux [] n bits
  in
  let base = bitstring_offset bits in
  bitmatch bits with
    | { id: 16; detail: 16: bitstring;
        qdcount: 16; ancount: 16; nscount: 16; arcount: 16;
        bits: -1: bitstring
      }
      -> let questions, bits = parsen parse_question names base qdcount bits in
         let answers, bits = parsen parse_rr names base ancount bits in
         let authorities, bits = parsen parse_rr names base nscount bits in
         let additionals, bits = parsen parse_rr names base arcount bits in
         { id; detail; questions; answers; authorities; additionals }

    | { _ } -> raise (Unparsable ("parse_dns", bits))

let build_dns id detail questions answers authorities additionals = 
  let qdcount = List.length questions in
  let ancount = List.length answers in
  let nscount = List.length authorities in
  let arcount = List.length additionals in
  let h = 
    (BITSTRING {
      id: 16; detail: 16;
      qdcount: 16; ancount: 16; nscount: 16; arcount: 16
    }) 
  in
  h :: questions @ answers @ authorities @ additionals
