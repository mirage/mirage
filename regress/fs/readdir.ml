open Lwt
open Printf

let main () =
  let finished_t, u = Lwt.task () in
  let listen_t = OS.Devices.listen (fun id ->
    OS.Devices.find_blkif id >>=
    function
    | None -> return ()
    | Some blkif -> Lwt.wakeup u blkif; return ()
  ) in
  printf "Acquiring a block device\n%!";
  (* Get one device *)
  lwt blkif = finished_t in
  (* Cancel the listening thread *)
  Lwt.cancel listen_t;
  printf "Block device ID: %s\n%!" blkif#id;
  printf "Connected block device\n%!";

  exception IO_error of string
  let module M = struct
    let page_size_bytes = 4096
    let sector_size_bytes = 512
    let sectors_per_page = page_size_bytes / sector_size_bytes
    let read_sector x =
      match_lwt Lwt_stream.get (blkif#read_512 x 1) with
      | Some x -> return x
      | None -> fail (IO_error "read_sector")
    let write_sector x bs =
      failwith "Writing currently unimplemented"
  end in

  let open Fs.Fat in
  let module FS = FATFilesystem(M) in
  lwt fs = FS.make () in
  let path = Path.of_string "/" in
  lwt listdir = FS.stat fs path in
  (match listdir with
  | Success(Stat.Dir(_, ds)) ->
    printf "Directory for A:%s\n\n" (Path.to_string path);
    List.iter
      (fun x -> printf "%s\n" (Dir_entry.to_string x)) ds;
    printf "%9d files\n%!" (List.length ds);
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
    printf "Out of space.\n%!");
  return ()
