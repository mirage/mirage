open Functoria

let get_target i = Mirage_key.(get (Info.context i) target)

let connect_err name number =
  Fmt.str "The %s connect expects exactly %d argument%s" name number
    (if number = 1 then "" else "s")

let pp_key fmt k = Runtime_arg.call fmt k

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty =
    try Unix.(isatty (descr_of_out_channel Stdlib.stdout))
    with Unix.Unix_error _ -> false
  in
  (not dumb) && isatty
