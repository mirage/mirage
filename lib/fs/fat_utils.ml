(* These functions should probably be pushed into a (or rewritten in terms of) a stdlib *)

open Printf

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

