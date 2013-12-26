open Mirage

let sender   = foreign "Test.Sender"   (console @-> network @-> job)
let receiver = foreign "Test.Receiver" (console @-> network @-> job)

let () =
  register "net" [
    sender   $ default_console $ tap0;
    receiver $ default_console $ tap0;
  ]
