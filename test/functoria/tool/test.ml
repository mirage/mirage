let () =
  let argv = Array.append Sys.argv [| "--dry-run" |] in
  F0.Tool.run_with_argv argv
