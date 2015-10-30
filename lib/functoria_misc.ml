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

open Rresult

let (/) = Filename.concat

let err_cmdliner ?(usage=false) = function
  | Ok x -> `Ok x
  | Error s -> `Error (usage, s)

module type Monoid = sig
  type t
  val empty: t
  val union: t -> t -> t
end

module Set = struct
  (* Compat with OCaml < 4.02 *)
  module type S = sig
    include Set.S
    val of_list: elt list -> t
  end
  module Make (M: Set.OrderedType) = struct
    module M = Set.Make(M)
    let of_list l = List.fold_left (fun s x -> M.add x s) M.empty l
    let _ = of_list (* quiet warning 32 on 4.02 *)
    include M
  end
end

(* {String manipulation} *)

module String = struct

  include String

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

  module Set = Set.Make (String)

end

(* {Logging} *)

module Log = struct

  let color = ref None
  let set_color x = color := x
  let get_color () = !color

  let red     = Fmt.(styled `Red string)
  let green   = Fmt.(styled `Green string)
  let yellow  = Fmt.(styled `Yellow string)
  let blue    = Fmt.(styled `Cyan string)

  let section = ref "Functoria"
  let set_section s = section := s
  let get_section () = !section

  let in_section ?(color = Fmt.nop) ?(section = get_section ()) f fmt =
    f ("@[<2>%a@ "^^fmt^^"@]@.") color section

  let error_msg f = in_section ~color:red ~section:"[ERROR]" f

  exception Fatal of string

  let error fmt = Fmt.kstrf (fun x -> Error x) fmt
  let fail fmt = error_msg (Fmt.kstrf @@ fun s -> raise (Fatal s)) fmt
  let info fmt  = in_section ~color:green Fmt.pr fmt
  let debug fmt = in_section ~color:green Fmt.pr fmt
  let show_error fmt = error_msg Fmt.pr fmt

end

(* {Process and output} *)

module Cmd = struct

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
      Log.info "%a %s" Log.red "Removing:" (realpath file);
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
      try Ok (fn ())
      with e -> Error e in
    flush oc;
    Unix.dup2 fd_old fd_oc;
    Unix.close fd_old;
    match r with
    | Ok x -> x
    | Error e -> raise e


  let run ?(redirect=true) fmt =
    Format.ksprintf (fun cmd ->
        Log.info "%a@ %s" Log.yellow "=>"  cmd;
        let redirect fn =
          if redirect then (
            let status =
              with_redirect stdout "log" (fun () ->
                  with_redirect stderr "log" fn
                ) in
            if status <> 0 then
              let ic = open_in "log" in
              let buf = Buffer.create 17 in
              begin
                try while true do Buffer.add_channel buf ic 1 done
                with End_of_file -> ()
              end;
              Log.error "@;%a" Fmt.buffer buf
            else
              Ok status
          ) else (
            flush stdout;
            flush stderr;
            Ok (fn ())
          ) in
        match redirect (fun () -> Sys.command cmd) with
        | Ok 0 -> Ok ()
        | Ok i -> Log.error "The command %S exited with code %d." cmd i
        | Error err -> Log.error "%s" err
      ) fmt

  let opam cmd ?(yes=true) ?switch ?color deps =
    let color = match color with
      | None -> ""
      | Some `None -> " --color=never"
      | Some `Ansi_tty -> " --color=always"
    in
    let deps = String.concat " " deps in
    (* Note: we don't redirect output to the log as installation can
     * take a long time and the user will want to see what is
       happening. *)
    let yes = if yes then " --yes " else "" in
    let redirect = false in
    let switch = match switch with
      | None   -> ""
      | Some s -> Printf.sprintf " --switch=%s" s
    in
    run ~redirect "opam %s%s%s%s %s" cmd yes color switch deps

  let in_dir dir f =
    let pwd = Sys.getcwd () in
    let reset () =
      if pwd <> dir then Sys.chdir pwd in
    if pwd <> dir then Sys.chdir dir;
    try let r = f () in reset (); r
    with e -> reset (); raise e

  let with_process open_p close_p cmd f =
    let ic = open_p cmd in
    try
      let r = f ic in
      ignore (close_p ic); r
    with exn ->
      ignore (close_p ic); raise exn

  let with_process_in s f =
    with_process Unix.open_process_in Unix.close_process_in s f

  let with_process_out s f =
    with_process Unix.open_process_out Unix.close_process_out s f

  let with_channel oc f =
    let ppf = Format.formatter_of_out_channel oc in
    let x = f ppf in
    Format.pp_print_flush ppf ();
    x

  let with_file filename f =
    let oc = open_out filename in
    let x = with_channel oc f in
    close_out oc;
    x

  let collect_output cmd =
    try
      with_process_in cmd
        (fun ic -> Some (String.strip (input_line ic)))
    with _ ->
      None

  let uname_s () = collect_output "uname -s"
  let uname_m () = collect_output "uname -m"
  let uname_r () = collect_output "uname -r"

  let exists s = Sys.command ("which " ^ s ^ " > /dev/null") = 0

  let read fmt =
    let open Unix in
    Format.ksprintf (fun cmd ->
        Log.info "%a@ %s" Log.yellow "=>" cmd;
        let ic, oc, ec = open_process_full cmd (environment ()) in
        let buf1 = Buffer.create 64
        and buf2 = Buffer.create 64 in
        (try while true do Buffer.add_channel buf1 ic 1 done with End_of_file -> ());
        (try while true do Buffer.add_channel buf2 ec 1 done with End_of_file -> ());
        match close_process_full (ic,oc,ec) with
        | WEXITED 0   -> Ok (Buffer.contents buf1)
        | WSIGNALED n -> Log.error "process killed by signal %d" n
        | WSTOPPED n  -> Log.error "process stopped by signal %d" n
        | WEXITED r   ->
          Log.error "command terminated with exit code %d\nstderr: %s" r
            (Buffer.contents buf2)) fmt

  let ocaml_version () =
    let version =
      match String.cut_at Sys.ocaml_version '+' with
      | Some (version, _) -> version
      | None              -> Sys.ocaml_version in
    match String.split version '.' with
    | major :: minor :: _ ->
      begin
        try int_of_string major, int_of_string minor
        with _ -> 0, 0
      end
    | _ -> 0, 0

  module OCamlfind = struct

    let query ?predicates ?(format="%p") ?(recursive=false) xs =
      let pred = match predicates with
        | None    -> ""
        | Some ps -> "-predicates '" ^ String.concat "," ps ^ "'"
      and fmt  = "-format '" ^ format ^ "'"
      and r    = if recursive then "-recursive" else ""
      and pkgs = String.concat " " xs
      in
      read "ocamlfind query %s %s %s %s" fmt pred r pkgs
      >>| fun out -> String.split out '\n'

    let installed lib =
      Sys.command ("ocamlfind query " ^ lib ^ " 2>&1 1>/dev/null") = 0

  end

