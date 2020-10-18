open Rresult
open Astring

let src = Logs.Src.create "mirage" ~doc:"mirage cli tool"
module Log = (val Logs.src_log src : Logs.LOG)

let get_target i = Mirage_key.(get (Functoria.Info.context i) target)

let connect_err name number =
  Fmt.strf "The %s connect expects exactly %d argument%s"
    name number (if number = 1 then "" else "s")

let with_output ?mode f k err =
  match Bos.OS.File.with_oc ?mode f k () with
  | Ok b -> b
  | Error _ -> Rresult.R.error_msg ("couldn't open output channel for " ^ err)

let pp_key fmt k = Mirage_key.serialize_call fmt (Mirage_key.abstract k)

let query_ocamlfind ?(recursive = false) ?(format="%p") ?predicates libs =
  let open Bos in
  let flag = if recursive then (Cmd.v "-recursive") else Cmd.empty
  and format = Cmd.of_list [ "-format" ; format ]
  and predicate = match predicates with
    | None -> []
    | Some x -> [ "-predicates" ; x ]
  and q = "query"
  in
  let cmd =
    Cmd.(v "ocamlfind" % q %% flag %% format %% of_list predicate %% of_list libs)
  in
  let open Rresult in
  OS.Cmd.run_out cmd |> OS.Cmd.out_lines >>| fst

let opam_prefix =
  let cmd = Bos.Cmd.(v "opam" % "config" % "var" % "prefix") in
  lazy (match Sys.getenv_opt "PREFIX" with
      | Some x -> Ok x
      | None -> Bos.OS.Cmd.(run_out cmd |> out_string |> success))

(* Invoke pkg-config and return output if successful. *)
let pkg_config pkgs args =
  let var = "PKG_CONFIG_PATH" in
  let pkg_config_fallback = match Bos.OS.Env.var var with
    | Some path -> ":" ^ path
    | None -> ""
  in
  Lazy.force opam_prefix >>= fun prefix ->
  (* the order here matters (at least for ancient 0.26, distributed with
       ubuntu 14.04 versions): use share before lib! *)
  let value =
    Fmt.strf "%s/share/pkgconfig:%s/lib/pkgconfig%s"
      prefix prefix pkg_config_fallback
  in
  Bos.OS.Env.set_var var (Some value) >>= fun () ->
  let cmd = Bos.Cmd.(v "pkg-config" % pkgs %% of_list args) in
  Bos.OS.Cmd.(run_out cmd |> out_string |> success) >>| fun data ->
  String.cuts ~sep:" " ~empty:false data

(* Implement something similar to the @name/file extended names of findlib. *)
let rec expand_name ~lib param =
  match String.cut param ~sep:"@" with
  | None -> param
  | Some (prefix, name) -> match String.cut name ~sep:"/" with
    | None              -> prefix ^ Fpath.(to_string (v lib / name))
    | Some (name, rest) ->
      let rest = expand_name ~lib rest in
      prefix ^ Fpath.(to_string (v lib / name / rest))

(* Get the linker flags for any extra C objects we depend on.
 * This is needed when building a Xen/Solo5 image as we do the link manually. *)
let extra_c_artifacts target pkgs =
  Lazy.force opam_prefix >>= fun prefix ->
  let lib = prefix ^ "/lib" in
  let format = Fmt.strf "%%d\t%%(%s_linkopts)" target
  and predicates = "native"
  in
  query_ocamlfind ~recursive:true ~format ~predicates pkgs >>= fun data ->
  let r = List.fold_left (fun acc line ->
      match String.cut line ~sep:"\t" with
      | None -> acc
      | Some (dir, ldflags) ->
        if ldflags <> "" then begin
          let ldflags = String.cuts ldflags ~sep:" " in
          let ldflags = List.map (expand_name ~lib) ldflags in
          acc @ ("-L" ^ dir) :: ldflags
        end else
          acc
    ) [] data
  in
  R.ok r

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty = try Unix.(isatty (descr_of_out_channel Stdlib.stdout)) with
    | Unix.Unix_error _ -> false
  in
  not dumb && isatty

let rec rr_iter f l =
  match l with
  | [] -> R.ok ()
  | x :: l -> f x >>= fun () -> rr_iter f l
