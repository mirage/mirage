let context_singleton key value =
  let info = Cmdliner.Term.info "" in
  let term =
    Functoria_key.context
      ~with_required:false
      (Functoria_key.Set.singleton @@ Mirage_key.abstract key)
  in
  let argv = [|"program"; "--target"; value|] in
  match Cmdliner.Term.eval ~argv (term, info) with
  | `Ok x -> x
  | _ -> assert false

let print_banner s =
  print_endline s;
  print_endline @@ String.make (String.length s) '=';
  print_newline ()

let test target =
  print_banner target;
  let context =
    context_singleton
    Mirage_key.target
    target
  in
  Mirage_job.dry_run_trace ~files:[] @@
  Mirage.configure @@
  Functoria.Info.create
    ~packages:[]
    ~keys:[]
    ~context
    ~name:"NAME"
    ~build_dir:(Fpath.v "BUILD_DIR");
  print_newline ()

let () =
  List.iter
    test
    [ "unix"
    ; "xen"
    ; "virtio"
    ]
  
