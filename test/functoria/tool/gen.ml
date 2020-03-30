type t = { args : string; file : string }

let v file args = { args; file }

let cmd s = v s (s ^ " a b c")

let gen t =
  Printf.printf
    {|
(rule
  (target %s)
  (action
    (with-stdout-to %s
    (with-stderr-to %s.err
      (run ./test.exe %s)))))

(rule
  (alias runtest)
  (package functoria)
  (action (diff %s.expected %s)))

(rule
  (alias runtest)
  (package functoria)
  (action (diff %s.err.expected %s.err)))
|}
    t.file t.file t.file t.args t.file t.file t.file t.file

let () =
  List.iter gen
    [
      cmd "configure";
      cmd "build";
      cmd "clean";
      cmd "query";
      cmd "describe";
      cmd "help";
      v "simple-help" "help";
      v "help-configure" "help configure";
      v "configure-help" "configure help";
      v "help-no-config" "help --file=empty/config.ml --man-format=plain";
      v "help-no-config-err" "help --file=empty/config.ml a b c";
      v "build-help-no-config" "build --help=plain --file=empty/config.ml a b c";
      v "version" "configure --version a b c";
      v "ambiguous" "c a b c";
      v "default" "";
    ]
