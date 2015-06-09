(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)


let (/) = Filename.concat

let strip str =
  let p = ref 0 in
  let l = String.length str in
  let fn = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false in
  while !p < l && fn (String.unsafe_get str !p) do
    incr p;
  done;
  let p = !p in
  let l = ref (l - 1) in
  while !l >= p && fn (String.unsafe_get str !l) do
    decr l;
  done;
  String.sub str p (!l - p + 1)

let cut_at s sep =
  try
    let i = String.index s sep in
    let name = String.sub s 0 i in
    let version = String.sub s (i+1) (String.length s - i - 1) in
    Some (name, version)
  with _ ->
    None

let split s sep =
  let rec aux acc r =
    match cut_at r sep with
    | None       -> List.rev (r :: acc)
    | Some (h,t) -> aux (strip h :: acc) t in
  aux [] s

let after prefix s =
  let lp = String.length prefix in
  let ls = String.length s in
  if ls >= lp && String.sub s 0 lp = prefix then
    Some (String.sub s lp (ls - lp))
  else
    None

let finally f cleanup =
  try
    let res = f () in cleanup (); res
  with exn -> cleanup (); raise exn

let append oc fmt =
  Printf.kprintf (fun str ->
      Printf.fprintf oc "%s\n" str
    ) fmt

let newline oc =
  append oc ""

(* Code duplication with irminsule/alcotest *)
let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let red_s = red "%s"
let green_s = green "%s"
let yellow_s = yellow "%s"
let blue_s = blue "%s"

let with_process_in cmd f =
  let ic = Unix.open_process_in cmd in
  try
    let r = f ic in
    ignore (Unix.close_process_in ic) ; r
  with exn ->
    ignore (Unix.close_process_in ic) ; raise exn

let terminal_columns =
  try           (* terminfo *)
    with_process_in "tput cols"
      (fun ic -> int_of_string (input_line ic))
  with _ -> try (* GNU stty *)
      with_process_in "stty size"
        (fun ic ->
           match split (input_line ic) ' ' with
           | [_ ; v] -> int_of_string v
           | _ -> failwith "stty")
    with _ -> try (* shell envvar *)
        int_of_string (Sys.getenv "COLUMNS")
      with _ ->
        80

let indent_left s nb =
  let nb = nb - String.length s in
  if nb <= 0 then
    s
  else
    s ^ String.make nb ' '

let indent_right s nb =
  let nb = nb - String.length s in
  if nb <= 0 then
    s
  else
    String.make nb ' ' ^ s

let left_column () =
  20

let right_column () =
  terminal_columns
  - left_column ()
  + 19

let right s =
  Printf.printf "%s\n%!" (indent_right s (right_column ()))

let left s =
  Printf.printf "%s%!" (indent_left s (left_column ()))

let error_msg section fmt =
  Printf.kprintf (fun str ->
      Printf.eprintf "%s %s\n%!"
        (indent_left (red_s section) (left_column ()))
        str;
    ) fmt

let error fmt =
  Printf.ksprintf (fun str ->
      error_msg "[ERROR]" "%s" str;
      exit 1;
    ) fmt

let section = ref "Mirage"

let set_section s = section := s

let get_section () = !section

let info fmt =
  Printf.kprintf (fun str ->
      left (green_s !section);
      Printf.printf "%s%!\n" str
    ) fmt

let debug fmt =
  Printf.kprintf (fun str ->
      left (yellow_s "Debug");
      Printf.printf "%s%!\n" str
    ) fmt

let realdir dir =
  if Sys.file_exists dir && Sys.is_directory dir then (
    let cwd = Sys.getcwd () in
    Sys.chdir dir;
    let d = Sys.getcwd () in
    Sys.chdir cwd;
    d
  ) else
    failwith "realdir"

let realpath file =
  if Sys.file_exists file && Sys.is_directory file then realdir file
  else if Sys.file_exists file
       || Sys.file_exists (Filename.dirname file) then
    realdir (Filename.dirname file) / (Filename.basename file)
  else
    failwith "realpath"

let remove file =
  if Sys.file_exists file then (
    info "%s %s" (red_s "Removing:") (realpath file);
    Sys.remove file
  )

let with_redirect oc file fn =
  flush oc;
  let fd_oc = Unix.descr_of_out_channel oc in
  let fd_old = Unix.dup fd_oc in
  let fd_file = Unix.(openfile file [O_WRONLY; O_TRUNC; O_CREAT] 0o666) in
  Unix.dup2 fd_file fd_oc;
  Unix.close fd_file;
  let r =
    try `Ok (fn ())
    with e -> `Error e in
  flush oc;
  Unix.dup2 fd_old fd_oc;
  Unix.close fd_old;
  match r with
  | `Ok x -> x
  | `Error e -> raise e

