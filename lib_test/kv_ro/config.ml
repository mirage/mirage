open Mirage

let x = Driver.crunch ~name:"x" "t"
let y = Driver.crunch ~name:"y" "t"

let () =
  Job.register [
    "Handler.Main",  [Driver.console; x; y]
  ]
