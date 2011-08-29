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

module Boot_sector = struct
  type t = {
      oem_name: string;
      bytes_per_sector: int;
	  sectors_per_cluster: int;
      reserved_sectors: int;
	  number_of_fats: int;
	  number_of_root_dir_entries: int;
	  total_sectors: int32;
      sectors_per_fat: int;
      hidden_preceeding_sectors: int32;
  }
  let of_bitstring bits =
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
      total_sectors_large: (4 * 8): littleendian;
      0xaa55: 16: littleendian, offset(0x1fe * 8)
    } -> 
    {
      oem_name = oem_name;
      bytes_per_sector = bytes_per_sector;
	  sectors_per_cluster = sectors_per_cluster;
      reserved_sectors = reserved_sectors;
	  number_of_fats = number_of_fats;
	  number_of_root_dir_entries = number_of_root_dir_entries;
	  total_sectors = max (Int32.of_int total_sectors_small) total_sectors_large;
      sectors_per_fat = sectors_per_fat;
      hidden_preceeding_sectors = hidden_preceeding_sectors;
    }
  | { _ } -> failwith "Failed to read a boot sector"

  let debug_print x =
      printf "OEM: [%s]\n" x.oem_name;
      printf "bytes_per_sector: %d\n" x.bytes_per_sector;
      printf "sectors_per_cluster: %d\n" x.sectors_per_cluster;
      printf "total_sectors: %ld\n" x.total_sectors;
	  printf "reserved_sectors: %d\n" x.reserved_sectors;
      printf "number_of_root_dir_entries: %d\n" x.number_of_root_dir_entries;
	  printf "hidden_preceeding_sectors: %ld\n" x.hidden_preceeding_sectors;
      ()
end
(*
module Fat = struct

  let of_bitstring bits =
  bitmatch bits with
  | { _: 24: string; (* JMP instruction *)
*)
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
  let boot = Boot_sector.of_bitstring bits in
  Boot_sector.debug_print boot



