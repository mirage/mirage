open Lwt

(* The performance test is functorised over a SYSTEM: *)
module type SYSTEM = sig
  val sector_size: int
  val read_sectors: int * int -> Bitstring.t array Lwt.t

  val gettimeofday: unit -> float
end

type results = {
  seq_rd: (int * float) list; (* sequential read: block size * bytes per sec *)
  seq_wr: (int * float) list;   (* sequential write: block size * bytes per sec *)
  rand_rd: (int * float) list;  (* random read: block size * bytes per sec *)
  rand_wr: (int * float) list;  (* random write: block size * bytes per sec *)
}

let block_sizes =
  (* multiples of 2 from [start] to [limit] inclusive *)
  let rec powers limit start = if start > limit then [] else start :: (powers limit (start * 2)) in
  powers 4194304 512

type 'a ll = Cons of 'a * (unit -> 'a ll)

let rec take n list = match n, list with
  | 0, _ -> [], list
  | n, Cons(x, xs) ->
    let xs, rest = take (n-1) (xs ()) in
    x :: xs, rest

(* A lazy-list of (offset, length) pairs corresponding to sequential blocks
   (size [block_size] from a disk of size [disk_size]. When we hit the end
   we go back to the beginning. *)
let sequential block_size disk_size =
  assert (block_size < disk_size);
  let rec list pos =
    if pos + block_size > disk_size
    then list 0
    else Cons((pos, block_size), fun () -> list (pos + block_size)) in
  list 0

(* A lazy-list of (offset, length) pairs corresponding to random blocks
   (size [block_size] from a disk of size [disk_size]. For deterministic
   results, use Random.init *)
let random block_size disk_size =
  assert (block_size < disk_size);
  let nblocks = disk_size / block_size in
  let rec list () =
    let block = Random.int nblocks in
    Cons((block * block_size, block_size), list) in
  list ()

(* Return (start sector, nsectors) corresponding to (offset, length) *)
let to_sectors sector_size (offset, length) =
  let first = offset / sector_size in
  let last = (offset + length - 1) / sector_size in
  first, last - first + 1

module Test = functor(S: SYSTEM) -> struct

  (* return the total number of [operations] performed on [blocks] per second, averaging over [seconds] s *)
  let time seconds blocks operation =
    let start = S.gettimeofday () in
    let parallelism = 8 in
    let rec loop blocks n =
      let extents, rest = take parallelism blocks in
      lwt () = Lwt_list.iter_p (fun x -> operation (to_sectors S.sector_size x)) extents in
      let now = S.gettimeofday () in
      if start +. seconds < now
      then return (float_of_int n /. seconds)
      else loop rest (n + parallelism) in
    loop blocks 0

  let seconds = 10.

  let go disk_size =
    let rd sequence =
      Lwt_list.map_s (fun block_size ->
	lwt t = time seconds (sequence block_size disk_size) (fun s -> Lwt.map (fun _ -> ()) (S.read_sectors s)) in
	return (block_size, t)
      ) block_sizes in
    lwt rand_rd = rd random in
    return {
      seq_rd = [];
      seq_wr = [];
      rand_rd = rand_rd;
      rand_wr = [];
    }
end

