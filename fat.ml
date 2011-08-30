open Printf

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

  let ints start length =
    let rec enumerate start length acc = match length with
      | 0 -> acc
      | _ -> enumerate (start + 1) (length - 1) (start :: acc) in
    List.rev (enumerate start length [])

  let sectors_of_fat x =
    ints x.reserved_sectors x.sectors_per_fat

  let sectors_of_root_dir x =
    let start = x.reserved_sectors + x.sectors_per_fat * x.number_of_fats in
    let length = (x.number_of_root_dir_entries * 32) / x.bytes_per_sector in
    ints start length
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

module Dir_entry = struct

  type datetime = {
    year: int;
    month: int;
    day: int;
    hours: int;
    mins: int;
    secs: int
  }

  type lfn = {
    lfn_deleted: bool;
    lfn_last: bool; (** marks the highest sequence number *)
    lfn_seq: int;
    (* checksum *)
    lfn_utf16_name: string
  }

  type t = {
    filename: string; (** 8 chars *)
    ext: string;      (** 3 chars *)
    utf_filename: string;
    deleted: bool;
    read_only: bool;
    hidden: bool;
    system: bool;
    volume: bool;
    subdir: bool;
    archive: bool;
    create: datetime;
    access: datetime;
	modify: datetime;
	start_cluster: int;
	file_size: int32;
  }

  type entry =
  | Old of t
  | Lfn of lfn
  | End

  let to_string x =
    let trim_utf16 x =
      let chars = ref (String.length x / 2) in
      for i = 0 to String.length x / 2 - 1 do
        let a = int_of_char x.[i * 2] and b = int_of_char x.[i * 2 + 1] in
        if a = 0xff && b = 0xff && i < !chars then chars := i
      done;
      String.sub x 0 (!chars * 2) in
    Printf.sprintf "%8s %3s %10ld %04d-%02d-%02d  %02d:%02d  %s"
      x.filename x.ext x.file_size
      x.create.year x.create.month x.create.day
      x.create.hours x.create.mins
      (trim_utf16 x.utf_filename)

  let time_of_int date time =
    let day = date land 0b11111 in
    let month = (date lsr 5) land 0b1111 in
    let year = (date lsr 9) + 1980 in
    let secs = (time land 0b11111) * 2 in
    let mins = (time lsr 5) land 0b111111 in
	let hours = (time lsr 10) land 0b11111 in
    { day = day; month = month; year = year;
      hours = hours; mins = mins; secs = secs }
    
  let of_bitstring bits =
    bitmatch bits with
    | { seq: 8;
        utf1: (10 * 8): string;
        0x0f: 8;
        0: 8;
        checksum: 8;
        utf2: (12 * 8): string;
        0: 16;
        utf3: (4 * 8): string
      } ->
      Lfn {
        lfn_deleted = seq land 0x80 = 1;
        lfn_last = seq land 0x40 = 1;
        lfn_seq = seq land 0x3f;
        (* checksum *)
        lfn_utf16_name = utf1 ^ utf2 ^ utf3;
      }
    | { filename: (8 * 8): string;
        ext: (3 * 8): string;
        read_only: 1;
        hidden: 1;
        system: 1;
        volume: 1;
        subdir: 1;
        archive: 1;
        _: 1; (* device *)
        _: 1; (* unused *)
        _: 8; (* reserved *)
        _: 8; (* high precision create time 0-199 in units of 10ms *)
        create_time: 16: littleendian;
		create_date: 16: littleendian;
		last_access_date: 16: littleendian;
		ea_index: 16: littleendian;
		last_modify_time: 16: littleendian;
		last_modify_date: 16: littleendian;
		start_cluster: 16: littleendian;
		file_size: 32: littleendian
      } ->
        let x = int_of_char filename.[0] in
        if x = 0
        then End
        else
          let deleted = x = 0xe5 in
          filename.[0] <- char_of_int (if x = 0x05 then 0xe5 else x);
          Old {
            filename = filename;
            ext = ext;
            utf_filename = "";
            read_only = read_only;
            deleted = deleted;
            hidden = hidden;
            system = system;
            volume = volume;
            subdir = subdir;
            archive = archive;
            create = time_of_int create_date create_time;
            access = time_of_int last_access_date 0;
            modify = time_of_int last_modify_date last_modify_time;
            start_cluster = start_cluster;
            file_size = file_size
          }
    | { _ } ->
      let (s, off, len) = bits in
      failwith (Printf.sprintf "Not a dir entry off=%d len=%d" off len)

    let chop n bits =
      let open Bitstring in
      let rec inner acc bits =
        if bitstring_length bits <= n then bits :: acc
        else inner (takebits n bits :: acc) (dropbits n bits) in
      List.rev (inner [] bits)

    let list bits =
      (* Stop as soon as we find a None *)
      let rec inner lfns acc = function
        | [] -> acc
        | b :: bs -> 
                     begin match of_bitstring b with
                     | Lfn lfn -> inner (lfn :: lfns) acc bs
                     | Old d ->
                       (* reconstruct UTF text from LFNs *)
                       let utfs = List.fold_left (fun acc lfn -> lfn.lfn_utf16_name :: acc) [] lfns in
                       inner [] ({d with utf_filename = String.concat "" utfs} :: acc) bs
                     | End -> acc
                     end in
      inner [] [] (chop (8 * 32) bits)

    (** [sectors_of_file format fat x] returns the list of sectors containing
        data from file [x] according to FAT [fat] which is of type [format].
        Note the last sector may contain undefined data after the file ends. *)
    let sectors_of_file format fat x =
      let open Fat_entry in
      let rec follow_chain acc i = match of_bitstring format i fat with
      | End -> i :: acc
      | Free | Bad -> acc (* corrupt file *)
      | Used j -> follow_chain (i :: acc) j in
      List.rev (follow_chain [] x.start_cluster)
