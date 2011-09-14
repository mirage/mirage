(* This is a toplevel-like test program *)

open Fat
open Fat_utils

let filename = ref ""
let sector_size = 512

module UnixBlock = struct

  let rec really_read fd string off n =
    if n=0 then () else
      let m = Unix.read fd string off n in
      if m = 0 then raise End_of_file;
      really_read fd string (off+m) (n-m)

  let finally f g =
    try
      let result = f () in
      g ();
      result
    with e ->
      g ();
      raise e

  let with_file flags filename f =
    let file = Unix.openfile filename flags 0o0 in
    finally (fun () -> f file) (fun () -> Unix.close file)

  let read_sector n =
    with_file [ Unix.O_RDONLY ] !filename
      (fun f ->
        ignore(Unix.lseek f (n * sector_size) Unix.SEEK_SET);
        let results = String.create sector_size in
        really_read f results 0 sector_size;
        Bitstring.bitstring_of_string results
      )

  let write_sector n bs =
    assert(Bitstring.bitstring_length bs / 8 = sector_size);
    with_file [ Unix.O_WRONLY ] !filename
      (fun f ->
	ignore(Unix.lseek f (n * sector_size) Unix.SEEK_SET);
	let m = Unix.write f (Bitstring.string_of_bitstring bs) 0 sector_size in
	if m <> sector_size then failwith (Printf.sprintf "short write: sector=%d written=%d" n m)
      )

end

module Test = (FATFilesystem(UnixBlock) : FS)

