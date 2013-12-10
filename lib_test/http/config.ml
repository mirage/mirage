open Mirage

let fs =
  Driver.KV_RO {
    KV_RO.name = "static";
    dirname    = "../kv_ro/t";
  }

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
