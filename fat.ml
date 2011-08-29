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

let read_sector n =
  Unix.lseek !f (n * sector_size) Unix.SEEK_SET;
  let results = String.create sector_size in
  really_read !f results 0 sector_size;
  results

let read_sectors ss =
  Bitstring.concat (List.map Bitstring.bitstring_of_string (List.map read_sector ss))

type format = FAT12 | FAT16 | FAT32
let string_of_format = function
  | FAT12 -> "FAT12"
  | FAT16 -> "FAT16"
  | FAT32 -> "FAT32"

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
      printf "number of FATs: %d\n" x.number_of_fats;
      printf "number_of_root_dir_entries: %d\n" x.number_of_root_dir_entries;
	  printf "hidden_preceeding_sectors: %ld\n" x.hidden_preceeding_sectors;
      ()

  (** Return the number of clusters *)
  let clusters x =
    let root_start = x.reserved_sectors + x.number_of_fats * x.sectors_per_fat in
    let cluster_start = root_start + (x.number_of_root_dir_entries * 32) / x.bytes_per_sector in
    2 + (Int32.to_int (Int32.div (Int32.sub x.total_sectors (Int32.of_int cluster_start)) (Int32.of_int x.sectors_per_cluster)))

  (* Choose between FAT12, FAT16 and FAT32 using heuristic from:
     http://averstak.tripod.com/fatdox/bootsec.htm *)
  let detect_format x =
    let number_of_clusters = clusters x in
    if number_of_clusters < 4087 then Some FAT12
    else if number_of_clusters < 65527 then Some FAT16
    else if number_of_clusters < 268435457 then Some FAT32
    else None

  let sectors_of_fat x =
    let rec enumerate start length acc = match length with
      | 0 -> acc
      | _ -> enumerate (start + 1) (length - 1) (start :: acc) in
    List.rev (enumerate x.reserved_sectors x.sectors_per_fat [])
end

module Fat_entry = struct
  type t = 
    | Free
    | Used of int (** points to the next in the chain *)
	| End         (** end of a chain *)
    | Bad         (** bad sector or illegal FAT entry *)
  let to_string = function
    | Free -> "F"
    | Used x -> "U"
    | End -> "E"
    | Bad -> "B"

  let of_fat16 n fat =
    bitmatch fat with
      | { x: 16: littleendian, offset(16*n) } ->
	    if x = 0 then Free
        else if x >= 0x0002 && x <= 0xffef then Used x
        else if x >= 0xfff8 && x <= 0xffff then End
        else Bad
      | { _ } -> Bad
  let of_fat32 n fat =
    bitmatch fat with
      | { x: 32: littleendian, offset(32 * n) } ->
        if x = 0l then Free
        else if x >= 0x00000002l && x <= 0x0fffffefl then Used (Int32.to_int x)
        else if x >= 0x0ffffff8l && x <= 0x0fffffffl then End
        else Bad
      | { _ } -> Bad
  let of_fat12 n fat =
    (* 2 entries span groups of 3 bytes *)
    bitmatch fat with
      | { x: 16: littleendian, offset((3 * n)/2) } ->
        let x = if n mod 2 = 0 then x land 0xfff else x lsr 4 in
        if x = 0 then Free
        else if x >= 0x002 && x <= 0xfef then Used x
        else if x >= 0xff8 && x <= 0xfff then End
        else Bad
      | { _ } -> Bad

  (** Return the bitstring containing the nth FAT entry *)
  let of_bitstring format = match format with
    | FAT16 -> of_fat16
    | FAT32 -> of_fat32
    | FAT12 -> of_fat12
end

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
  let bits = Bitstring.bitstring_of_string (read_sector 0) in
  let boot = Boot_sector.of_bitstring bits in
  Boot_sector.debug_print boot;
  let format = Boot_sector.detect_format boot in
  match format with
  | None -> failwith "Failed to detect FAT format"
  | Some format ->
    Printf.printf "Format: %s\n" (string_of_format format);
    let fat = read_sectors (Boot_sector.sectors_of_fat boot) in
    for i = 0 to Boot_sector.clusters boot - 1 do
      let x = Fat_entry.of_bitstring format i fat in
      Printf.printf "%s%!" (Fat_entry.to_string x)
    done



