open Mirage

let basic = foreign "Test.Basic" (console @-> stackv4 @-> job)

let stack console = generic_stackv4 console tap0

let () =
  register "basic_ethif" [
    basic $ default_console $ stack default_console
  ]
