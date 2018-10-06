type 'a or_err = ('a, Rresult.R.msg) result

type _ command =
  | Delete : Fpath.t -> unit command
  | Exists : Fpath.t -> bool command
  | Run_cmd : Bos.Cmd.t -> unit command
  | Write_file : Fpath.t * string -> unit command
  | With_out : int option * Fpath.t * string * (Format.formatter -> 'a) -> 'a command

type _ t =
  | Done : 'a -> 'a t
  | Run : 'r command * ('r -> 'a t) -> 'a t

let return x =
  Done x

let rec bind ~f = function
  | Done r -> f r
  | Run (c, k) ->
      let k2 r = bind ~f (k r) in
      Run (c, k2)

let map ~f x =
  bind x ~f:(fun y -> return (f y))

let wrap x =
  Run (x, return)

let delete path =
  wrap @@ Delete path

let exists path =
  wrap @@ Exists path

let run_cmd path =
  wrap @@ Run_cmd path

let write_file path contents =
  wrap @@ Write_file (path, contents)

let with_out ~mode ~path ~purpose k =
  wrap @@ With_out (mode, path, purpose, k)

let interpret_command : type r . r command -> r or_err = function
  | Delete path -> Bos.OS.File.delete path
  | Exists path -> Bos.OS.File.exists path
  | Run_cmd path -> Bos.OS.Cmd.run path
  | Write_file (path, contents) -> Bos.OS.File.write path contents
  | With_out (mode, path, purpose, k) ->
      let bos_k oc () =
        let fmt = Format.formatter_of_out_channel oc in
        Ok (k fmt)
      in
      match Bos.OS.File.with_oc ?mode path bos_k () with
      | Ok b -> b
      | Error _ -> Rresult.R.error_msg ("couldn't open output channel for " ^ purpose)

let rec run = function
  | Done r -> Ok r
  | Run (cmd, k) ->
      Rresult.R.bind
        (interpret_command cmd)
        (fun x -> run @@ k x)

let interpret_dry : type r . files:_ -> r command -> r or_err * _ * _ =
  fun ~files ->
  function
    | Delete path ->
        let log s = Format.asprintf "Delete %a (%s)" Fpath.pp path s in
        if Fpath.Set.mem path files then
          ( Ok ()
          , Fpath.Set.remove path files
          , log "ok"
          )
        else
          ( Rresult.R.error_msg "File does not exist"
          , files
          , log "error"
          )
    | Exists path ->
        let r = Fpath.Set.mem path files in
        (Ok r, files, Format.asprintf "Exists? %a -> %b" Fpath.pp path r)
    | Run_cmd cmd ->
        ( Rresult.R.error_msg "run_cmd is not supported"
        , files
        , Format.asprintf "Run: %a" Bos.Cmd.pp cmd
        )
    | Write_file (path, s) ->
        ( Ok ()
        , Fpath.Set.add path files
        , Format.asprintf
            "Write to %a (%d bytes)"
            Fpath.pp path
            (String.length s)
        )
    | With_out (mode, path, purpose, k) ->
        let buf = Buffer.create 0 in
        let fmt = Format.formatter_of_buffer buf in
        let pp_mode fmt = function
          | None -> Format.fprintf fmt "default"
          | Some n -> Format.fprintf fmt "%#o" n
        in
        ( Ok (k fmt)
        , Fpath.Set.add path files
        , Format.asprintf
            "Write (fmt) to %a (mode: %a, purpose: %s)"
            Fpath.pp path
            pp_mode mode
            purpose
        )

let dry_run t ~files =
  let rec go t ~files log =
    match t with
    | Done r -> (Ok r, files, log)
    | Run (cmd, k) ->
        begin
          let r, new_files, log_line = interpret_dry ~files cmd in
          let new_log = log_line::log in
          match r with
          | Ok x -> go (k x) ~files:new_files new_log
          | Error _ as e -> e, new_files, new_log
        end
  in
  let (r, f, l) = go t ~files:(Fpath.Set.of_list files) [] in
  (r, Fpath.Set.elements f, List.rev l)

let dry_run_trace t ~files =
  let (_, _, lines) = dry_run t ~files in
  List.iter print_endline lines

module Infix = struct
  let (>>=) x f =
    bind ~f x
end
