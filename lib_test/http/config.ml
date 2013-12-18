open Mirage

let fs = Driver.crunch ~name:"static" "../kv_ro/t"

let http =
  Driver.HTTP {
    HTTP.port  = 8080;
    address    = None;
    ip         = IP.local Network.Tap0;
  }

let () =
  Job.register [
    "Handler.Main", [Driver.console; fs; http]
  ]
