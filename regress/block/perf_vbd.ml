open Lwt
open Printf

open Perf

let main () =
  let finished_t, u = Lwt.task () in
  let listen_t = OS.Devices.listen (fun id ->
    OS.Devices.find_blkif id >>=
    function
    | None -> return ()
    | Some blkif -> Lwt.wakeup u blkif; return ()
  ) in
  (* Get one device *)
  lwt blkif = finished_t in
  (* Cancel the listening thread *)
  Lwt.cancel listen_t;
  printf "ID: %s\n%!" blkif#id;
  printf "Connected block device\n%!";
  printf "Total device size = %Ld\nSector size = %d\n%!" blkif#size blkif#sector_size;
  printf "Device is read%s\n%!" (if blkif#readwrite then "/write" else "-only");
  let module M = struct
    let page_size_bytes = 4096
    let sector_size = 512
    let sectors_per_page = page_size_bytes / sector_size
    let read_sectors (start, length) =
      (* XXX: for performance testing, we read the correct pages but omit the clipping *)
      let start_page_no = start / sectors_per_page in
      let last_page_no = (start + length - 1) / sectors_per_page in
      (* We must read all pages from start_page_no to last_page_no inclusive *)
      let rec loop n =
	if n > last_page_no
	then return (Bitstring.bitstring_of_string "dummy data")
	else
	  let offset = Int64.(mul (of_int page_size_bytes) (of_int n)) in
	  lwt _ = blkif#read_page offset in
          loop (n + 1) in
      loop start_page_no

    let gettimeofday = OS.Clock.time
  end in
  let module Test = Perf.Test(M) in
  lwt results = Test.go (Int64.to_int blkif#size) in

(* Write the results to the first page on the disk, unused for now:
  let results' = [
    "Sequential Read\n";
    "---------------\n";
  ] @ (List.map (fun (block_size, number) ->
    Printf.sprintf "%d, %.0f\n" block_size (float_of_int block_size *. number)
  ) results.Perf.seq_rd
  ) @ [
    "End"
  ] in

  lwt () = OS.Io_page.with_page
      (fun page ->
	let bs = OS.Io_page.to_bitstring page in
	let results = Bitstring.bitstring_of_string (String.concat "" results') in
	Bitstring.bitstring_write results 0 bs;
	blkif#write_page 0L bs
      ) in
*)
  lwt () = OS.Console.log_s "Sequential Read" in
  lwt () = OS.Console.log_s "---------------" in
  lwt () = Lwt_list.iter_s
    (fun (block_size, number) ->
      OS.Console.log_s (sprintf "%d, %.0f" block_size (float_of_int block_size *. number))
    ) results.Perf.seq_rd in
  return ()

