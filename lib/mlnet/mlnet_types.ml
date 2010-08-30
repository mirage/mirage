(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

type bytes = string (* to differentiate from pretty-printed strings *)
type ethernet_mac = string (* length 6 only *)

(* Raw MAC address off the wire (network endian) *)
let ethernet_mac_of_bytes x =
    assert(String.length x = 6);
    x

(* Read a MAC address colon-separated string *)
let ethernet_mac_of_string x = 
    try
      let s = String.create 6 in
      Scanf.sscanf x "%02x:%02x:%02x:%02x:%02x:%02x"
       (fun a b c d e f ->
         s.[0] <- Char.chr a;
         s.[1] <- Char.chr b;
         s.[2] <- Char.chr c;
         s.[3] <- Char.chr d;
         s.[4] <- Char.chr e;
         s.[5] <- Char.chr f;
       );
       Some s
    with _ -> None

let ethernet_mac_to_string x =
    let chri i = Char.code x.[i] in
    Printf.sprintf "%2x:%2x:%2x:%2x:%2x:%2x"
       (chri 0) (chri 1) (chri 2) (chri 3) (chri 4) (chri 5)

let ethernet_mac_to_bytes x = x 

let ethernet_mac_broadcast = String.make 6 '\255'

type ipv4_addr = string (* length 4 only *)

(* Raw IPv4 address of the wire (network endian) *)
let ipv4_addr_of_bytes x = 
    assert(String.length x = 4);
    x

(* Identity function to convert ipv4_addr back to bytes *)
let ipv4_addr_to_bytes x = x

(* Read an IPv4 address dot-separated string *)
let ipv4_addr_of_string x =
    try
        let s = String.create 4 in
        Scanf.sscanf x "%d.%d.%d.%d"
          (fun a b c d ->
              s.[0] <- Char.chr a;
              s.[1] <- Char.chr b;
              s.[2] <- Char.chr c;
              s.[3] <- Char.chr d;
          );
        Some s
    with _ -> None

(* Blank 0.0.0.0 IPv4 address *)
let ipv4_blank = String.make 4 '\000'
(* Broadcast 255.255.255.255 IPv4 address *)
let ipv4_broadcast = String.make 4 '\255'

let ipv4_addr_of_uint32 s =
    let (>!) x y = Char.chr (Int32.to_int (Int32.logand (Int32.shift_right x y) 255l)) in
    let x = String.create 4 in
    x.[0] <- (s >! 24);
    x.[1] <- (s >! 16); 
    x.[2] <- (s >! 8); 
    x.[3] <- (s >! 0);
    x

let ipv4_addr_to_uint32 a =
    let s x y = Int32.shift_left (Int32.of_int (Char.code a.[x])) (y*8) in
    let (++) = Int32.add in
    (s 0 3) ++ (s 1 2) ++ (s 2 1) ++ (s 3 0)

(* Read an IPv4 address from a tuple *)
let ipv4_addr_of_tuple (a,b,c,d) =
    let s = String.create 4 in
    s.[0] <- Char.chr a;
    s.[1] <- Char.chr b;
    s.[2] <- Char.chr c;
    s.[3] <- Char.chr d;
    s

let ipv4_addr_to_string x =
    let chri i = Char.code x.[i] in
    Printf.sprintf "%d.%d.%d.%d" 
      (chri 0) (chri 1) (chri 2) (chri 3)
