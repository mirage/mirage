open Mirage

let basic = foreign "Test.Direct" (console @-> network @-> job)
let sock  = foreign "Test.Socket" (console @-> job)

let () =
  add_to_ocamlfind_libraries ["tcpip.stack-unix"];
  register "basic_stackv4" [
    basic $ default_console $ tap0;
    sock $ default_console
  ]
