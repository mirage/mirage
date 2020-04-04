type t = {
  cmd : string;
  file : string;
  target : [ `None | `X | `Y ];
  context : [ `X | `Y ];
}

let str = function `X -> "x" | `Y -> "y" | `None -> "no"

let file cmd target context =
  let cmd = String.map (function ' ' -> '-' | x -> x) cmd in
  cmd ^ "-" ^ str target ^ "-" ^ str context

let v cmd target context =
  let file = file cmd target context in
  let target_str = match target with `None -> "" | x -> " -t " ^ str x in
  let cmd = cmd ^ target_str ^ " --context-file=" ^ str context ^ ".context" in
  { cmd; file; target; context }

let gen t =
  let out = t.file ^ ".expected" in
  let err = t.file ^ ".err.expected" in
  List.iter
    (fun file ->
      if not (Sys.file_exists file) then
        Format.eprintf "touch test/functoria/context/%s\n" file)
    [ out; err ];

  Format.printf
    {|
(rule
 (deps x.context y.context)
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

let run =
  List.iter gen
    [
      v "query package" `None `X;
      v "query package" `None `Y;
      v "query package" `X `Y;
      v "query package" `Y `X;
      v "describe" `None `X;
      v "describe" `None `Y;
      v "describe" `Y `X;
      v "describe" `X `Y;
    ]
