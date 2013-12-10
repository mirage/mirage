open Mirage

let ip = Driver.local_ip Network.Tap0

let () =
  Job.register [
    "Ping.Main", [Driver.console; ip]
  ]
