open Mirage

let () =
  Job.register [
    "Test.Sender",   [Driver.console; Driver.tap0];
    "Test.Receiver", [Driver.console; Driver.tap0];
  ]
