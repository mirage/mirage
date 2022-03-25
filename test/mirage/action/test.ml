open Mirage

let context_singleton key value =
  let info = Cmdliner.Cmd.info "" in
  let term =
    Key.context ~with_required:false (Key.Set.singleton @@ Key.v key)
  in
  let argv = [| "mirage"; "--target"; value |] in
  match Cmdliner.Cmd.eval_value ~argv (Cmdliner.Cmd.v info term) with
  | Ok (`Ok x) -> x
  | _ -> assert false

let print_banner s =
  print_endline s;
  print_endline @@ String.make (String.length s) '=';
  print_newline ()

let info context =
  Info.v ~packages:[] ~keys:[] ~build_cmd:[ "mirage build" ] ~context ~src:`None
    "NAME"

let test target =
  print_banner target;
  let context = context_singleton Key.target target in
  let env = Action.env ~files:(`Files []) () in
  Action.dry_run_trace ~env @@ Project.configure @@ info context;
  print_newline ()

let () = List.iter test [ "unix"; "hvt" ]
