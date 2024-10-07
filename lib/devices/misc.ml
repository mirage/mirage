let get_target i = Key.(get (Functoria.Info.context i) target)

let connect_err name ?max number =
  let str =
    match max with
    | None ->
        Fmt.str "The %s connect expects exactly %d argument%s" name number
          (if number = 1 then "" else "s")
    | Some n ->
        Fmt.str "The %s connect expects between %d and %d arguments" name number
          n
  in
  failwith str

let pop ~err x rest =
  match (rest, x) with
  | h :: t, Some _ -> (Some h, t)
  | _, None -> (None, rest)
  | _ -> err ()

let pp_label name ppf = function
  | None -> ()
  | Some key -> Fmt.pf ppf "@ ~%s:%s" name key

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty =
    try Unix.(isatty (descr_of_out_channel Stdlib.stdout))
    with Unix.Unix_error _ -> false
  in
  (not dumb) && isatty
