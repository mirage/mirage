open Lwt
open Printf

let main () =
  lwt ids = OS.Blkif.enumerate () in
  printf "VM has %d block devices configured\n%!" (List.length ids);
  let id = List.hd ids in
  lwt vbd,vbd_t = OS.Blkif.create id in
  printf "Connected block device\n%!";

  let module M = struct
    let page_size_bytes = 4096
    let sector_size_bytes = 512
    let sectors_per_page = page_size_bytes / sector_size_bytes
    let read_sector x =
      let page_no = x / sectors_per_page in
      lwt page = OS.Blkif.read_page vbd (Int64.of_int page_no) in
      Bitstring.bitstring_clip (page_no * sector_size_bytes * 8) (sector_size_bytes * 8)
    let write_sector x bs =
      let page_no = x / sectors_per_page in
	  let sector_no = x mod sectors_per_page in
	  lwt page = OS.Blkif.read_page vbd (Int64.of_int page_no) in
      Bitstring.bitstring_write bs (Int64.of_int (sector_no * sector_size_bytes)) existing_page;
	  lwt () = OS.Blkif.write_page vbd (Int64.of_int page_no) page in
      ()
  end in

  let open FAT in
  let module FS = FATFilesystem(M) in
  let fs = FS.make () in
  lwt listdir = FS.stat fs (Path.of_string "/") in
  match listdir with
  | Success(Stat.Dir(_, ds)) ->
    printf "Directory for A:%s\n\n" (Path.to_string path);
    List.iter
      (fun x -> printf "%s\n" (Dir_entry.to_string x)) dirs;
    printf "%9d files\n%!" (List.length dirs)
  | Success(Stat.File _) ->
    printf "Not a directory.\n%!"
  | Error (Not_a_directory path) ->
    printf "Not a directory (%s).\n%!" (Path.to_string path)
  | Error (Is_a_directory path) ->
    printf "Is a directory (%s).\n%!" (Path.to_string path)
  | Error (Directory_not_empty path) ->
    printf "Directory isn't empty (%s).\n%!" (Path.to_string path)
  | Error (No_directory_entry (path, name)) ->
    printf "No directory %s in %s.\n%!" name (Path.to_string path)
  | Error (File_already_exists name) ->
    printf "File already exists (%s).\n%!" name
  | Error No_space ->
    printf "Out of space.\n%!"
