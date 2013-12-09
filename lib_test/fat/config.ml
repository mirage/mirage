open Mirage

let block = {
  Block.name = "myfile";
  filename   = "fat.img";
  read_only  = true;
}

let fat = Driver.Fat {
    Fat.name = "fat";
    block;
  }

let () = Job.register [
    "Handler.Main", [Driver.console; fat]
  ]
