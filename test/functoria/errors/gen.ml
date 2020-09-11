type t = { cmd : string; file : string; code : int }

let v code n = { code; cmd = n ^ " --vote=dog"; file = n }

let gen t =
  Printf.printf
    {|
(rule
  (target %s)
  (action
    (with-stdout-to %s
    (with-stderr-to %s.err
      (with-accepted-exit-codes %d (run ./test.exe %s))))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff %s.expected %s)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff %s.err.expected %s.err)))
|}
    t.file t.file t.file t.code t.cmd t.file t.file t.file t.file

let () =
  List.iter gen
    [
      v 1 "configure";
      v 1 "query";
      v 1 "describe";
      { code = 0; file = "help"; cmd = "help --man-format=plain" };
      v 0 "clean";
    ]
