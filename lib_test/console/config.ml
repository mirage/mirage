open Mirari

let c = Driver.Console ()

let () =
  Job.register [
    "Handler.Main",  [c]
  ]
