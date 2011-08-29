open Printf

let sector_size = 512

let f = ref Unix.stdin

let opendevice filename =
  f := Unix.openfile filename [ Unix.O_RDONLY ] 0o0

let rec really_read fd string off n =
  if n=0 then () else
    let m = Unix.read fd string off n in
    if m = 0 then raise End_of_file;
    really_read fd string (off+m) (n-m)

let read_block n =
  Unix.lseek !f (n * sector_size) Unix.SEEK_SET;
  let results = String.create sector_size in
  really_read !f results 0 sector_size;
  results

let () =
  let usage () =
    Printf.fprintf stderr "Usage:\n";
    Printf.fprintf stderr "  %s -fs <filesystem>\n" Sys.argv.(0);
    exit 1 in

  let fs = ref "" in
  Arg.parse
    [ ("-fs", Arg.Set_string fs, "Filesystem to open") ]
    (fun x -> Printf.fprintf stderr "Skipping unknown argument: %s\n" x)
    "Examine the contents of a fat filesystem";
  if !fs = "" then usage ();

  opendevice !fs;  

  (* Load the boot sector *)
  let bits = Bitstring.bitstring_of_string (read_block 0) in
  bitmatch bits with
  | { _: 24: string; (* JMP instruction *)
      oem_name: (8 * 8): string;
      bytes_per_sector: (2 * 8): littleendian;
	  sectors_per_cluster: (1 * 8): littleendian;
      reserved_sectors: (2 * 8): littleendian;
	  number_of_fats: (1 * 8): littleendian;
	  number_of_root_dir_entries: (2 * 8): littleendian;
	  total_sectors_small: (2 * 8): littleendian;
      media_descriptor: (1 * 8): littleendian;
      sectors_per_fat: (2 * 8): littleendian;
      sectors_per_track: (2 * 8): littleendian;
      heads: (2 * 8): littleendian;
      hidden_preceeding_sectors: (4 * 8): littleendian;
      total_sectors_large: (4 * 8): littleendian
    } ->
      printf "OEM: [%s]\n" oem_name;
      printf "bytes_per_sector: %d\n" bytes_per_sector;
      printf "sectors_per_cluster: %d\n" sectors_per_cluster;
      printf "total_sectors_small: %d\n" total_sectors_small;
      printf "total_sectors_large: %ld\n" total_sectors_large;
	  ()
  | { _ } -> failwith "Failed to read a boot sector"

