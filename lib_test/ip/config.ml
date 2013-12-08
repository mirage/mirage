open Mirage

let () =
  Driver.register [
    Driver.clock;
    Driver.local_ip Network.Tap0;
  ]
