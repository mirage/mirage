type t = { cmd : string; file : string }

let v x = { cmd = "query " ^ x; file = x }

let gen t =
  Format.printf
    {|
(rule
 (target %s)
 (action
  (with-stdout-to
   %%{target}
   (run ./config.exe %s))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff %s.expected %s)))
|}
    t.file t.cmd t.file t.file

let () =
  List.iter gen
    [
      v "name";
      v "opam";
      v "packages";
      v "install";
      v "files-configure";
      v "files-build";
      v "Makefile";
      { file = "Makefile.depext"; cmd = "query Makefile --depext" };
      { file = "help-query"; cmd = "help query --man-format=plain" };
      { file = "query-help"; cmd = "query --help=plain" };
      { file = "version"; cmd = "query --version" };
    ]
