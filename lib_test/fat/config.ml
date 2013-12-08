open Mirage

let block = {
  Block.name = "myfile";
  filename   = "../kv_ro/t/a";
  read_only  = true;
}

let fat = Driver.Fat {
    Fat.name = "fat";
    block;
  }

let () = Job.register [
    "Handler.Main", [Driver.console; fat]
  ]
