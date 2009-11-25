let main arg =
  Printf.printf "Hello, world!\n%!."

let _ = Callback.register "main" main
