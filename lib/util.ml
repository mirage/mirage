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

let (|>) a f = f a

let unopt v = function
  | None -> raise Not_found
  | Some v -> v

let finally f cleanup =
  try
    let res = f () in cleanup (); res
  with exn -> cleanup (); raise exn

let lines_of_file file =
  let ic = open_in file in
  let lines = ref [] in
  let rec aux () =
    let line =
      try Some (input_line ic)
      with _ -> None in
    match line with
    | None   -> ()
    | Some l ->
      lines := l :: !lines;
      aux () in
  aux ();
  close_in ic;
  List.rev !lines

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

let key_value line =
  match cut_at line ':' with
  | None       -> None
  | Some (k,v) -> Some (k, strip v)

let filter_map f l =
  let rec loop accu = function
    | []     -> List.rev accu
    | h :: t ->
        match f h with
        | None   -> loop accu t
        | Some x -> loop (x::accu) t in
  loop [] l

let subcommand ~prefix (command, value) =
  let p1 = String.uncapitalize prefix in
  match cut_at command '-' with
  | None      -> None
  | Some(p,n) ->
    let p2 = String.uncapitalize p in
    if p1 = p2 then
      Some (n, value)
    else
      None

let append oc fmt =
  Printf.kprintf (fun str ->
    Printf.fprintf oc "%s\n" str
  ) fmt

let newline oc =
  append oc ""

let error fmt =
  Printf.kprintf (fun str ->
    Printf.eprintf "[mirari] ERROR: %s\n%!" str;
    exit 1;
  ) fmt

let info fmt =
  Printf.kprintf (Printf.printf "[mirari] %s\n%!") fmt

let debug fmt =
  Printf.kprintf (Printf.printf "[mirari] %s\n%!") fmt

let remove file =
  if Sys.file_exists file then (
    info "+ Removing %s." file;
    Sys.remove file
  )

let command ?switch fmt =
  Printf.kprintf (fun str ->
    let cmd = match switch with
      | None -> str
      | Some cmp -> Printf.sprintf "opam config exec \"%s\" --switch=%s" str cmp in
    info "+ Executing: %s" cmd;
    match Sys.command cmd with
    | 0 -> ()
    | i -> error "The command %S exited with code %d." cmd i
  ) fmt

let opam_install ?switch deps =
  let deps_str = String.concat " " deps in
  match switch with
  | None -> command "opam install --yes %s" deps_str
  | Some cmp -> command "opam install --yes %s --switch=%s" deps_str cmp

let in_dir dir f =
  let pwd = Sys.getcwd () in
  let reset () =
    if pwd <> dir then Sys.chdir pwd in
  if pwd <> dir then Sys.chdir dir;
  try let r = f () in reset (); r
  with e -> reset (); raise e

let cmd_exists s =
  Sys.command ("which " ^ s ^ " > /dev/null") = 0

(* If a configuration file is specified, then use that.
 * If not, then scan the curdir for a `.conf` file.
 * If there is more than one, then error out. *)
let scan_conf file =
  match file with
  |Some f ->  info "Using specified config file %s" f; f
  |None -> begin
     let files = Array.to_list (Sys.readdir ".") in
     match List.filter (fun f -> Filename.check_suffix f ".conf") files with
     |[] -> error "No configuration file ending in .conf found.\nYou'll need to create one to let Mirari know what do do."
     |[f] -> info "Using scanned config file %s" f; f
     |_ -> error "There is more than one file ending in .conf in the cwd.\nPlease specify one explicitly on the command-line."
  end

let read_command fmt =
  let open Unix in
  Printf.ksprintf (fun cmd ->
    let () = info "+ Executing: %s" cmd in
    let ic, oc, ec = open_process_full cmd (environment ()) in
    let buf1 = Buffer.create 64
    and buf2 = Buffer.create 64 in
    (try while true do Buffer.add_channel buf1 ic 1 done with End_of_file -> ());
    (try while true do Buffer.add_channel buf2 ec 1 done with End_of_file -> ());
    match close_process_full (ic,oc,ec) with
    | WEXITED 0   -> Buffer.contents buf1
    | WSIGNALED n -> error "process killed by signal %d" n
    | WSTOPPED n  -> error "process stopped by signal %d" n
    | WEXITED r   -> error "command terminated with exit code %d\nstderr: %s" r (Buffer.contents buf2)) fmt