end
(* {Misc informations} *)


module Name = struct

  let ocamlify s =
    let b = Buffer.create (String.length s) in
    String.iter begin function
      | 'a'..'z' | 'A'..'Z'
      | '0'..'9' | '_' as c -> Buffer.add_char b c
      | '-' -> Buffer.add_char b '_'
      | _ -> ()
    end s;
    let s' = Buffer.contents b in
    if String.length s' = 0 || ('0' <= s'.[0] && s'.[0] <= '9') then
      raise (Invalid_argument s);
    s'

  let ids = Hashtbl.create 1024

  let names = Hashtbl.create 1024

  let create name =
    let n =
      try 1 + Hashtbl.find ids name
      with Not_found -> 1 in
    Hashtbl.replace ids name n;
    Format.sprintf "%s%d" name n

  let find_or_create tbl key create_value =
    try Hashtbl.find tbl key
    with Not_found ->
      let value = create_value () in
      Hashtbl.add tbl key value;
      value

  let create key ~prefix =
    find_or_create names key (fun () -> create prefix)

end

module Codegen = struct

  let main_ml = ref None


  let generated_header () =
    let name = Log.get_section () in
    let t = Unix.gettimeofday () in
    let months = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun";
                    "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |] in
    let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
    let time = Unix.gmtime t in
    let date =
      Format.sprintf "%s, %d %s %d %02d:%02d:%02d GMT"
        days.(time.Unix.tm_wday) time.Unix.tm_mday
        months.(time.Unix.tm_mon) (time.Unix.tm_year+1900)
        time.Unix.tm_hour time.Unix.tm_min time.Unix.tm_sec in
    Format.sprintf "Generated by %s (%s)." name date

  let append oc fmt = Format.fprintf oc (fmt ^^ "@.")
  let newline oc = append oc ""

  let append_main fmt = match !main_ml with
    | None    -> failwith "main_ml"
    | Some oc -> append oc fmt

  let newline_main () = match !main_ml with
    | None    -> failwith "main_ml"
    | Some oc -> newline oc

  let set_main_ml file =
    let oc = Format.formatter_of_out_channel @@ open_out file in
    main_ml := Some oc

end

(* TTY feature detection *)
module Terminfo = struct

  (* stolen from opam *)

  let default_columns = 100

  let with_process_in cmd args f =
    let path = ["/bin";"/usr/bin"] in
    let cmd =
      List.find Sys.file_exists (List.map (fun d -> Filename.concat d cmd) path)
    in
    Cmd.with_process_in (cmd^" "^args) f

  let get_terminal_columns () =
    try (* terminfo *)
      with_process_in "tput" "cols"
        (fun ic -> int_of_string (input_line ic))
    with Unix.Unix_error _ | Sys_error _ | Failure _ | End_of_file | Not_found ->
      try (* GNU stty *)
        with_process_in "stty" "size"
          (fun ic ->
             match String.split (input_line ic) ' ' with
             | [_; v] -> int_of_string v
             | _ -> failwith "stty")
      with
        Unix.Unix_error _ | Sys_error _ | Failure _  | End_of_file | Not_found ->
        try (* shell envvar *)
          int_of_string (Unix.getenv "COLUMNS")
        with Not_found | Failure _ ->
          default_columns

  let tty_out = Unix.isatty Unix.stdout

  let columns =
    let v = ref (lazy (get_terminal_columns ())) in
    let () =
      try Sys.set_signal 28 (* SIGWINCH *)
            (Sys.Signal_handle
               (fun _ -> v := lazy (get_terminal_columns ())))
      with Invalid_argument _ -> ()
    in
    fun () ->
      if tty_out
      then Lazy.force !v
      else 80

end

module Univ = struct

  type 'a key = string * ('a -> exn) * (exn -> 'a)

  let new_key: string -> 'a key =
    fun s (type a) ->
      let module M = struct
        exception E of a
      end
      in
      ( s
      , (fun a -> M.E a)
      , (function M.E a -> a | _ -> assert false)
      )

  module Map = Map.Make(String)

  type t = exn Map.t

  let empty = Map.empty

  let add (kn, kput, _kget) v t =
    Map.add kn (kput v) t

  let mem (kn, _, _) t =
    Map.mem kn t

  let find (kn, _kput, kget) t =
    if Map.mem kn t then Some (kget @@ Map.find kn t)
    else None
end
