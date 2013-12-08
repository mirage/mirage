open Mirage

let () =
  Job.register [
    "Handler.Main", [Driver.console]
  ]
