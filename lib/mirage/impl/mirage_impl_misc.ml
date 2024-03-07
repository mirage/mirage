open Functoria

let get_target i = Mirage_key.(get (Info.context i) target)

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

let pop_and_check_empty ~err x rest =
  let result, rest = pop ~err x rest in
  match rest with [] -> result | _ -> fst (err ())

let pp_opt name ppf = function
  | None -> ()
  | Some key -> Fmt.pf ppf "@ ?%s:%s" name key

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