let command ?(redirect=true) fmt =
  Printf.kprintf (fun cmd ->
      info "%s %s" (yellow_s "=>") cmd;
      let redirect fn =
        if redirect then (
          let status =
            with_redirect stdout "log" (fun () ->
              with_redirect stderr "log" fn
            ) in
          if status <> 0 then (
            let ic = open_in "log" in
            try while true do error_msg !section "%s" (input_line ic) done;
            with End_of_file -> ()
          );
          status
        ) else (
          flush stdout;
          flush stderr;
          fn ()
        ) in
      match redirect (fun () -> Sys.command cmd) with
      | 0 -> ()
      | i ->
        error "The command %S exited with code %d." cmd i;
    ) fmt

let opam cmd ?(yes=true) ?switch deps =
  let deps_str = String.concat " " deps in
  (* Note: we don't redirect output to the log as installation can take a long time
   * and the user will want to see what is happening. *)
  let yes = if yes then "--yes " else "" in
  match switch with
  | None     -> command ~redirect:false "opam %s %s%s" cmd yes deps_str
  | Some cmp -> command ~redirect:false "opam %s %s%s --switch=%s" cmd yes deps_str cmp

let in_dir dir f =
  let pwd = Sys.getcwd () in
  let reset () =
    if pwd <> dir then Sys.chdir pwd in
  if pwd <> dir then Sys.chdir dir;
  try let r = f () in reset (); r
  with e -> reset (); raise e

let collect_output cmd =
  try
    with_process_in cmd
      (fun ic -> Some (strip (input_line ic)))
  with _ ->
    None

let uname_s () = collect_output "uname -s"
let uname_m () = collect_output "uname -m"
let uname_r () = collect_output "uname -r"

let command_exists s =
  Sys.command ("which " ^ s ^ " > /dev/null") = 0

let read_command fmt =
  let open Unix in
  Printf.ksprintf (fun cmd ->
      let () = info "%s %s" (yellow_s "=>") cmd in
      let ic, oc, ec = open_process_full cmd (environment ()) in
      let buf1 = Buffer.create 64
      and buf2 = Buffer.create 64 in
      (try while true do Buffer.add_channel buf1 ic 1 done with End_of_file -> ());
      (try while true do Buffer.add_channel buf2 ec 1 done with End_of_file -> ());
      match close_process_full (ic,oc,ec) with
      | WEXITED 0   -> Buffer.contents buf1
      | WSIGNALED n -> error "process killed by signal %d" n
      | WSTOPPED n  -> error "process stopped by signal %d" n
      | WEXITED r   ->
        error "command terminated with exit code %d\nstderr: %s" r (Buffer.contents buf2)) fmt

let generated_by_mirage =
  let t = Unix.gettimeofday () in
  let months = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun";
                  "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |] in
  let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
  let time = Unix.gmtime t in
  let date =
    Printf.sprintf "%s, %d %s %d %02d:%02d:%02d GMT"
      days.(time.Unix.tm_wday) time.Unix.tm_mday
      months.(time.Unix.tm_mon) (time.Unix.tm_year+1900)
      time.Unix.tm_hour time.Unix.tm_min time.Unix.tm_sec in
  Printf.sprintf "Generated by Mirage (%s)." date

let ocaml_version () =
  let version =
    match cut_at Sys.ocaml_version '+' with
    | Some (version, _) -> version
    | None              -> Sys.ocaml_version in
  match split version '.' with
  | major :: minor :: _ ->
    begin
      try int_of_string major, int_of_string minor
      with _ -> 0, 0
    end
  | _ -> 0, 0

let cofind (type t) h value =
  let module M = struct
    exception Found of t
  end in
  try
    Hashtbl.iter (fun k v ->
        if v = value then raise (M.Found k)
      ) h;
    raise Not_found
  with
  | M.Found k -> k

let find_or_create tbl key create_value =
  try Hashtbl.find tbl key
  with Not_found ->
    let value = create_value () in
    Hashtbl.add tbl key value;
    value

let dump h =
  Printf.eprintf "{ ";
  Hashtbl.iter (fun k v ->
      Printf.eprintf "%s:%s " k v
    ) h;
  Printf.eprintf "}\n%!"

module StringSet = Set.Make(struct
    type t = string
    let compare = String.compare
  end)

let dedup l =
  StringSet.(elements (List.fold_left (fun s e -> add e s) empty l))

module OCamlfind = struct

  let query ?predicates ?(format="%p") ?(recursive=false) xs =
    let pred = match predicates with
      | None    -> ""
      | Some ps -> "-predicates '" ^ String.concat "," ps ^ "'"
    and fmt  = "-format '" ^ format ^ "'"
    and r    = if recursive then "-recursive" else ""
    and pkgs = String.concat " " xs
    in
    let out = read_command "ocamlfind query %s %s %s %s" fmt pred r pkgs in
    split out '\n'

  let installed lib =
    Sys.command ("ocamlfind query " ^ lib ^ " 2>&1 1>/dev/null") = 0

end
