open Functoria

let get_target i = Mirage_key.(get (Info.context i) target)

let connect_err name number =
  Fmt.failwith "The %s connect expects exactly %d argument%s" name number
    (if number = 1 then "" else "s")

let pp_key fmt k = Runtime_arg.call fmt k

let pp_opt name ppf = function
  | None -> ()
  | Some key -> Fmt.pf ppf "@ ?%s:%a" name pp_key key

let pp_label name ppf = function
  | None -> ()
  | Some key -> Fmt.pf ppf "@ ~%s:%a" name pp_key key

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty =
    try Unix.(isatty (descr_of_out_channel Stdlib.stdout))
    with Unix.Unix_error _ -> false
  in
  (not dumb) && isatty

module K = struct
  type t = [] | ( :: ) : 'a Runtime_arg.arg option * t -> t
end

let runtime_args_opt l =
  let rec aux acc = function
    | K.[] -> List.rev acc
    | K.(None :: t) -> aux acc t
    | K.(Some h :: t) -> aux (Runtime_arg.v h :: acc) t
  in
  aux [] l