let () =
  let usage () =
    Printf.fprintf stderr "Usage:\n";
    Printf.fprintf stderr "  %s -fs <filesystem>\n" Sys.argv.(0);
    exit 1 in

  Arg.parse
    [ ("-fs", Arg.Set_string filename, "Filesystem to open") ]
    (fun x -> Printf.fprintf stderr "Skipping unknown argument: %s\n" x)
    "Examine the contents of a fat filesystem";
  if !filename = "" then usage ();

  let fs = Test.make () in

  let open Test in
  let handle_error f = function
    | Error (Not_a_directory path) -> Printf.printf "Not a directory (%s).\n%!" (Path.to_string path)
    | Error (Is_a_directory path) -> Printf.printf "Is a directory (%s).\n%!" (Path.to_string path)
    | Error (Directory_not_empty path) -> Printf.printf "Directory isn't empty (%s).\n%!" (Path.to_string path)
    | Error (No_directory_entry (path, name)) -> Printf.printf "No directory %s in %s.\n%!" name (Path.to_string path)
    | Error (File_already_exists name) -> Printf.printf "File already exists (%s).\n%!" name
    | Error No_space -> Printf.printf "Out of space.\n%!"
    | Success x -> f x in

  let cwd = ref (Path.of_string "/") in

  let do_dir dir =
    let path = Path.cd !cwd dir in
    handle_error
      (function
	| Stat.Dir (_, dirs) ->
	  Printf.printf "Directory for A:%s\n\n" (Path.to_string path);
	  List.iter
            (fun x -> Printf.printf "%s\n" (Dir_entry.to_string x)) dirs;
	  Printf.printf "%9d files\n%!" (List.length dirs)
	| Stat.File _ -> Printf.printf "Not a directory.\n%!"
      ) (stat fs path) in
  let do_type file =
    let path = Path.cd !cwd file in
    handle_error 
      (function
	| Stat.Dir (_, _) -> Printf.printf "Is a directory.\n%!"
	| Stat.File s ->
	  let file_size = Int32.to_int (Dir_entry.file_size_of s) in
	  handle_error
	    (fun data ->
	      let data = Bitstring.string_of_bitstring data in
	      Printf.printf "%s\n%!" data;
	      if String.length data <> file_size
	      then Printf.printf "Short read; expected %d got %d\n%!" file_size (String.length data)
	    ) (read fs (file_of_path fs path) 0 file_size)
      ) (stat fs path) in
  let do_del file =
    let path = Path.cd !cwd file in
    handle_error
      (fun () -> ())
      (destroy fs path) in
  let do_cd dir =
    let path = Path.cd !cwd dir in
    handle_error
      (function
	| Stat.Dir (_, _) ->
	  cwd := path
	| Stat.File _ -> Printf.printf "Not a directory.\n%!"
      ) (stat fs path) in
  let do_touch x =
    let path = Path.cd !cwd x in
    handle_error
      (fun () -> ())
      (create fs path) in
  let do_mkdir x = 
    let path = Path.cd !cwd x in
    handle_error
      (fun () -> ())
      (mkdir fs path) in
  let do_rmdir x = 
    let path = Path.cd !cwd x in
    handle_error
      (fun () -> ())
      (destroy fs path) in
  let copy_file_in outside inside =
    UnixBlock.with_file [ Unix.O_RDONLY ] (Path.to_string outside)
      (fun ifd ->
	handle_error (fun _ ->
	  let block_size = 1024 in
          let results = String.create block_size in
	  let bs = Bitstring.bitstring_of_string results in
	  let finished = ref false in
	  let offset = ref 0 in
	  while not !finished do
	    let n = Unix.read ifd results 0 block_size in
	    finished := n <> block_size;
	    handle_error
	      (fun () ->
		offset := !offset + block_size;
	      ) (write fs (file_of_path fs inside) !offset (Bitstring.takebits (n * 8) bs))
	  done
	) (create fs inside)
      ) in
  let rec copy_in outside inside =
    if Sys.is_directory (Path.to_string outside) then begin
      handle_error (fun () -> ()) (mkdir fs inside);
      Array.iter
	(fun x ->
	  let outside' = Path.cd outside x and inside' = Path.cd inside x in
	  copy_in outside' inside'
	) (Sys.readdir (Path.to_string outside))
    end else begin
      copy_file_in outside inside
    end in

  let parse_path x =
    (* return a pair of (outside filesystem bool, absolute path) *)
    let is_outside = Stringext.startswith "u:" x in
    (* strip off the drive prefix *)
    let x' = if is_outside then String.sub x 2 (String.length x - 2) else x in
    let is_absolute = x' <> "" && x'.[0] = '/' in
    let abspath =
      if is_absolute
      then Path.of_string x'
      else
	let wd = if is_outside then Path.of_string (Unix.getcwd ()) else !cwd in
	Path.cd wd x' in
    is_outside, abspath in

  let do_copy x y =
    let x_outside, x_path = parse_path x in
    let y_outside, y_path = parse_path y in
    match x_outside, y_outside with
      | true, false ->
	copy_in x_path y_path
      | _, _ -> failwith "Unimplemented" in

  let deltree x =
    let rec inner path =
      handle_error
	(function
	  | Stat.Dir (_, dirs) ->
	    List.iter
	      (fun dir ->
		inner (Path.cd path (Dir_entry.filename_of dir))
	      ) dirs;
	    handle_error (fun () -> ()) (destroy fs path)
	  | Stat.File _ ->
	    handle_error (fun () -> ()) (destroy fs path)  
	) (stat fs path) in
    inner (snd(parse_path x)) in

  let finished = ref false in
  while not !finished do
    Printf.printf "A:%s> %!" (Path.to_string !cwd);
    match Stringext.split ' ' (input_line stdin) with
    | [ "dir" ] -> do_dir ""
    | [ "dir"; path ] -> do_dir path
    | [ "cd"; path ] -> do_cd path
    | [ "type"; path ] -> do_type path
    | [ "touch"; path ] -> do_touch path
    | [ "mkdir"; path ] -> do_mkdir path
    | [ "rmdir"; path ] -> do_rmdir path
    | [ "copy"; a; b ] -> do_copy a b
    | [ "deltree"; a ] -> deltree a
    | [ "del"; a ] -> do_del a
    | [ "exit" ] -> finished := true
    | [] -> ()
    | cmd :: _ -> Printf.printf "Unknown command: %s\n%!" cmd
  done


