open Mirage

let fs = {
  KV_RO.name = "static";
  dirname    = "../kv_ro/t";
}

let ip =
  Driver.local_ip Network.Tap0 true

let http = Driver.HTTP {
  HTTP.port  = 8080;
  address    = None;
  fs         = Some fs;
}

let () =
  Job.register [
    "Callback.Main", [Driver.console; ip; http]
  ]
