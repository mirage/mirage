open Lwt

(* The performance test is functorised over a SYSTEM: *)
module type SYSTEM = sig
  val sector_size: int
  val read_sectors: int * int -> Bitstring.t Lwt_stream.t

  val gettimeofday: unit -> float
end

module Normal_population = struct
  (** Stats on a normally-distributed population *)
  type t = { mutable sigma_x: float;
             mutable sigma_xx: float;
             mutable n: int }
      
  let make () = { sigma_x = 0.; sigma_xx = 0.; n = 0 }
    
  let sample (p: t) (x: float) = 
    p.sigma_x <- p.sigma_x +. x;
    p.sigma_xx <- p.sigma_xx +. x *. x;
    p.n <- p.n + 1
      
  let mean (p: t) : float = p.sigma_x /. (float_of_int p.n)
  let sd (p: t) : float option = 
    if p.n = 0 
    then None
    else 
      let n = float_of_int p.n in
      Some (sqrt (n *. p.sigma_xx -. p.sigma_x *. p.sigma_x) /. n)
end


type results = {
  seq_rd: (int * float) list; (* sequential read: block size * bytes per sec *)
  seq_wr: (int * float) list;   (* sequential write: block size * bytes per sec *)
  rand_rd: (int * Normal_population.t) list;  (* random read: block size * MiB per sec *)
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
    let parallelism = 64 in

    let blocks = ref blocks in

    let rec loop n =
      let extents, rest = take 1 !blocks in
      blocks := rest;
      lwt () = Lwt_list.iter_p (fun x -> operation (to_sectors S.sector_size x)) extents in
      let now = S.gettimeofday () in
      if start +. seconds < now
      then return n
      else loop (n + (List.length extents)) in
    let rec start = function
      | 0 -> []
      | n -> loop 0 :: (start (n - 1)) in
    let threads = start parallelism in
    lwt n = List.fold_left (fun acc t -> lwt n = t and acc = acc in return (n + acc)) (return 0) threads in
    return (float_of_int n /. seconds)

  let seconds = 1.
  let samples = 50

  let go disk_size =
    let rd sequence =
      Lwt_list.map_s (fun block_size ->
	let stats = Normal_population.make () in
	for_lwt i = 0 to samples - 1 do
	  lwt t = time seconds (sequence block_size disk_size)
	    (fun s ->
	      let stream = S.read_sectors s in
	      (* Consume the stream *)
	      Lwt_stream.junk_while_s (fun _ -> return true) stream
	    ) in
	    let mib_per_sec = float_of_int block_size *. t /. (1024.0 *. 1024.0) in
	    Normal_population.sample stats mib_per_sec;
	    return ()
        done >>
	return (block_size, stats)
      ) block_sizes in
    lwt rand_rd = rd random in
    return {
      seq_rd = [];
      seq_wr = [];
      rand_rd = rand_rd;
      rand_wr = [];
    }
end

