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

module Ethernet = struct
    type mac = string (* length 6 only *)
  
    (* Raw MAC address off the wire (network endian) *)
    let mac_of_bytes x : mac =
        assert(String.length x = 6);
        x

    (* Read a MAC address colon-separated string *)
    let mac_of_string x : mac option = 
        try
          let s = String.create 6 in
          Scanf.sscanf x "%2x:%2x:%2x:%2x:%2x:%2x"
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

    let mac_to_string x =
        let chri i = Char.code x.[i] in
        Printf.sprintf "%2x:%2x:%2x:%2x:%2x:%2x"
           (chri 0) (chri 1) (chri 2) (chri 3) (chri 4) (chri 5)
end

module IPv4 = struct
   type addr = string (* length 4 only *)
  
   (* Raw IPv4 address of the wire (network endian) *)
   let addr_of_bytes x : addr = 
       assert(String.length x = 4);
       x

   (* Read an IPv4 address dot-separated string *)
   let addr_of_string x : addr option =
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

   (* Read an IPv4 address from a tuple *)
   let addr_of_tuple (a,b,c,d) : addr =
       let s = String.create 4 in
       s.[0] <- Char.chr a;
       s.[1] <- Char.chr b;
       s.[2] <- Char.chr c;
       s.[3] <- Char.chr d;
       s

   let addr_to_string x =
       let chri i = Char.code x.[i] in
       Printf.sprintf "%d.%d.%d.%d" 
         (chri 0) (chri 1) (chri 2) (chri 3)
end

