open Lwt

let num = ref 0

let main () =
   incr num;
   let s = (string_of_int !num) ^ "\n" in
   OS.Console.log_s s
