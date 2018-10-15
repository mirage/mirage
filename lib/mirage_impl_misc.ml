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
