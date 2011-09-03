open Printf

(** [bitstring_is_byte_aligned b] true if the data within [b] is byte aligned *)
let bitstring_is_byte_aligned (_, off, len) = off mod 8 = 0 && (len mod 8 = 0)

(** [bitstring_write src offset dest] modifies the bitstring [dest] by writing
    [src] at [offset] in [dest] *)
let bitstring_write ((src_s, src_off, src_len) as src) offset_bytes ((dest_s, dest_off, dest_len) as dest) =
  (* We don't expect to run off the end of the target bitstring *)
  assert (dest_len - offset_bytes * 8 - src_len >= 0);
  assert (bitstring_is_byte_aligned src);
  assert (bitstring_is_byte_aligned dest);
  String.blit src_s (src_off / 8) dest_s (dest_off / 8 + offset_bytes) (src_len / 8)

(** [bitstring_compare a b] compares the contents of bitstrings *)
let bitstring_compare ((a_s, a_off, a_len) as a) ((b_s, b_off, b_len) as b) =
  (* We don't expect unaligned strings *)
  compare (Bitstring.string_of_bitstring a) (Bitstring.string_of_bitstring b)

module Buf = struct
  type t =
    | Base of Bitstring.t
    | Update of (int * Bitstring.t * t)

  let make x = Base x
  let write x offset bs = Update(offset, bs, x)

  let rec flatten = function
    | Base x -> Bitstring.bitstring_of_string (Bitstring.string_of_bitstring x)
    | Update (offset_bytes, bs, x) ->
      let x' = flatten x in
      bitstring_write bs offset_bytes x';
      x'
end

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

  let ints start length =
    let rec enumerate start length acc = match length with
      | 0 -> acc
      | _ -> enumerate (start + 1) (length - 1) (start :: acc) in
    List.rev (enumerate start length [])

  (** Return the sector number of the first cluster *)
  let initial_cluster x =
    let root_start = x.reserved_sectors + x.number_of_fats * x.sectors_per_fat in
    root_start + (x.number_of_root_dir_entries * 32) / x.bytes_per_sector

  (** Return a list of sectors corresponding to cluster n *)
  let sectors_of_cluster x n =
    (* NB clusters 0 and 1 are not on disk *)
    ints (initial_cluster x + x.sectors_per_cluster * (n - 2))	 x.sectors_per_cluster

  (** Return the number of clusters *)
  let clusters x =
    let cluster_start = initial_cluster x in
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
  let to_fat16 n fat x =
    let x' = match x with
    | Free -> 0 | End -> 0xffff | Bad -> 0xfff7 | Used x -> x in
    let bs = BITSTRING {
      x' : 16 : littleendian
    } in
    Buf.write (Buf.make fat) (2 * n) bs

  (* TESTING only *)
  let of_fat16 n fat =
    let x = of_fat16 n fat in
    let fat' = Buf.flatten (to_fat16 n fat x) in
    if bitstring_compare fat fat' <> 0 then begin
      Printf.printf "before =\n";
      Bitstring.hexdump_bitstring stdout fat;
      Printf.printf "after =\n";
      Bitstring.hexdump_bitstring stdout fat';
    end;
    x
  let of_fat32 n fat =
    bitmatch fat with
      | { x: 32: littleendian, offset(32 * n) } ->
        if x = 0l then Free
        else if x >= 0x00000002l && x <= 0x0fffffefl then Used (Int32.to_int x)
        else if x >= 0x0ffffff8l && x <= 0x0fffffffl then End
        else Bad
      | { _ } -> Bad
  let to_fat32 n fat x = failwith "Unimplemented"
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
  let to_fat12 n fat x = failwith "Unimplemented"

  (** Return the bitstring containing the nth FAT entry *)
  let of_bitstring format = match format with
    | FAT16 -> of_fat16
    | FAT32 -> of_fat32
    | FAT12 -> of_fat12

  (** Return the bitstring describing the FAT delta and the offset within
      the FAT table. *)
  let to_bitstring format = match format with
    | FAT16 -> to_fat16
    | FAT32 -> to_fat32
    | FAT12 -> to_fat12

  (** [follow_chain format fat cluster] returns the list of sectors containing
      data according to FAT [fat] which is of type [format]. *)
  let follow_chain format fat cluster =
    let rec inner acc i = match of_bitstring format i fat with
    | End -> i :: acc
    | Free | Bad -> acc (* corrupt file *)
    | Used j -> inner (i :: acc) j in
    List.rev (inner [] cluster)

  (** [find_free_from boot format fat start] returns an unallocated cluster
      after [start] *)
  let find_free_from boot format fat start =
    let n = Boot_sector.clusters boot in
    let rec inner i =
      if i = n then None
      else match of_bitstring format i fat with
      | Free -> Some i
      | _ -> inner (i + 1) in
    inner start

  (** [allocate boot format fat] allocates a free cluster suitable for a
      new file *)
  let allocate boot format fat =
    match find_free_from boot format fat 0 with
    | Some start ->
      Some [ to_bitstring format start fat End ]
    | None -> None
 
  (** [extend boot format fat last] allocates a free cluster and extends
      the chain whose last element is [last] *)
  let extend boot format fat last =
    match find_free_from boot format fat last with
    | Some next ->
      Some [
        to_bitstring format next fat End;
        to_bitstring format last fat (Used next);
      ]
    | None -> None
end

module Dir_entry = struct

  type datetime = {
    year: int;
    month: int;
    day: int;
    hours: int;
    mins: int;
    secs: int;
    ms: int;
  }

  type lfn = {
    lfn_deleted: bool;
    lfn_last: bool; (** marks the highest sequence number *)
    lfn_seq: int;
    lfn_checksum: int;
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
    Printf.sprintf "%-8s %-3s %10s %04d-%02d-%02d  %02d:%02d  %s"
      x.filename x.ext
      (if x.subdir then "<DIR>     " else (Printf.sprintf "%10ld" x.file_size))
      x.create.year x.create.month x.create.day
      x.create.hours x.create.mins
      (trim_utf16 x.utf_filename)

  let int_to_hms time =
    let hours = ((time lsr 11) land 0b11111) in
    let mins = (time lsr 5) land 0b111111 in
    let secs = (time land 0b11111) * 2 in
    hours, mins, secs

  let hms_to_int (hours, mins, secs) =
    let h = (hours land 0b11111) lsl 11 in
    let m = (mins land 0b111111) lsl 5 in
    let s = ((secs/2) land 0b11111) in
    h lor m lor s

  let f x = hms_to_int (int_to_hms x)

  let int_of_time time = hms_to_int (time.hours, time.mins, time.secs)

  let time_of_int date time ms =
    let day = date land 0b11111 in
    let month = (date lsr 5) land 0b1111 in
    let year = (date lsr 9) + 1980 in
    let hours, mins, secs = int_to_hms time in
    { day = day; month = month; year = year;
      hours = hours; mins = mins; secs = secs; ms = ms }

  let int_of_date x =
    let d = x.day land 0b11111 in
    let m = (x.month land 0b1111) lsl 5 in
    let y = (x.year - 1980) lsl 9 in
    d lor m lor y

  let remove_padding p x =
    let rec inner = function
      | -1 -> x
      | n when x.[n] = p -> inner (n-1)
      | n -> String.sub x 0 (n + 1) in
    inner (String.length x - 1)

  let add_padding p n x =
    if String.length x >= n then x
    else
      let y = String.make n p in
      String.blit x 0 y 0 (String.length x);
      y

  (** Returns the checksum corresponding to the 8.3 DOS filename *)
  let compute_checksum x =
    let y = add_padding ' ' 8 x.filename ^ (add_padding ' ' 3 x.ext) in
    let rec inner sum i =
      if i = String.length y then sum
      else
	let sum' = (sum land 1) lsl 7 + (sum lsr 1) + (int_of_char y.[i]) in
	inner sum' (i + 1) in
    (inner 0 0) land 0xff

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
        lfn_deleted = seq land 0x80 = 0x80;
        lfn_last = seq land 0x40 = 0x40;
        lfn_seq = seq land 0x3f;
	lfn_checksum = checksum;
        lfn_utf16_name = utf1 ^ utf2 ^ utf3;
      }
    | { filename: (8 * 8): string;
        ext: (3 * 8): string;
        _: 1; (* unused *)
        _: 1; (* device *)
        archive: 1;
        subdir: 1;
        volume: 1;
        system: 1;
        hidden: 1;
        read_only: 1;
        _: 8; (* reserved *)
        create_time_ms: 8; (* high precision create time 0-199 in units of 10ms *)
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
            filename = remove_padding ' ' filename;
            ext = remove_padding ' ' ext;
            utf_filename = "";
            read_only = read_only;
            deleted = deleted;
            hidden = hidden;
            system = system;
            volume = volume;
            subdir = subdir;
            archive = archive;
            create = time_of_int create_date create_time create_time_ms;
            access = time_of_int last_access_date 0 0;
            modify = time_of_int last_modify_date last_modify_time 0;
            start_cluster = start_cluster;
            file_size = file_size
          }
    | { _ } ->
      let (s, off, len) = bits in
      failwith (Printf.sprintf "Not a dir entry off=%d len=%d" off len)

    let to_bitstring = function
      | End ->
	let zeroes = String.make 32 (char_of_int 0) in
	BITSTRING {
	  zeroes: (32 * 8): string
	}
      | Lfn l ->
	let seq = l.lfn_seq lor (if l.lfn_last then 0x40 else 0) lor (if l.lfn_deleted then 0x80 else 0) in
	let utf = add_padding (char_of_int 0xff) 26 l.lfn_utf16_name in
	let utf1 = String.sub utf 0 10 in
	let utf2 = String.sub utf 10 12 in
	let utf3 = String.sub utf 22 4 in
	let checksum = 0 in (* XXX **)
	BITSTRING {
	  seq: 8;
          utf1: (10 * 8): string;
          0x0f: 8;
          0: 8;
          checksum: 8;
          utf2: (12 * 8): string;
          0: 16;
          utf3: (4 * 8): string
	}
      | Old x ->
	let filename = add_padding ' ' 8 x.filename in
	let ext = add_padding ' ' 3 x.ext in
	let create_time_ms = x.create.ms in
	let create_time = int_of_time x.create in
	let create_date = int_of_date x.create in
	let last_access_date = int_of_date x.access in
	let last_modify_time = int_of_time x.modify in
	let last_modify_date = int_of_date x.modify in
	
	BITSTRING {
	  filename: (8 * 8): string;
          ext: (3 * 8): string;
          false: 1; (* unused *)
          false: 1; (* device *)
          x.archive: 1;
          x.subdir: 1;
          x.volume: 1;
          x.system: 1;
          x.hidden: 1;
          x.read_only: 1;
          0: 8; (* reserved *)
          create_time_ms: 8; (* high precision create time 0-199 in units of 10ms *)
          create_time: 16: littleendian;
          create_date: 16: littleendian;
	  last_access_date: 16: littleendian;
	  0: 16: littleendian;
	  last_modify_time: 16: littleendian;
	  last_modify_date: 16: littleendian;
	  x.start_cluster: 16: littleendian;
	  x.file_size: 32: littleendian
	}

    let chop n bits =
      let module B = Bitstring in
      let rec inner acc bits =
        if B.bitstring_length bits <= n then bits :: acc
        else inner (B.takebits n bits :: acc) (B.dropbits n bits) in
      List.rev (inner [] bits)

    let list bits =
      (* Stop as soon as we find a None *)
      let rec inner lfns acc = function
        | [] -> acc
        | b :: bs ->
          begin match of_bitstring b with
            | Lfn lfn -> inner (lfn :: lfns) acc bs
            | Old d ->
	      (* TESTING ONLY *)
              let b' = to_bitstring (Old d) in
	      if bitstring_compare b b' <> 0 then begin
                Printf.printf "On disk:\n";
		Bitstring.hexdump_bitstring stdout b;
		Printf.printf "Regenerated:\n";
		Bitstring.hexdump_bitstring stdout b'
	      end;
                       (* reconstruct UTF text from LFNs *)
	      let lfns = List.sort (fun a b -> compare a.lfn_seq b.lfn_seq) lfns in
              let utfs = List.rev (List.fold_left (fun acc lfn -> lfn.lfn_utf16_name :: acc) [] lfns) in
              inner [] ({d with utf_filename = String.concat "" utfs} :: acc) bs
            | End -> acc
          end in
      inner [] [] (chop (8 * 32) bits)

    let ascii_to_utf16 x =
      let l = String.length x in
      (* round up to next multiple of 13 *)
      let padto = (l + 1 + 12) / 13 * 13 in
      let total = max (l + 1) padto in (* NULL *)
      let results = String.make (total * 2) (char_of_int 0xff) in
      for i = 0 to l - 1 do
        results.[i*2] <- x.[i];
        results.[i*2+1] <- char_of_int 0;
      done;
      results.[l*2] <- char_of_int 0;
      results.[l*2+1] <- char_of_int 0;
      results

    (** [find name list] returns [Some d] where [d] is a Dir_entry.t with
        name [name] (or None) *)
    let find name list =
      let utf_name = ascii_to_utf16 name in
      let dos_name = name in (* XXX *)
      let rec inner = function
      | [] -> None
      | x :: xs ->
        let dos_filename = x.filename ^ "." ^ x.ext in
        if dos_filename = dos_name then Some x
        else if x.utf_filename = utf_name then Some x
        else inner xs in
      inner list
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

  type find_result =
    | Not_a_directory of string list
    | No_directory_entry of string list * string
    | Dir of Dir_entry.t list
    | File of Dir_entry.t

  let read_file x { Dir_entry.start_cluster = cluster; file_size = file_size; subdir = subdir } =
    let chain = Fat_entry.follow_chain x.format x.fat cluster in
    Printf.printf "chain = [ %s ]\n%!" (String.concat "; " (List.map string_of_int chain));
    let sectors = List.concat (List.map (Boot_sector.sectors_of_cluster x.boot) chain) in
    Printf.printf "sectors = [ %s ]\n%!" (String.concat "; " (List.map string_of_int sectors));
    let all = B.read_sectors sectors in
    if subdir then all else Bitstring.subbitstring all 0 (Int32.to_int file_size * 8)

  (** [find x path] returns a [find_result] corresponding to the object
      stored at [path] *)
  let find x path =
    let readdir = function
      | Dir ds -> ds
      | File d -> Dir_entry.list (read_file x d)
      | _ -> assert false in
    let rec inner sofar current = function
    | [] ->
      begin match current with
      | Dir ds -> Dir ds
      | File { Dir_entry.subdir = true } -> Dir (readdir current)
      | File ({ Dir_entry.subdir = false } as d) -> File d
      | _ -> assert false
      end
    | p :: ps ->
      let entries = readdir current in
      begin match Dir_entry.find p entries, ps with
      | Some { Dir_entry.subdir = false }, _ :: _ ->
        Not_a_directory (List.rev (p :: sofar))
      | Some d, _ ->
        inner (p::sofar) (File d) ps
      | None, _ ->
        No_directory_entry (List.rev sofar, p)
      end in
    inner [] (Dir (Dir_entry.list x.root)) path    
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
        ignore(Unix.lseek f (n * sector_size) Unix.SEEK_SET);
        let results = String.create sector_size in
        really_read f results 0 sector_size;
        Bitstring.bitstring_of_string results
      )

  let read_sectors ss =
    Bitstring.concat (List.map read_sector ss)

end

module Test = FATFilesystem(UnixBlock)

module Stringext = struct
open String

let of_char c = String.make 1 c

let fold_right f string accu =
        let accu = ref accu in
        for i = length string - 1 downto 0 do
                accu := f string.[i] !accu
        done;
        !accu

let explode string =
        fold_right (fun h t -> h :: t) string []

let implode list =
        concat "" (List.map of_char list)

(** True if string 'x' ends with suffix 'suffix' *)
let endswith suffix x =
        let x_l = String.length x and suffix_l = String.length suffix in
        suffix_l <= x_l && String.sub x (x_l - suffix_l) suffix_l = suffix

(** True if string 'x' starts with prefix 'prefix' *)
let startswith prefix x =
        let x_l = String.length x and prefix_l = String.length prefix in
        prefix_l <= x_l && String.sub x 0 prefix_l  = prefix

(** Returns true for whitespace characters, false otherwise *)
let isspace = function
        | ' ' | '\n' | '\r' | '\t' -> true
        | _ -> false

(** Removes all the characters from the ends of a string for which the predicate is true *)
let strip predicate string =
        let rec remove = function
        | [] -> []
        | c :: cs -> if predicate c then remove cs else c :: cs in
        implode (List.rev (remove (List.rev (remove (explode string)))))

let rec split ?limit:(limit=(-1)) c s =
        let i = try String.index s c with Not_found -> -1 in
        let nlimit = if limit = -1 || limit = 0 then limit else limit - 1 in
        if i = -1 || nlimit = 0 then
                [ s ]
        else
                let a = String.sub s 0 i
                and b = String.sub s (i + 1) (String.length s - i - 1) in
                a :: (split ~limit: nlimit c b)

end

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

  let cwd = ref [] in
  let path_to_string p = "/" ^ (String.concat "/" p) in
  let string_to_path s = if s = "/" then [] else Stringext.split '/' s in
  let abspath dir =
    if dir = "" then !cwd
    else if dir.[0] = '/' then (string_to_path dir)
    else !cwd @ (string_to_path dir) in
  let module T = Test in
  let do_dir dir =
    let path = abspath dir in
    match T.find fs path with
    | T.Not_a_directory _ -> Printf.printf "Not a directory.\n%!"
    | T.No_directory_entry (path, name) -> Printf.printf "No directory %s in %s\n%!" name (path_to_string path)
    | T.Dir dirs ->
      Printf.printf "Directory for A:%s\n\n" (path_to_string path);
      List.iter
        (fun x -> Printf.printf "%s\n" (Dir_entry.to_string x)) dirs;
      Printf.printf "%9d files\n%!" (List.length dirs)
    | T.File _ -> Printf.printf "Not a directory.\n%!" in
  let do_type file =
    let path = abspath file in
    match T.find fs path with
    | T.Not_a_directory _ -> Printf.printf "Not a directory.\n%!"
    | T.No_directory_entry (path, name) -> Printf.printf "File (%s) not found (in %s)\n%!" name (path_to_string path)
    | T.Dir dirs ->
      Printf.printf "Is a directory.\n%!";
    | T.File d ->
      Printf.printf "File starts at cluster: %d; has length = %ld\n%!" (d.Dir_entry.start_cluster) (d.Dir_entry.file_size);
      let data = T.read_file fs d in
      Printf.printf "%s\n%!" (Bitstring.string_of_bitstring data) in
  let do_cd dir =
    let path = abspath dir in
    Printf.printf "path = [%s]\n%!" (String.concat ";" path);
    match T.find fs path with
    | T.Not_a_directory _ -> Printf.printf "Not a directory.\n%!"
    | T.No_directory_entry (path, name) -> Printf.printf "No directory %s in %s\n%!" name (path_to_string path)
    | T.Dir _ ->
      cwd := (string_to_path dir);
    | T.File _ -> Printf.printf "Not a directory.\n%!" in

  let finished = ref false in
  while not !finished do
    Printf.printf "A:%s> %!" (path_to_string !cwd);
    match Stringext.split ~limit:2 ' ' (input_line stdin) with
    | [ "dir" ] -> do_dir ""
    | [ "dir"; path ] -> do_dir path
    | [ "cd"; path ] -> do_cd path
    | [ "type"; path ] -> do_type path
    | [ "exit" ] -> finished := true
    | [] -> ()
    | cmd :: _ -> Printf.printf "Unknown command: %s\n%!" cmd
  done;

  Boot_sector.debug_print fs.Test.boot;
(*
    Printf.printf "FAT:\n";
    let fat = read_sectors (Boot_sector.sectors_of_fat boot) in
    for i = 0 to Boot_sector.clusters boot - 1 do
      let x = Fat_entry.of_bitstring format i fat in
      Printf.printf "%s%!" (Fat_entry.to_string x)
    done;*)
    Printf.printf "Root directory:\n";




