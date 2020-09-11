open Functoria
open Astring
open Action.Infix

let src = Logs.Src.create "mirage" ~doc:"mirage cli tool"

module Log = (val Logs.src_log src : Logs.LOG)

let get_target i = Mirage_key.(get (Functoria.Info.context i) target)

(* Mirage implementation backing the target. *)
let backend_predicate = function
  | #Mirage_key.mode_xen -> "mirage_xen"
  | #Mirage_key.mode_solo5 -> "mirage_solo5"
  | #Mirage_key.mode_unix -> "mirage_unix"

let connect_err name number =
  Fmt.strf "The %s connect expects exactly %d argument%s" name number
    (if number = 1 then "" else "s")

let pp_key fmt k = Mirage_key.serialize_call fmt (Mirage_key.v k)

let query_ocamlfind ?(recursive = false) ?(format = "%p") ?predicates libs =
  let open Bos in
  let flag = if recursive then Cmd.v "-recursive" else Cmd.empty
  and format = Cmd.of_list [ "-format"; format ]
  and predicate =
    match predicates with None -> [] | Some x -> [ "-predicates"; x ]
  and q = "query" in
  let cmd =
    Cmd.(
      v "ocamlfind" % q %% flag %% format %% of_list predicate %% of_list libs)
  in
  Action.run_cmd_out cmd >|= fun out -> String.cuts ~sep:"\n" ~empty:false out

let opam_prefix =
  let cmd = Bos.Cmd.(v "opam" % "config" % "var" % "prefix") in
  lazy (Action.run_cmd_out cmd)

(* Implement something similar to the @name/file extended names of findlib. *)
let rec expand_name ~lib param =
  match String.cut param ~sep:"@" with
  | None -> param
  | Some (prefix, name) -> (
      match String.cut name ~sep:"/" with
      | None -> prefix ^ Fpath.(to_string (v lib / name))
      | Some (name, rest) ->
          let rest = expand_name ~lib rest in
          prefix ^ Fpath.(to_string (v lib / name / rest)) )

(* Get the linker flags for any extra C objects we depend on.
 * This is needed when building a Xen/Solo5 image as we do the link manually. *)
let extra_c_artifacts target pkgs =
  Lazy.force opam_prefix >>= fun prefix ->
  let lib = prefix ^ "/lib" in
  let format = Fmt.strf "%%d\t%%(%s_linkopts)" target
  and predicates = "native" in
  query_ocamlfind ~recursive:true ~format ~predicates pkgs >>= fun data ->
  let r =
    List.fold_left
      (fun acc line ->
        match String.cut line ~sep:"\t" with
        | None -> acc
        | Some (dir, ldflags) ->
            if ldflags <> "" then
              let ldflags = String.cuts ldflags ~sep:" " in
              let ldflags = List.map (expand_name ~lib) ldflags in
              acc @ (("-L" ^ dir) :: ldflags)
            else acc)
      [] data
  in
  Action.ok r

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty =
    try Unix.(isatty (descr_of_out_channel Stdlib.stdout))
    with Unix.Unix_error _ -> false
  in
  (not dumb) && isatty
