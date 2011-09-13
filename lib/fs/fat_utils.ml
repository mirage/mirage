(* These functions should probably be pushed into a (or rewritten in terms of) a stdlib *)

open Printf

(** [bitstring_is_byte_aligned b] true if the data within [b] is byte aligned *)
let bitstring_is_byte_aligned (_, off, len) = off mod 8 = 0 && (len mod 8 = 0)

(** [bitstring_write src offset dest] modifies the bitstring [dest] by writing
    [src] at [offset] in [dest] *)
let bitstring_write ((src_s, src_off, src_len) as src) offset_bytes ((dest_s, dest_off, dest_len) as dest) =
  (* We don't expect to run off the end of the target bitstring *)
  assert (dest_len - offset_bytes * 8 - src_len >= 0);
  assert (bitstring_is_byte_aligned src);
  assert (bitstring_is_byte_aligned dest);
  String.blit src_s (src_off / 8) dest_s (dest_off / 8 + offset_bytes) (src_len / 8)

(** [bitstring_chop n b] splits [b] into a list of bitstrings, all but possibly
    the last of size [n] *)
let bitstring_chop n bits =
  let module B = Bitstring in
  let rec inner acc bits =
    if B.bitstring_length bits <= n then bits :: acc
    else inner (B.takebits n bits :: acc) (B.dropbits n bits) in
  List.rev (inner [] bits)

(** [bitstring_clip s offset length] returns the sub-bitstring which exists
    between [offset] and [length] *)
let bitstring_clip (s_s, s_off, s_len) offset length =
  let s_end = s_off + s_len in
  let the_end = offset + length in
  let offset' = max s_off offset in
  let end' = min s_end the_end in
  let length' = max 0 (end' - offset') in
  s_s, offset', length'


module Stringext = struct
open String

let of_char c = String.make 1 c

let fold_right f string accu =
        let accu = ref accu in
        for i = length string - 1 downto 0 do
                accu := f string.[i] !accu
        done;
        !accu

let explode string =
        fold_right (fun h t -> h :: t) string []

let implode list =
        concat "" (List.map of_char list)

(** True if string 'x' ends with suffix 'suffix' *)
let endswith suffix x =
        let x_l = String.length x and suffix_l = String.length suffix in
        suffix_l <= x_l && String.sub x (x_l - suffix_l) suffix_l = suffix

(** True if string 'x' starts with prefix 'prefix' *)
let startswith prefix x =
        let x_l = String.length x and prefix_l = String.length prefix in
        prefix_l <= x_l && String.sub x 0 prefix_l  = prefix

(** Returns true for whitespace characters, false otherwise *)
let isspace = function
        | ' ' | '\n' | '\r' | '\t' -> true
        | _ -> false

(** Removes all the characters from the ends of a string for which the predicate is true *)
let strip predicate string =
        let rec remove = function
        | [] -> []
        | c :: cs -> if predicate c then remove cs else c :: cs in
        implode (List.rev (remove (List.rev (remove (explode string)))))

let rec split ?limit:(limit=(-1)) c s =
        let i = try String.index s c with Not_found -> -1 in
        let nlimit = if limit = -1 || limit = 0 then limit else limit - 1 in
        if i = -1 || nlimit = 0 then
                [ s ]
        else
                let a = String.sub s 0 i
                and b = String.sub s (i + 1) (String.length s - i - 1) in
                a :: (split ~limit: nlimit c b)

end

