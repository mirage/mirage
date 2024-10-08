let get_target i = Key.(get (Functoria.Info.context i) target)

let connect_err name number =
  let str =
    Fmt.str "The %s connect expects exactly %d argument%s" name number
      (if number = 1 then "" else "s")
  in
  failwith str

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty =
    try Unix.(isatty (descr_of_out_channel Stdlib.stdout))
    with Unix.Unix_error _ -> false
  in
  (not dumb) && isatty
