

type regexp;;
val uniq_tag : regexp -> int;;

val empty : regexp;;
val epsilon : regexp;;
val char : char -> regexp;;
val char_interv : char -> char -> regexp;;
val string : string -> regexp;;
val star : regexp -> regexp;;
val alt : regexp -> regexp -> regexp;;
val seq : regexp -> regexp -> regexp;;
val opt : regexp -> regexp;;
val some : regexp -> regexp;;


val nullable : regexp -> bool;;
val residual : regexp -> int -> regexp ;;
val firstchars : regexp -> (int * int * regexp) list ;;


val match_string : regexp -> string -> bool;;


val fprint : Format.formatter -> regexp -> unit;;
val print : regexp -> unit;;
