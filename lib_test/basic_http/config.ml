open Mirage

let basic = foreign "Test.Direct" (console @-> network @-> job)

let () =
  add_to_ocamlfind_libraries ["tcpip.stack-direct"; "mirage-http"];
  register "basic_direct_http" [
    basic $ default_console $ tap0;
  ]
