(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
 * Copyright (c) 2019-2020 Etienne Millon <etienne@tarides.com>
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

let src = Logs.Src.create "functoria.action" ~doc:"functoria library"

module Log = (val Logs.src_log src : Logs.LOG)

open Astring

type 'a or_err = ('a, Rresult.R.msg) result

type tmp_name_pat = Bos.OS.File.tmp_name_pat

type 'a with_output = {
  mode : int option;
  path : Fpath.t;
  purpose : string;
  contents : Format.formatter -> 'a;
  append : bool;
}

type channel = [ `Null | `Fmt of Format.formatter ]

type cmd = { cmd : Bos.Cmd.t; err : channel; out : channel; trim : bool }

type ls = { root : Fpath.t; filter : Fpath.t -> bool }

type _ command =
  | Rmdir : Fpath.t -> unit command
  | Mkdir : Fpath.t -> bool command
  | Ls : ls -> Fpath.t list command
  | Rm : Fpath.t -> unit command
  | Is_file : Fpath.t -> bool command
  | Is_dir : Fpath.t -> bool command
  | Size_of : Fpath.t -> int option command
  | Run_cmd : cmd -> unit command
  | Run_cmd_out : cmd -> string command
  | Get_var : string -> string option command
  | Set_var : string * string option -> unit command
  | With_dir : Fpath.t * (unit -> 'a t) -> 'a command
  | Pwd : Fpath.t command
  | Tmp_file : int option * tmp_name_pat -> Fpath.t command
  | Write_file : Fpath.t * string -> unit command
  | Read_file : Fpath.t -> string command
  | With_output : 'a with_output -> 'a command

and _ t =
  | Done : 'a -> 'a t
  | Fail : string -> 'a t
  | Run : 'r command * ('r -> 'a t) -> 'a t

let ok x = Done x

let error e = Fail e

let errorf fmt = Fmt.kstr error fmt

let rec bind ~f = function
  | Done r -> f r
  | Fail s -> Fail s
  | Run (c, k) ->
      let k2 r = bind ~f (k r) in
      Run (c, k2)

let map ~f x = bind x ~f:(fun y -> ok (f y))

let rec seq = function [] -> ok () | h :: t -> bind ~f:(fun () -> seq t) h

let wrap x = Run (x, ok)

let ( ! ) = Fpath.normalize

let rm path = wrap @@ Rm !path

let rmdir path = wrap @@ Rmdir !path

let mkdir path = wrap @@ Mkdir !path

let ls path filter = wrap @@ Ls { root = !path; filter }

let with_dir path f = wrap @@ With_dir (!path, f)

let pwd () = wrap @@ Pwd

let is_file path = wrap @@ Is_file !path

let is_dir path = wrap @@ Is_dir !path

let size_of path = wrap @@ Size_of !path

let set_var c v = wrap @@ Set_var (c, v)

let get_var c = wrap @@ Get_var c

let run_cmd ?(err = `Fmt Fmt.stderr) ?(out = `Fmt Fmt.stdout) cmd =
  wrap @@ Run_cmd { cmd; out; err; trim = false }

let run_cmd_out ?(err = `Fmt Fmt.stderr) cmd =
  wrap @@ Run_cmd_out { cmd; out = `Null; err; trim = true }

let write_file path contents = wrap @@ Write_file (!path, contents)

let read_file path = wrap @@ Read_file !path

let tmp_file ?mode pat = wrap @@ Tmp_file (mode, pat)

let with_output ?mode ?(append = false) ~path ~purpose contents =
  wrap @@ With_output { append; mode; path; purpose; contents }

let pfo ppf s = match ppf with `Null -> () | `Fmt ppf -> Fmt.pf ppf "%s%!" s

let interpret_cmd { cmd; err; out; trim } =
  Log.debug (fun l -> l "RUN: %a" Bos.Cmd.pp cmd);
  let open Rresult in
  let err =
    match err with
    | `Null -> Ok (Bos.OS.Cmd.err_null, fun () -> Ok ())
    | `Fmt ppf ->
        Bos.OS.File.tmp "cmd-err-%s" >>| fun path ->
        let flush () = Bos.OS.File.read path >>| fun s -> Fmt.pf ppf "%s%!" s in
        (Bos.OS.Cmd.err_file path, flush)
  in
  err >>= fun (err, flush_err) ->
  let res = Bos.OS.Cmd.run_out ~err cmd in
  let res = Bos.OS.Cmd.out_string ~trim res in
  res >>= fun (str_out, _) ->
  pfo out str_out;
  flush_err () >>= fun () -> Bos.OS.Cmd.success res

let rec interpret_command : type r. r command -> r or_err = function
  | Rmdir path ->
      Log.debug (fun l -> l "rmdir %a" Fpath.pp path);
      Bos.OS.Dir.delete ~recurse:true path
  | Mkdir path ->
      Log.debug (fun l -> l "mkdir %a" Fpath.pp path);
      Bos.OS.Dir.create ~path:true path
  | Ls { root; filter } ->
      let open Rresult in
      Log.debug (fun l -> l "ls %a" Fpath.pp root);
      Bos.OS.Path.matches ~dotfiles:true Fpath.(root / "$(file)")
      >>| fun files -> List.filter filter files
  | Rm path ->
      Log.debug (fun l -> l "rm %a" Fpath.pp path);
      Bos.OS.File.delete ~must_exist:false path
  | Is_file path ->
      Log.debug (fun l -> l "is-file %a" Fpath.pp path);
      Bos.OS.File.exists path
  | Is_dir path ->
      Log.debug (fun l -> l "is-dir %a" Fpath.pp path);
      Bos.OS.Dir.exists path
  | Size_of path -> (
      Log.debug (fun l -> l "size-of %a" Fpath.pp path);
      match Bos.OS.Path.stat path with
      | Ok s -> Ok (Some s.Unix.st_size)
      | _ -> Ok None )
  | Run_cmd cmd -> Rresult.(interpret_cmd cmd >>| fun _ -> ())
  | Run_cmd_out cmd -> interpret_cmd cmd
  | Set_var (c, v) ->
      Log.debug (fun l ->
          l "set_var %s %a" c Fmt.(option ~none:(unit "<unset>") string) v);
      Bos.OS.Env.set_var c v
  | Get_var c ->
      Log.debug (fun l -> l "get_var %s" c);
      Ok (Bos.OS.Env.var c)
  | With_dir (dir, f) ->
      let f () = run (f ()) in
      let open Rresult in
      Bos.OS.Dir.current () >>= fun old ->
      Log.debug (fun l -> l "entering %a" Fpath.pp dir);
      Rresult.R.join @@ Bos.OS.Dir.with_current dir f () >>| fun r ->
      Log.debug (fun l -> l "entering %a" Fpath.pp old);
      r
  | Pwd ->
      Log.debug (fun l -> l "pwd");
      Bos.OS.Dir.current ()
  | Write_file (path, contents) ->
      Log.debug (fun l -> l "write %a" Fpath.pp path);
      Bos.OS.File.write path contents
  | Read_file path ->
      Log.debug (fun l -> l "read-file %a" Fpath.pp path);
      Bos.OS.File.read path
  | Tmp_file (mode, pat) ->
      Log.debug (fun l -> l "tmp-file %s" Fmt.(str pat "*"));
      Bos.OS.File.tmp ?mode pat
  | With_output { mode; path; purpose; contents; append } -> (
      try
        let oc =
          let path = Fpath.to_string path in
          let mode = match mode with None -> 0o666 | Some m -> m in
          if append then
            open_out_gen [ Open_wronly; Open_append; Open_text ] mode path
          else open_out path
        in
        let ppf = Format.formatter_of_out_channel oc in
        let r = contents ppf in
        Fmt.pf ppf "%!";
        flush oc;
        close_out oc;
        Ok r
      with e ->
        Rresult.R.error_msgf "couldn't open output channel for %s: %a" purpose
          Fmt.exn e )

and run : type r. r t -> r or_err = function
  | Done r -> Ok r
  | Fail f -> Error (`Msg f)
  | Run (cmd, k) -> Rresult.R.bind (interpret_command cmd) (fun x -> run @@ k x)

type files = [ `Passtrough of Fpath.t | `Files of (Fpath.t * string) list ]

(* (simple) virtual environment *)
module Env : sig
  type t

  val eq : t -> t -> bool

  val pp : t Fmt.t

  val pwd : t -> Fpath.t

  val chdir : t -> Fpath.t -> t

  val ls : t -> Fpath.t -> Fpath.t list option

  val v :
    ?commands:(Bos.Cmd.t -> (string * string) option) ->
    ?env:(string * string) list ->
    ?pwd:Fpath.t ->
    ?files:files ->
    unit ->
    t

  val exec : t -> Bos.Cmd.t -> (string * string) option

  val is_file : t -> Fpath.t -> bool

  val is_dir : t -> Fpath.t -> bool

  val mkdir : t -> Fpath.t -> (t * bool) option

  val rm : t -> Fpath.t -> (t * bool) option

  val rmdir : t -> Fpath.t -> t

  val size_of : t -> Fpath.t -> int option

  val write : t -> Fpath.t -> string -> t

  val read : t -> Fpath.t -> string option

  val tmp_file : t -> tmp_name_pat -> Fpath.t

  val set_var : t -> string -> string option -> t

  val get_var : t -> string -> string option
end = struct
  type t = {
    files : string Fpath.Map.t;
    pwd : Fpath.t;
    env : string String.Map.t;
    commands : Bos.Cmd.t -> (string * string) option;
  }

  let scan dir =
    (let open Rresult in
    Bos.OS.Path.fold ~dotfiles:true ~elements:`Files ~traverse:`Any
      (fun file files ->
        files >>= fun files ->
        Bos.OS.File.read file >>| fun c -> (file, c) :: files)
      (Ok []) [ dir ])
    |> Rresult.R.join
    |> Rresult.R.error_msg_to_invalid_arg

  let default_commands _ = None

  let v ?(commands = default_commands) ?env ?pwd ?(files = `Files []) () =
    let env =
      match env with Some e -> String.Map.of_list e | None -> String.Map.empty
    in
    let pwd = match pwd with None -> Fpath.v "/" | Some p -> p in
    let files =
      let files =
        match files with `Passtrough dir -> scan dir | `Files files -> files
      in
      let files =
        List.map
          (fun (f, c) ->
            match Fpath.is_rel f with
            | false -> (f, c)
            | true -> (Fpath.(pwd // f), c))
          files
      in
      List.map (fun (f, c) -> (Fpath.normalize f, c)) files
    in
    { files = Fpath.Map.of_list files; pwd; env; commands }

  let eq x y =
    Fpath.Map.equal ( = ) x.files y.files
    && Fpath.equal x.pwd y.pwd
    && String.Map.equal ( = ) x.env y.env

  let pp =
    let open Fmt.Dump in
    record
      [
        field "files" (fun t -> t.files) (Fpath.Map.dump string);
        field "pwd" (fun t -> t.pwd) Fpath.dump;
        field "env" (fun t -> t.env) (String.Map.dump string);
      ]

  let pwd t = t.pwd

  let exec t cmd = t.commands cmd

  let mk_path t path =
    match (Fpath.to_string t.pwd, Fpath.is_rel path) with
    | _, true -> Fpath.(normalize @@ (t.pwd // path))
    | _, false -> Fpath.normalize path

  let chdir t path =
    let pwd = mk_path t path in
    { t with pwd }

  let is_root path = Fpath.to_string path = "/"

  let mkdir t path =
    let path = mk_path t path in
    if is_root path then Some (t, false)
    else
      match Fpath.Map.find path t.files with
      | Some f when f <> "<DIR>" -> None
      | r ->
          let t = { t with files = Fpath.Map.add path "<DIR>" t.files } in
          Some (t, r = None)

  let rmdir t path =
    let path = mk_path t path in
    let files =
      Fpath.Map.filter
        (fun f _ ->
          let f = mk_path t f in
          let b = not (Fpath.is_prefix path f) in
          b)
        t.files
    in
    { t with files }

  let ls t path =
    let root = mk_path t path in
    match Fpath.Map.find root t.files with
    | Some "<DIR>" -> Some []
    | Some _ -> Some [ path ]
    | None -> (
        Fpath.Map.fold
          (fun file _ acc ->
            let file = mk_path t file in
            match Fpath.relativize ~root file with
            | None -> acc
            | Some f -> f :: acc)
          t.files []
        |> function
        | [] -> None
        | x -> Some (List.rev x) )

  let write t path f =
    let path = mk_path t path in
    { t with files = Fpath.Map.add path f t.files }

  let read t path =
    let path = mk_path t path in
    Fpath.Map.find path t.files

  let tmp_file t pat =
    let rec aux n =
      let dir = Fpath.v "/tmp" in
      let file = Fpath.(dir / Fmt.str pat (string_of_int n)) in
      if Fpath.Map.mem file t.files then aux (n + 1) else file
    in
    aux 0

  let is_dir t path =
    let path = mk_path t path in
    match Fpath.Map.find path t.files with
    | Some "<DIR>" -> true
    | Some _ -> false
    | None ->
        Fpath.Map.exists
          (fun f _ ->
            let f = mk_path t f in
            Fpath.is_prefix path f)
          t.files

  let is_file t path =
    let path = mk_path t path in
    match Fpath.Map.find path t.files with
    | Some "<DIR>" | None -> false
    | Some _ -> true

  let rm t path =
    let path = mk_path t path in
    match Fpath.Map.find path t.files with
    | Some "<DIR>" -> None
    | Some _ -> Some ({ t with files = Fpath.Map.remove path t.files }, true)
    | None -> if is_dir t path then None else Some (t, false)

  let size_of t path =
    let path = mk_path t path in
    match Fpath.Map.find path t.files with
    | None -> None
    | Some "<DIR>" -> Some 0
    | Some f -> Some (String.length f)

  let set_var t c = function
    | None -> { t with env = String.Map.remove c t.env }
    | Some v -> { t with env = String.Map.add c v t.env }

  let get_var t c = String.Map.find c t.env
end

let error_msg = Rresult.R.error_msgf

type env = Env.t

let env = Env.v

let eq_env = Env.eq

let pp_env = Env.pp

let interpret_dry_cmd env { cmd; err; out; _ } : string or_err * _ * _ =
  Log.debug (fun l -> l "Run_cmd '%a'" Bos.Cmd.pp cmd);
  let log x = Fmt.str "Run_cmd '%a' (%s)" Bos.Cmd.pp cmd x in
  match Env.exec env cmd with
  | None -> (error_msg "'%a' not found" Bos.Cmd.pp cmd, env, log "error")
  | Some (o, e) ->
      pfo out o;
      pfo err e;
      (Ok o, env, log "ok")

let rec interpret_dry : type r. env:Env.t -> r command -> r or_err * _ * _ =
 fun ~env -> function
  | Mkdir path -> (
      Log.debug (fun l -> l "Mkdir %a" Fpath.pp path);
      let log s = Fmt.str "Mkdir %a (%s)" Fpath.pp path s in
      match Env.mkdir env path with
      | Some (fs, true) -> (Ok true, fs, log "created")
      | Some (fs, false) -> (Ok false, fs, log "already exists")
      | None ->
          ( error_msg "a file named '%a' already exists" Fpath.pp path,
            env,
            log "error" ) )
  | Rmdir path ->
      Log.debug (fun l -> l "Rmdir %a" Fpath.pp path);
      let log s = Fmt.str "Rmdir %a (%s)" Fpath.pp path s in
      if Env.is_dir env path || Env.is_file env path then
        (Ok (), Env.rmdir env path, log "removed")
      else (Ok (), env, log "no-op")
  | Ls { root; filter } -> (
      Log.debug (fun l -> l "Ls %a" Fpath.pp root);
      let logs fmt = Fmt.kstr (Fmt.str "Ls %a (%s)" Fpath.pp root) fmt in
      match Env.ls env root with
      | None ->
          ( error_msg "%a: no such file or directory" Fpath.pp root,
            env,
            logs "error" )
      | Some es -> (
          match List.filter filter es with
          | ([] | [ _ ]) as e -> (Ok e, env, logs "%d entry" (List.length e))
          | es -> (Ok es, env, logs "%d entries" (List.length es)) ) )
  | Rm path -> (
      Log.debug (fun l -> l "Rm %a" Fpath.pp path);
      let log s = Fmt.str "Rm %a (%s)" Fpath.pp path s in
      match Env.rm env path with
      | Some (env, b) -> (Ok (), env, log (if b then "removed" else "no-op"))
      | None -> (error_msg "%a is a directory" Fpath.pp path, env, log "error")
      )
  | Is_file path ->
      Log.debug (fun l -> l "Is_file %a" Fpath.pp path);
      let r = Env.is_file env path in
      (Ok r, env, Fmt.str "Is_file? %a -> %b" Fpath.pp path r)
  | Is_dir path ->
      Log.debug (fun l -> l "Is_dir %a" Fpath.pp path);
      let r = Env.is_dir env path in
      (Ok r, env, Fmt.str "Is_dir? %a -> %b" Fpath.pp path r)
  | Size_of path ->
      Log.debug (fun l -> l "Size_of %a" Fpath.pp path);
      let r = Env.size_of env path in
      ( Ok r,
        env,
        Fmt.str "Size_of %a -> %a" Fpath.pp path
          Fmt.(option ~none:(unit "error") int)
          r )
  | Run_cmd cmd -> (
      match interpret_dry_cmd env cmd with
      | Ok _, env, log -> (Ok (), env, log)
      | (Error _, _, _) as e -> e )
  | Run_cmd_out cmd -> interpret_dry_cmd env cmd
  | Write_file (path, s) ->
      Log.debug (fun l -> l "Write_file %a" Fpath.pp path);
      ( Ok (),
        Env.write env path s,
        Fmt.str "Write to %a (%d bytes)" Fpath.pp path (String.length s) )
  | Read_file path -> (
      Log.debug (fun l -> l "Read_file %a" Fpath.pp path);
      match Env.read env path with
      | None ->
          ( error_msg "read_file: file does not exist",
            env,
            Fmt.str "Read: %a" Fpath.pp path )
      | Some r ->
          ( Ok r,
            env,
            Fmt.str "Read %a (%d bytes)" Fpath.pp path (String.length r) ) )
  | Tmp_file (_, pat) ->
      Log.debug (fun l -> l "Tmp_file %s" Fmt.(str pat "*"));
      let r = Env.tmp_file env pat in
      (Ok r, env, Fmt.str "Tmp_file -> %a" Fpath.pp r)
  | Set_var (c, v) ->
      Log.debug (fun l ->
          l "Set_var %s %a" c Fmt.(option ~none:(unit "<none>") string) v);
      let env = Env.set_var env c v in
      ( Ok (),
        env,
        Fmt.str "Set_var %s %a" c Fmt.(option ~none:(unit "<unset>") string) v
      )
  | Get_var c ->
      Log.debug (fun l -> l "Get_var %s" c);
      let v = Env.get_var env c in
      ( Ok v,
        env,
        Fmt.str "Get_var %s -> %a" c
          Fmt.(option ~none:(unit "<not set>") string)
          v )
  | With_dir (dir, f) ->
      Log.debug (fun l -> l "With_dir %a" Fpath.pp dir);
      let old = Env.pwd env in
      let env = Env.chdir env dir in
      let r, env, logs = dry_run ~env (f ()) in
      let env = Env.chdir env old in
      ( r,
        env,
        Fmt.str "With_dir %a [%a]" Fpath.pp dir
          Fmt.(vbox ~indent:2 (list ~sep:(unit "@,") string))
          logs )
  | Pwd ->
      Log.debug (fun l -> l "Pwd");
      let r = Env.pwd env in
      (Ok r, env, Fmt.str "Pwd -> %a" Fpath.pp r)
  | With_output { mode; path; purpose; contents; append } ->
      let pp_append ppf () = if append then Fmt.string ppf "[append]" else () in
      Log.debug (fun l ->
          l "With_output%a %a (%s)" pp_append () Fpath.pp path purpose);
      let buf = Buffer.create 0 in
      let fmt = Format.formatter_of_buffer buf in
      let pp_mode fmt = function
        | None -> Format.fprintf fmt "default"
        | Some n -> Format.fprintf fmt "%#o" n
      in
      let r = contents fmt in
      Fmt.pf fmt "%!";
      let f = Buffer.contents buf in
      ( Ok r,
        Env.write env path f,
        Fmt.str "Write to %a (mode: %a, purpose: %s)" Fpath.pp path pp_mode mode
          purpose )

and dry_run : type r. env:Env.t -> r t -> r or_err * _ * _ =
 fun ~env t ->
  let rec go t ~env log =
    match t with
    | Done r -> (Ok r, env, log)
    | Fail e -> (Error (`Msg e), env, log)
    | Run (cmd, k) -> (
        let r, new_env, log_line = interpret_dry ~env cmd in
        let new_log = log_line :: log in
        match r with
        | Ok x -> go (k x) ~env:new_env new_log
        | Error _ as e -> (e, new_env, new_log) )
  in
  let r, f, l = go t ~env [] in
  (r, f, List.rev l)

let dry_run ?(env = env ()) t = dry_run ~env t

let dry_run_trace ?env t =
  let _, _, lines = dry_run ?env t in
  List.iter print_endline lines

module Infix = struct
  let ( >>= ) x f = bind ~f x

  let ( >|= ) x f = map ~f x
end

module List = struct
  open Infix

  let iter ~f l = List.fold_left (fun acc e -> acc >>= fun () -> f e) (ok ()) l

  let map ~f l =
    List.fold_left
      (fun acc e ->
        acc >>= fun acc ->
        f e >|= fun e -> e :: acc)
      (ok []) l
end
