module OS = Browser

let _ =
  let x = "foo bar" in
  OS.Console.(write t x 0 (String.length x))
