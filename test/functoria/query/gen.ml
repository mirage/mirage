type t = { cmd : string; file : string }

let v x = { cmd = "query " ^ x; file = x }

let gen t =
  Format.printf
    {|
(rule
 (action
  (with-stdout-to %s
  (with-stderr-to %s.err
   (run ./config.exe %s)))))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff %s.expected %s)))

(rule
 (alias runtest)
 (package functoria)
 (action
  (diff %s.err.expected %s.err)))
|}
    t.file t.file t.cmd t.file t.file t.file t.file

let () =
  List.iter gen
    [
      v "name";
      v "opam";
      v "packages";
      v "files";
      v "Makefile";
      { file = "Makefile.no-depext"; cmd = "query Makefile --no-depext" };
      { file = "Makefile.depext"; cmd = "query Makefile --depext" };
      { file = "version"; cmd = "query --version" };
      { file = "x-dune"; cmd = "query dune" };
      { file = "x-dune-base"; cmd = "query dune-base" };
      { file = "x-dune-project"; cmd = "query dune-project" };
      { file = "x-dune-workspace"; cmd = "query dune-workspace" };
    ]
