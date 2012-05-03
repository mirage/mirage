open Printf
open Lwt

(* Create a thread that records the OS time at point of creation,
 * and at the point it wakes up, and measures the jitter.
 *)
let jitter_t t =
  let duration = (Random.float 2.0) +. 1. in
  (* Wait for the passed in thread to wake as a sync point *)
  lwt () = t in
  let t1 = OS.Clock.time () in
  lwt () = OS.Time.sleep duration in
  let t2 = OS.Clock.time () in
  return (t2 -. t1 -. duration)

(* Cumulative distribution function of results list *)
let maxt = 0.0002
let mint = 0.000
let diff = maxt -. mint
let buckets = 50
let quant = diff /. (float buckets)
let b = Array.create (buckets+1) 0

let cdf res =
  (* Put each result in a bucket *)
  List.iter (fun j ->
    let bucket = int_of_float ((j -. mint) /. quant) in
    let bucket = if bucket >= buckets then
     ((buckets-1)) else bucket in
    b.(bucket) <- b.(bucket) + 1
  ) res;
  return ()

let cdf_show () =
  Array.iteri (fun i x -> printf "%s %f %d %d\n%!" Sys.os_type (mint +. (float i *. quant)) i x) b;
  return ()

let main () =
  (* Construction X parallel threads and measure each of their
   * jitters 
   *)
  let make_threads num =
    let t,u = Lwt.task () in
    let rec loop acc =
      function
      |0 -> acc
      |n ->
        let th = jitter_t t in
        loop (th::acc) (n-1)
    in
    (loop [] num), u
  in
  for_lwt i = 0 to 5 do
    let reps = 1000 in
    (* Make threads and launch the parallel map *)
    let ths, u = make_threads reps in
    let result_t = Lwt_list.map_p (fun x -> x) ths in
    (* Settle the GC *)
    Gc.compact ();
    (* Launch them! *)
    Lwt.wakeup u ();
    lwt results = result_t in
    cdf results
  done >>
  cdf_show ()