end

module type BLOCK = sig
  val read_sector: int -> Bitstring.t
  val read_sectors: int list -> Bitstring.t
end

module FATFilesystem = functor(B: BLOCK) -> struct
  type t = {
    boot: Boot_sector.t;
    format: format;      (** FAT12, 16 or 32 *)
    fat: Bitstring.t;    (** contains the whole FAT *)
    root: Bitstring.t;   (** contains the root directory *)
  }
  let make () = 
    let boot_sector = B.read_sector 0 in
    let boot = Boot_sector.of_bitstring boot_sector in
    let format = match Boot_sector.detect_format boot with
    | None -> failwith "Failed to detect FAT format"
    | Some format -> format in
    let fat = B.read_sectors (Boot_sector.sectors_of_fat boot) in
    let root = B.read_sectors (Boot_sector.sectors_of_root_dir boot) in
    { boot = boot; format = format; fat = fat; root = root }
end

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
        Unix.lseek f (n * sector_size) Unix.SEEK_SET;
        let results = String.create sector_size in
        really_read f results 0 sector_size;
        Bitstring.bitstring_of_string results
      )

  let read_sectors ss =
    Bitstring.concat (List.map read_sector ss)

end

module Test = FATFilesystem(UnixBlock)

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

  Boot_sector.debug_print fs.Test.boot;
(*
    Printf.printf "FAT:\n";
    let fat = read_sectors (Boot_sector.sectors_of_fat boot) in
    for i = 0 to Boot_sector.clusters boot - 1 do
      let x = Fat_entry.of_bitstring format i fat in
      Printf.printf "%s%!" (Fat_entry.to_string x)
    done;*)
    Printf.printf "Root directory:\n";
    let dirs = Dir_entry.list fs.Test.root in
    List.iter
      (fun x -> Printf.printf "%s\n" (Dir_entry.to_string x)) dirs



