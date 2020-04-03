type t = { cmd : string; file : string; target : [ `Unix | `Hvt ] }

let target_str = function `Unix -> "unix" | `Hvt -> "hvt"

let v x target = { cmd = "query " ^ x; file = x; target }

let gen t =
  let file =
    match t.target with
    | `Unix -> t.file
    | x -> Format.sprintf "%s-%s" t.file (target_str x)
  in
  let cmd =
    match t.target with
    | `Unix -> t.cmd
    | x -> Format.sprintf "%s --target=%s" t.cmd (target_str x)
  in
  Format.printf
    {|
(rule
 (action
  (with-stdout-to %s
  (with-stderr-to %s.err
   (run ./config.exe %s)))))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff %s.expected %s)))

(rule
 (alias runtest)
 (package mirage)
 (action
  (diff %s.err.expected %s.err)))
|}
    file file cmd file file file file

let of_target target =
  List.iter gen
    [
      v "name" target;
      v "opam" target;
      v "packages" target;
      v "files-configure" target;
      v "files-build" target;
      v "Makefile" target;
      {
        file = "Makefile.no-depext";
        cmd = "query Makefile --no-depext";
        target;
      };
      { file = "Makefile.depext"; cmd = "query Makefile --depext"; target };
      { file = "version"; cmd = "query --version"; target };
    ]

let () = List.iter of_target [ `Unix; `Hvt ]
