type t = {
  cmd : string;
  file : string;
  args : string option;
  target : [ `Unix | `Hvt ];
}

let target_str = function `Unix -> "unix" | `Hvt -> "hvt"

let v ?args x target = { cmd = "query " ^ x; file = x; target; args }

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
  let cmd = match t.args with None -> cmd | Some a -> cmd ^ " " ^ a in
  Format.printf
    {|
(rule
 (action
  (with-stdout-to %s
  (with-stderr-to %s.err
   (setenv MIRAGE_DEFAULT_TARGET unix
   (run ./config.exe %s))))))

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
      v "files" target;
      v "Makefile" target;
      {
        file = "Makefile.no-depext";
        cmd = "query Makefile --no-depext";
        args = None;
        target;
      };
      {
        file = "Makefile.depext";
        cmd = "query Makefile --depext";
        target;
        args = None;
      };
      { file = "x-dune"; cmd = "query dune --dry-run"; target; args = None };
      { file = "x-dune-base"; cmd = "query dune-base"; target; args = None };
      {
        file = "x-dune-project";
        cmd = "query dune-project";
        target;
        args = None;
      };
      {
        file = "x-dune-workspace";
        cmd = "query dune-workspace --dry-run";
        target;
        args = None;
      };
    ]

let () = List.iter of_target [ `Unix; `Hvt ]
