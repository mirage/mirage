(* This contains the FAT-specific library stuff *)

(** Instances of SectorMap will map virtual sectors within a file to physical
    sector numbers on disk *)
module SectorMap = struct
  include Map.Make(struct type t = int let compare = compare end)

  let make sectors =
    fst (List.fold_left (fun (m, i) o -> add i o m, i + 1) (empty,0) sectors)

  (** [find x sector] returns the physical address on disk corresponding to the
      virtual sector [sector] according to SectorMap [x] *)
  let find (x: int t) sector =
    if not (mem sector x) then failwith "fault";
    find sector x

  (** [transform_offset x sector_size vaddr] returns the physical address on disk
     corresponding to virtual address [vaddr] according to SectorMap [x] *)
  let transform_offset (x: int t) sector_size vaddr =
    let s = Int64.of_int sector_size in
    let vsector = Int64.(div vaddr s) in
    let psector = find x (Int64.to_int vsector) in
    let voffset = Int64.(sub vaddr (mul vsector s)) in
    Int64.(add voffset (mul (of_int psector) s))
end

module Update = struct
  type t = { offset: int64; data: Bitstring.t }

  let to_string x = Printf.sprintf "Update[offset=%Ld length=%d]" x.offset (Bitstring.bitstring_length x.data / 8)

  let hexdump x = Printf.printf "%s:\n%!" (to_string x); Bitstring.hexdump_bitstring stdout x.data

  let make offset data = { offset = offset; data = data }
  let move offset x = { x with offset = Int64.add x.offset offset }

  (** [total_length x] returns the minimum size of the buffer needed to apply this update. *)
  let total_length x = Int64.add x.offset (Int64.of_int (Bitstring.bitstring_length x.data / 8))

  let apply bs x =
    let result = Bitstring.bitstring_of_string (Bitstring.string_of_bitstring bs) in
    Bitstring.bitstring_write x.data (Int64.to_int x.offset) result;
    result

  (** [clip x offset length] returns the fraction of the update between
      [offset] and [offset+length] in bytes *)
  let clip x offset length =
    let new_offset = max x.offset offset in
    let drop_bytes_from_start = Int64.(to_int(sub new_offset x.offset)) in
    let original_end = Int64.(add x.offset (of_int (Bitstring.bitstring_length x.data * 8))) in
    let proposed_end = Int64.(add offset (of_int length)) in
    let new_end = min original_end proposed_end in
    let new_length = Int64.(to_int(sub new_end new_offset)) in
    { offset = new_offset; data = Bitstring.bitstring_clip x.data (8 * drop_bytes_from_start) (8 * new_length) }

  let is_empty x = Bitstring.equals Bitstring.empty_bitstring x.data

  (** [split x sector_size] returns [x] as a sequence of consecutive updates,
      each of which corresponds to a region of length [sector_size]. Note empty
      updates are omitted. *)
  let split x sector_size =
    let rec inner acc start =
      if Int64.(add x.offset (mul 8L (of_int (Bitstring.bitstring_length x.data)))) <= start
      then List.rev acc
      else
	let this = clip x start sector_size in
	let new_start = Int64.(add start (of_int sector_size)) in
	inner (if is_empty this then acc else this :: acc) new_start in
    inner [] 0L

  (** [map_updates xs offsets] takes a sequence of virtual sector updates (eg within the
      virtual address space of a file) and a sequence of physical offsets (eg the
      location of physical sectors on disk) and returns a sequence of physical
      sector updates. *)
  let map_updates xs sectors sector_size =
    let m = SectorMap.make sectors in
    List.map (fun x -> { x with offset = SectorMap.transform_offset m sector_size x.offset}) xs
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
      Printf.printf "OEM: [%s]\n" x.oem_name;
      Printf.printf "bytes_per_sector: %d\n" x.bytes_per_sector;
      Printf.printf "sectors_per_cluster: %d\n" x.sectors_per_cluster;
      Printf.printf "total_sectors: %ld\n" x.total_sectors;
      Printf.printf "reserved_sectors: %d\n" x.reserved_sectors;
      Printf.printf "number of FATs: %d\n" x.number_of_fats;
      Printf.printf "number_of_root_dir_entries: %d\n" x.number_of_root_dir_entries;
      Printf.printf "hidden_preceeding_sectors: %ld\n" x.hidden_preceeding_sectors;
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
    Update.make (Int64.of_int (2 * n)) bs

  (* TESTING only *)
  let of_fat16 n fat =
    let x = of_fat16 n fat in
    let fat' = Update.apply fat (to_fat16 n fat x) in
    if Bitstring.compare fat fat' <> 0 then begin
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
  let to_fat32 n fat x =
    let x' = match x with
      | Free -> 0l | End -> 0x0fffffffl | Bad -> 0x0ffffff7l | Used x -> Int32.of_int x in
    let bs = BITSTRING {
      x' : 32 : littleendian
    } in
    Update.make (Int64.of_int (4 * n)) bs
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

  module IntSet = Set.Make(struct type t = int let compare = compare end)

  (** [follow_chain format fat cluster] returns the list of sectors containing
      data according to FAT [fat] which is of type [format]. *)
  let follow_chain format fat cluster =
    (* the elements will be returned in order as 'list'; 'set' is used to
       check that we aren't going round in an infinite loop. *)
    let rec inner (list, set) = function
      | 0 -> list (* either zero-length chain if list = [] or corrupt file *)
      | 1 -> list (* corrupt file *)
      | i -> begin match of_bitstring format i fat with
	  | End -> i :: list
	  | Free | Bad -> list (* corrupt file *)
	  | Used j ->
	    if IntSet.mem i set
	    then list (* infinite loop: corrupt file *)
	    else inner (i :: list, IntSet.add i set) j
      end in
    List.rev (inner ([], IntSet.empty) cluster)

  let initial = 2 (* first valid entry *)

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

  (** [extend boot format fat last n] allocates [n] free clusters to extend
      the chain whose current end is [last] *)
  let extend boot format fat (last: int option) n =
    let rec inner acc start = function
      | 0 -> acc (* in reverse disk order *)
      | i ->
	match find_free_from boot format fat start with
	  | None -> acc (* out of space *)
	  | Some c -> inner (c :: acc) (c + 1) (i - 1) in
    let to_allocate = inner [] (match last with None -> initial | Some x -> x) n in
    if n = 0
    then [], []
    else
      if List.length to_allocate <> n
      then [], [] (* allocation failed *)
      else
	let final = List.hd to_allocate in
	let to_allocate = List.rev to_allocate in
	let updates = fst(List.fold_left (fun (acc, last) next ->
	  (match last with
	    | Some last ->
	      to_bitstring format last fat (Used next) :: acc
	    | None -> acc), Some next
	) ([], last) to_allocate) in

	to_bitstring format final fat End :: updates (* reverse order *), to_allocate
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
  let epoch = {
    year = 1980; month = 0; day = 0;
    hours = 0; mins = 0; secs = 0; ms = 0;
  }

  (** Long filename entry: the same size as an original DOS disk entry *)
  type lfn = {
    lfn_deleted: bool;
    lfn_last: bool; (** marks the highest sequence number *)
    lfn_seq: int;
    lfn_checksum: int;
    lfn_utf16_name: string
  }

  (** A DOS disk entry *)
  type dos = {
    filename: string; (** 8 chars *)
    ext: string;      (** 3 chars *)
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

  (** Useful for streaming entries to/from the disk *)
  type single_entry =
  | Dos of dos
  | Lfn of lfn
  | End

  (** A high-level directory entry, complete with reconstructed UTF name and
      offsets of each individual entry on the disk *)
  type r = {
    utf_filename: string;
    dos: int * dos;
    lfns: (int * lfn) list;
  }

  (* Make the tree more uniform by creating a "fake root" node above the
     root directory entries *)
  let fake_root_entry = {
    utf_filename = "";
    dos = 0, {
      filename = ""; ext = ""; deleted = false; read_only = false;
      hidden = false; system = false; volume = false; subdir = true; archive = false;
      create = epoch; access = epoch; modify = epoch; start_cluster = 0; file_size = 0l
    };
    lfns = []
  }

  let remove_padding x =
    let rec inner = function
      | -1 -> x
      | n when x.[n] = ' ' -> inner (n-1)
      | n -> String.sub x 0 (n + 1) in
    inner (String.length x - 1)

  let file_size_of r = (snd r.dos).file_size
  let deleted r = (snd r.dos).deleted
  let filename_of r =
    if r.lfns <> []
    then r.utf_filename
    else
      let d = snd(r.dos) in
      (remove_padding d.filename) ^ "." ^ (remove_padding d.ext)

  let to_single_entries r =
    List.rev ((Dos (snd r.dos)) :: (List.map (fun l -> Lfn (snd l)) r.lfns))

  let legal_dos_char = function
    | 'A' .. 'Z'
    | '0' .. '9'
    | ' '
    | '!' | '#' | '$' | '%' | '&' | '\'' | '(' | ')' 
    | '-' | '@' | '^' | '_' | '`' | '{'  | '}' | '~' -> true
    | c -> int_of_char c >= 128

  let legal_dos_string x = String.fold_right (fun c sofar -> sofar && (legal_dos_char c)) x true

  let is_legal_dos_name filename = match String.split '.' filename with
    | [ one ] -> String.length one <= 8 && (legal_dos_string one)
    | [ one; two ] -> String.length one <= 8 && (String.length two <= 3) && (legal_dos_string one) && (legal_dos_string two)
    | _ -> false

  let add_padding p n x =
    if String.length x >= n then x
    else
      let y = String.make n p in
      String.blit x 0 y 0 (String.length x);
      y

  let dos_name_of_filename filename =
    if is_legal_dos_name filename
    then match String.split '.' filename with
      | [ one ] -> add_padding ' ' 8 one, "   "
      | [ one; two ] -> add_padding ' ' 8 one, add_padding ' ' 3 two
      | _ -> assert false (* implied by is_legal_dos_name *)
    else
      let all = String.uppercase (Digest.to_hex (Digest.string filename)) in
      let base = String.sub all 0 8 in
      let ext = String.sub all 8 3 in
      base, ext

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

  (** Returns the checksum corresponding to the 8.3 DOS filename *)
  let compute_checksum x =
    let y = add_padding ' ' 8 x.filename ^ (add_padding ' ' 3 x.ext) in
    let rec inner sum i =
      if i = String.length y then sum
      else
	(* In [*] below: note the algorithm given by wikipedia uses arithmetic
	   modulo 256 to make things less obvious than using natural numbers. *)
	let sum' = (sum land 1) lsl 7 + ((sum (* [*] *) land 0xff) lsr 1) + (int_of_char y.[i]) in
	inner sum' (i + 1) in
    (inner 0 0) land 0xff

  let make ?(read_only=false) ?(system=false) ?(subdir=false) filename =
    (* entries with file size 0 should have start cluster 0 *)
    let start_cluster = 0 and file_size = 0l in
    let filename', ext = dos_name_of_filename filename in
    let dos = {
      filename = filename';
      ext = ext;
      deleted = false;
      read_only = read_only;
      hidden = false;
      system = system;
      volume = false;
      subdir = subdir;
      archive = false;
      create = epoch;
      access = epoch;
      modify = epoch;
      start_cluster = start_cluster;
      file_size = file_size
    } in
    let checksum = compute_checksum dos in
    let lfns =
      if is_legal_dos_name filename
      then []
      else
        (* chop filename into 13 character / 26 byte chunks *)
	let padded_utf16 = ascii_to_utf16 filename in
	let rec inner acc seq i =
	  let last = i + 26 = String.length padded_utf16 in
	  let finished = i + 26 > String.length padded_utf16 in
	  if finished then acc
	  else
	    let chunk = String.sub padded_utf16 i 26 in
	    let lfn = {
	      lfn_deleted = false;
	      lfn_last = last;
	      lfn_seq = seq;
	      lfn_checksum = checksum;
	      lfn_utf16_name = chunk;
	    } in
	    inner (lfn :: acc) (seq + 1) (i + 26) in
	inner [] 1 0 in
    {
      utf_filename = filename;
      dos = 0, dos;
      lfns = List.map (fun l -> 0, l) lfns
    }

  let _ =
    let checksum_tests = [
      make "MAKEFILE", 193;
      make "FAT.ML", 223;
    ] in
    List.iter (fun (d, expected) ->
      let d = snd d.dos in
      let checksum = compute_checksum d in
      if checksum <> expected then failwith (Printf.sprintf "checksum_tests: %s.%s expected=%d actual=%d" d.filename d.ext expected checksum)
    ) checksum_tests

  let to_string x =
    let trim_utf16 x =
      let chars = ref (String.length x / 2) in
      for i = 0 to String.length x / 2 - 1 do
        let a = int_of_char x.[i * 2] and b = int_of_char x.[i * 2 + 1] in
        if a = 0xff && b = 0xff && i < !chars then chars := i
      done;
      String.sub x 0 (!chars * 2) in
    let d = snd x.dos in
    Printf.sprintf "%-8s %-3s %10s %04d-%02d-%02d  %02d:%02d  %s"
      d.filename d.ext
      (if d.subdir then "<DIR>     " else (Printf.sprintf "%10ld" d.file_size))
      d.create.year d.create.month d.create.day
      d.create.hours d.create.mins
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
          Dos {
            filename = remove_padding filename;
            ext = remove_padding ext;
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
      if len = 0
      then End
      else failwith (Printf.sprintf "Not a dir entry off=%d len=%d" off len)

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
	let checksum = l.lfn_checksum in
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
      | Dos x ->
	let filename = add_padding ' ' 8 x.filename in
	let y = int_of_char filename.[0] in
        filename.[0] <- char_of_int (if y = 0xe5 then 0x05 else y);
	if x.deleted then filename.[0] <- char_of_int 0xe5;
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

    let entry_size = 32 (* bytes *)

    (** [blocks bits] returns the directory chopped into individual bitstrings,
	each one containing a possible Dir_entry (fragment) *)
    let blocks bits =
      let list = Bitstring.bitstring_chop (8 * entry_size) bits in
      List.rev (fst (List.fold_left (fun (acc, offset) bs -> ((offset, bs)::acc, offset + entry_size)) ([], 0) list))

    (** [fold f initial bits] folds [f acc offset dir_entry] across all the
        reconstructed directory entries contained in bits. *)
    let fold f initial bits =
      (* Stop as soon as we find a None *)
      let rec inner lfns acc = function
        | [] -> acc
        | (offset, b) :: bs ->
          begin match of_bitstring b with
	    | Dos { deleted = true }
	    | Lfn { lfn_deleted = true } -> inner lfns acc bs

            | Lfn lfn -> inner ((offset, lfn) :: lfns) acc bs
            | Dos d ->
	      let expected_checksum = compute_checksum d in
	      (* TESTING ONLY *)
              let b' = to_bitstring (Dos d) in
	      if Bitstring.compare b b' <> 0 then begin
                Printf.printf "On disk:\n";
		Bitstring.hexdump_bitstring stdout b;
		Printf.printf "Regenerated:\n";
		Bitstring.hexdump_bitstring stdout b'
	      end;
                       (* reconstruct UTF text from LFNs *)
	      let lfns = List.sort (fun a b -> compare (snd a).lfn_seq (snd b).lfn_seq) lfns in
	      List.iter
		(fun (_, l) -> if l.lfn_checksum <> expected_checksum then begin
		  Printf.printf "Filename: %s.%s; expected_checksum = %d; actual = %d\n%!" d.filename d.ext expected_checksum l.lfn_checksum
		end) lfns;
              let utfs = List.rev (List.fold_left (fun acc (_, lfn) -> lfn.lfn_utf16_name :: acc) [] lfns) in
	      let reconstructed = {
		utf_filename = String.concat "" utfs;
		dos = offset, d;
		lfns = lfns;
	      } in
	      let acc' = f acc offset reconstructed in
              inner [] acc' bs
            | End -> acc
          end in
      inner [] initial (blocks bits)

    (** [list bits] returns a list of valid (not deleted) directory entries
        contained within the directory [bits] *)
    let list = fold (fun acc _ d -> d :: acc) []

    (** [next bits] returns the bit offset of a free directory slot. Note this
        function does not recycle deleted elements. *)
    let next bits =
      let rec inner offset = function
        | [] -> None
        | b :: bs ->
          begin match of_bitstring b with
            | End -> Some offset
            | _ -> inner (8 * 32 + offset) bs
          end in
      inner 0 (Bitstring.bitstring_chop (8 * 32) bits)

    (** [add block t] return the update required to add [t] to the directory [block].
        Note the update may be beyond the end of [block] indicating more space needs 
        to be allocated. *)
    let add block r =
      let after_block = Bitstring.bitstring_length block in
      let next_bit = match next block with
	| Some b -> b
	| None -> after_block in
      let dir_entries = to_single_entries r in
      let bits = Bitstring.concat (List.map to_bitstring dir_entries) in
      [ Update.make (Int64.of_int (next_bit / 8)) bits ]

    let name_match name x =
      let utf_name = ascii_to_utf16 name in
      let d = snd x.dos in
      let d_filename = remove_padding d.filename in
      let d_ext = remove_padding d.ext in
      if is_legal_dos_name name
      then begin
	let filename, ext = dos_name_of_filename name in
	let filename = remove_padding filename and ext = remove_padding ext in
	filename = d_filename && ext = d_ext
      end else
	utf_name = x.utf_filename || name = x.utf_filename

    (** [find name list] returns [Some d] where [d] is a Dir_entry.t with
        name [name] (or None) *)
    let find name list =
      try Some (List.find (name_match name) list) with Not_found -> None

    let remove block filename =
      match find filename (list block) with
	| Some r ->
	  let offsets = fst r.dos :: (List.map fst r.lfns) in
	  List.rev (List.fold_left
	    (fun acc offset ->
	      let b = Bitstring.takebits (8 * entry_size) (Bitstring.dropbits (8 * offset) block) in
	      let update = match of_bitstring b with
		| Lfn lfn ->
		  let lfn' = { lfn with lfn_deleted = true } in
		  Update.make (Int64.of_int offset) (to_bitstring (Lfn lfn'))
		| Dos dos ->
		  let dos' = { dos with deleted = true } in
		  Update.make (Int64.of_int offset) (to_bitstring (Dos dos'))
		| End -> assert false
	      in
	      update :: acc
	    ) [] offsets)
	| None -> [] (* no updates implies nothing to remove *)

    let modify block filename file_size start_cluster =
      fold (fun acc offset x ->
	if name_match filename x
	then
	  let offset, dos = x.dos in
	  let dos' = { dos with file_size = file_size; start_cluster = start_cluster } in
	  (Update.make (Int64.of_int offset) (to_bitstring (Dos dos'))) :: acc
	else acc
      ) [] block
end

module Path = (struct
  type t = string list (* stored in reverse order *)
  let of_string_list x = List.rev x
  let to_string_list x = List.rev x

  let directory = List.tl
  let filename = List.hd

  let to_string p = "/" ^ (String.concat "/" (to_string_list p))
  let of_string s = if s = "/" || s = "" then [] else of_string_list (String.split '/' s)

  let cd path x = of_string x @ (if x <> "" && x.[0] = '/' then [] else path)
  let is_root p = p = []
end: sig
  type t
  val of_string_list: string list -> t
  val to_string_list: t -> string list
  val directory: t -> t
  val filename: t -> string
  val to_string: t -> string
  val of_string: string -> t
  val cd: t -> string -> t
  val is_root: t -> bool
end)

module type BLOCK = sig
  val read_sector: int -> Bitstring.t
  val read_sectors: int list -> Bitstring.t
  val write_sector: int -> Bitstring.t -> unit
end

type error =
  | Not_a_directory of Path.t
  | Is_a_directory of Path.t
  | Directory_not_empty of Path.t
  | No_directory_entry of Path.t * string
  | File_already_exists of string
  | No_space
type 'a result =
  | Error of error
  | Success of 'a
let iter f xs = List.fold_left (fun r x -> match r with Error _ -> r | _ -> f x) (Success ()) xs

module Stat = struct
  type t = 
    | File of Dir_entry.r
    | Dir of Dir_entry.r * (Dir_entry.r list) (** the directory itself and its immediate children *)
end

module type FS = sig
  type fs
  val make: unit -> fs

  type file

  val create: fs -> Path.t -> unit result

  val mkdir: fs -> Path.t -> unit result

  (** [destroy fs path] removes a [path] on filesystem [fs] *)
  val destroy: fs -> Path.t -> unit result

  (** [file_of_path fs path] returns a [file] corresponding to [path] on
      filesystem [fs] *)
  val file_of_path: fs -> Path.t -> file

  (** [stat fs f] returns information about file [f] on filesystem [fs] *)
  val stat: fs -> Path.t -> Stat.t result

  (** [write fs f offset bs] writes bitstring [bs] at [offset] in file [f] on
      filesystem [fs] *)
  val write: fs -> file -> int -> Bitstring.t -> unit result

  (** [read fs f offset length] reads up to [length] bytes from file [f] on
      filesystem [fs]. If less data is returned than requested, this indicates
      end-of-file. *)
  val read: fs -> file -> int -> int -> Bitstring.t result
end

module FATFilesystem = functor(B: BLOCK) -> struct
  type fs = {
    boot: Boot_sector.t;
    format: format;      (** FAT12, 16 or 32 *)
    mutable fat: Bitstring.t;    (** contains the whole FAT *)
    mutable root: Bitstring.t;   (** contains the root directory *)
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

  type file = Path.t
  let file_of_path fs x = x

  type find =
    | Dir of Dir_entry.r list
    | File of Dir_entry.r

  let sectors_of_chain x chain =
    List.concat (List.map (Boot_sector.sectors_of_cluster x.boot) chain)
       
  let sectors_of_file x { Dir_entry.start_cluster = cluster; file_size = file_size; subdir = subdir } =
    let chain = Fat_entry.follow_chain x.format x.fat cluster in
    sectors_of_chain x chain

  let read_whole_file x { Dir_entry.dos = _, ({ Dir_entry.file_size = file_size; subdir = subdir } as f) } =
    B.read_sectors (sectors_of_file x f)

  let write_update x ({ Update.offset = offset; data = data } as update) =
    let bps = x.boot.Boot_sector.bytes_per_sector in
    let sector_number = Int64.(div offset (of_int bps)) in
    let sector_offset = Int64.(sub offset (mul sector_number (of_int bps))) in
    let sector = B.read_sector (Int64.to_int sector_number) in
    let sector' = Update.apply sector { update with Update.offset = sector_offset } in
    B.write_sector (Int64.to_int sector_number) sector'

  (** [find x path] returns a [find_result] corresponding to the object
      stored at [path] *)
  let find x path : find result =
    let readdir = function
      | Dir ds -> ds
      | File d -> Dir_entry.list (read_whole_file x d) in
    let rec inner sofar current = function
    | [] ->
      begin match current with
      | Dir ds -> Success (Dir ds)
      | File { Dir_entry.dos = _, { Dir_entry.subdir = true } } -> Success (Dir (readdir current))
      | File ( { Dir_entry.dos = _, { Dir_entry.subdir = false } } as d ) -> Success (File d)
      end
    | p :: ps ->
      let entries = readdir current in
      begin match Dir_entry.find p entries, ps with
      | Some { Dir_entry.dos = _, { Dir_entry.subdir = false } }, _ :: _ ->
        Error (Not_a_directory (Path.of_string_list (List.rev (p :: sofar))))
      | Some d, _ ->
        inner (p::sofar) (File d) ps
      | None, _ ->
        Error(No_directory_entry (Path.of_string_list (List.rev sofar), p))
      end in
    inner [] (Dir (Dir_entry.list x.root)) (Path.to_string_list path)

  (** Updates to files and directories involve writing to the following disk areas: *)
  type location =
    | Chain of int list (** write to a file/directory stored in a chain *)
    | Rootdir           (** write to the root directory area *)


  (** [chain_of_file x path] returns [Some chain] where [chain] is the chain
      corresponding to [path] or [None] if [path] cannot be found or if it
      is / and hasn't got a chain. *)
  let chain_of_file x path =
    if Path.is_root path then None
    else
      let parent_path = Path.directory path in
      match find x parent_path with
	| Success (Dir ds) ->
	  begin match Dir_entry.find (Path.filename path) ds with
	    | None -> assert false
	    | Some f ->
	      let start_cluster = (snd f.Dir_entry.dos).Dir_entry.start_cluster in
	      Some(Fat_entry.follow_chain x.format x.fat start_cluster)
	  end
	| _ -> None

  (** [write_to_location x path location update] applies [update] to the data given by
      [location]. This will also allocate any additional clusters necessary. *)
  let rec write_to_location x path location update : unit result =
    let bps = x.boot.Boot_sector.bytes_per_sector in
    let spc = x.boot.Boot_sector.sectors_per_cluster in
    let updates = Update.split update bps in
    let sectors = match location with 
      | Chain clusters -> sectors_of_chain x clusters
      | Rootdir -> Boot_sector.sectors_of_root_dir x.boot in
    (* This would be a good point to see whether we need to allocate
       new sectors and do that too. *)
    let current_bytes = bps * (List.length sectors) in
    let bytes_needed = max 0L (Int64.(sub (Update.total_length update) (of_int current_bytes))) in
    let clusters_needed =
      let bpc = Int64.of_int(spc * bps) in
      Int64.(to_int(div (add bytes_needed (sub bpc 1L)) bpc)) in
    match location, bytes_needed > 0L with
      | Rootdir, true ->
	Error No_space
      | (Rootdir | Chain _), false ->
	let writes = Update.map_updates updates sectors bps in
	List.iter (write_update x) writes;
	if location = Rootdir then x.root <- Update.apply x.root update;
	Success ()
      | Chain cs, true ->
	let last = if cs = [] then None else Some (List.hd (List.tl cs)) in
	let fat_allocations, new_clusters = Fat_entry.extend x.boot x.format x.fat last clusters_needed in
	(* Split the FAT allocations into multiple sectors. Note there might be more than one
	   per sector. *)
	let fat_allocations_sectors = List.concat (List.map (fun x -> Update.split x bps) fat_allocations) in
	let fat_sectors = Boot_sector.sectors_of_fat x.boot in
	let fat_writes = Update.map_updates fat_allocations_sectors fat_sectors bps in

	let new_sectors = sectors_of_chain x new_clusters in
	let data_writes = Update.map_updates updates (sectors @ new_sectors) bps in
	List.iter (write_update x) data_writes;
	List.iter (write_update x) fat_writes;
	update_directory_containing x path
	  (fun bits ds ->
	    let enoent = Error(No_directory_entry (Path.directory path, Path.filename path)) in
	    let filename = Path.filename path in
	    match Dir_entry.find filename ds with
	      | None ->
		enoent
	      | Some d ->
		let file_size = Dir_entry.file_size_of d in
		let new_file_size = max file_size (Int32.of_int (Int64.to_int (Update.total_length update))) in
		let start_cluster = List.hd (cs @ new_clusters) in
		begin match Dir_entry.modify bits filename new_file_size start_cluster with
		  | [] ->
		    enoent
		  | x ->
		    Success x
		end
	  );
	x.fat <- List.fold_left (fun fat update -> Update.apply fat update) x.fat fat_allocations;
	Success ()

  and update_directory_containing x path f =
    let parent_path = Path.directory path in
    match find x parent_path with
      | Error x -> Error x
      | Success (File _) -> Error(Not_a_directory parent_path)
      | Success (Dir ds) ->
	let sectors, location = match (chain_of_file x parent_path) with
	  | None -> Boot_sector.sectors_of_root_dir x.boot, Rootdir
	  | Some c -> sectors_of_chain x c, Chain c in
	let contents = B.read_sectors sectors in
	begin match f contents ds with
	  | Error x -> Error x
	  | Success updates ->
	    begin match iter (write_to_location x parent_path location) updates with
	      | Success () -> Success ()
	      | Error x -> Error x
	    end
	end

  (** [write x f offset bs] writes bitstring [bs] at [offset] in file [f] on
      filesystem [x] *)
  let write x f offset bs =
    let u = Update.make (Int64.of_int offset) bs in
    let location = match chain_of_file x f with
      | None -> Rootdir
      | Some c -> Chain (sectors_of_chain x c) in
    write_to_location x f location u

  let create_common x path dir_entry =
    let filename = Path.filename path in
    update_directory_containing x path
      (fun contents ds ->
	if Dir_entry.find filename ds <> None
	then Error (File_already_exists filename)
	else Success (Dir_entry.add contents dir_entry)
      )

  (** [create x path] create a zero-length file at [path] *)
  let create x path : unit result =
    create_common x path (Dir_entry.make (Path.filename path))

  (** [mkdir x path] create an empty directory at [path] *)
  let mkdir x path : unit result =
    create_common x path (Dir_entry.make ~subdir:true (Path.filename path))

  (** [destroy x path] deletes the entry at [path] *)
  let destroy x path : unit result =
    let filename = Path.filename path in
    let do_destroy () =
      update_directory_containing x path
	(fun contents ds ->
	(* XXX check for nonempty *)
	(* XXX delete chain *)
	  if Dir_entry.find filename ds = None
	  then Error (No_directory_entry(Path.directory path, filename))
	  else Success (Dir_entry.remove contents filename)
	) in
    match find x path with
      | Error x -> Error x
      | Success (File _) -> do_destroy ()
      | Success (Dir []) -> do_destroy ()
      | Success (Dir (_::_)) -> Error(Directory_not_empty(path))

  let stat x path =
    let entry_of_file f = f in
    match find x path with
      | Error x -> Error x
      | Success (File f) -> Success (Stat.File (entry_of_file f))
      | Success (Dir ds) ->
	let ds' = List.map entry_of_file ds in
	if Path.is_root path
	then Success (Stat.Dir (entry_of_file Dir_entry.fake_root_entry, ds'))
	else
	  let filename = Path.filename path in
	  let parent_path = Path.directory path in
	  match find x parent_path with
	    | Error x -> Error x
	    | Success (File _) -> assert false (* impossible by initial match *)
	    | Success (Dir ds) ->
	      begin match Dir_entry.find filename ds with
		| None -> assert false (* impossible by initial match *)
		| Some f ->
		  Success (Stat.Dir (entry_of_file f, ds'))
	      end

  let read_file x { Dir_entry.dos = _, ({ Dir_entry.file_size = file_size } as f) } the_start length =
    let bps = x.boot.Boot_sector.bytes_per_sector in
    let sm = SectorMap.make (sectors_of_file x f) in
    (* Clip [length] so that the region is within [file_size] *)
    let length = min (the_start + length) (Int32.to_int file_size) - the_start in
    (* Compute the list of sectors from the_start to length inclusive *)
    let the_end = the_start + length in
    let start_sector = the_start / bps in
    let rec inner acc sector bytes_read =
      if bytes_read >= length
      then List.rev acc
      else
	let data = B.read_sector (SectorMap.find sm sector) in
        (* consider whether this sector needs to be clipped to be within the range *)
	let bs_start = max 0 (the_start - sector * bps) in
	let bs_trim_from_end = max 0 ((sector + 1) * bps - the_end) in
	let bs_length = bps - bs_start - bs_trim_from_end in
	if bs_length <> bps
	then inner (Bitstring.bitstring_clip data bs_start (bs_length * 8) :: acc) (sector + 1) (bytes_read + bs_length)
	else inner (data :: acc) (sector + 1) (bytes_read + bs_length) in
    let bitstrings = inner [] start_sector 0 in
    Bitstring.concat bitstrings
      
  let read x path the_start length =
    match find x path with
      | Success (Dir _) -> Error (Is_a_directory path)
      | Success (File f) -> Success (read_file x f the_start length)
      | Error x -> Error x

end
