open Lwt
open OS

let num = ref 0
let cons = Console.t

let rec main () =
   incr num;
   let s = (string_of_int !num) ^ "\n" in
   OS.Console.log_s s >>
   main ()

let _ = OS.Main.run (main ())
