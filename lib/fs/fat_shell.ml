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

  let read_sectors ss =
    Bitstring.concat (List.map read_sector ss)

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
	  handle_error
	    (fun data ->
	      let data = Bitstring.string_of_bitstring data in
	      Printf.printf "%s\n%!" data;
	      if String.length data <> Int32.to_int s.Dir_entry.file_size
	      then Printf.printf "Short read; expected %d got %d\n%!" (Int32.to_int s.Dir_entry.file_size) (String.length data)
	    ) (read fs (file_of_path fs path) 0 (Int32.to_int s.Dir_entry.file_size))
      ) (stat fs path) in
  let do_del file =
    let path = Path.cd !cwd file in
    handle_error
      (fun () -> ())
      (destroy fs path) in
  let do_cd dir =
    let path = Path.cd !cwd dir in
    Printf.printf "path = %s\n%!" (Path.to_string path);
    handle_error
      (function
	| Stat.Dir (_, _) ->
	  cwd := path
	| Stat.File _ -> Printf.printf "Not a directory.\n%!"
      ) (stat fs path) in
  let do_touch x =
    let path = Path.cd !cwd x in
    Printf.printf "path = %s\n%!" (Path.to_string path);
    handle_error
      (fun () -> ())
      (create fs path) in
  let do_copy x y =
    let is_outside = Stringext.startswith "u:" in
    let parse_path x =
      if Stringext.startswith "u:" x
      then Path.of_string (String.sub x 2 (String.length x - 2))
      else Path.of_string x in
    let x' = parse_path x and y' = parse_path y in
    match is_outside x, is_outside y with
      | true, false ->
	(* copying to the filesystem *)
	UnixBlock.with_file [ Unix.O_RDONLY ] ("." ^ (Path.to_string x'))
	  (fun ifd ->
	    let filename = Path.filename y' in
	    let path = Path.cd !cwd filename in
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
		  ) (write fs (file_of_path fs path) !offset bs)
	      done
	    ) (create fs path)
	  )
      | _, _ -> failwith "Unimplemented" in
  
  let finished = ref false in
  while not !finished do
    Printf.printf "A:%s> %!" (Path.to_string !cwd);
    match Stringext.split ' ' (input_line stdin) with
    | [ "dir" ] -> do_dir ""
    | [ "dir"; path ] -> do_dir path
    | [ "cd"; path ] -> do_cd path
    | [ "type"; path ] -> do_type path
    | [ "touch"; path ] -> do_touch path
    | [ "copy"; a; b ] -> do_copy a b
    | [ "del"; a ] -> do_del a
    | [ "exit" ] -> finished := true
    | [] -> ()
    | cmd :: _ -> Printf.printf "Unknown command: %s\n%!" cmd
  done


