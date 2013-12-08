open Mirage

let c = Driver.Console ()

let () =
  Job.register [
    "Handler.Main",  [c]
  ]
