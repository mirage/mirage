type t = { cmd : string; file : string }

let v x = { cmd = x; file = x }

let gen t =
  Format.printf
    {|
(rule
 (target %s)
 (action
  (with-stdout-to
   %%{target}
   (run ./config.exe query %s))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff %s.expected %s)))
|}
    t.cmd t.file t.file t.file

let () =
  List.iter gen
    [
      v "name";
      v "opam";
      v "packages";
      v "install";
      v "files-configure";
      v "files-build";
    ]
