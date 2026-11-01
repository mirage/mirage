let find_rss str =
  try Scanf.sscanf str "Rss: %d kB" Option.some
  with Scanf.Scan_failure _ -> None

let find_rss_slow ch =
  let (_skip_first_line : string) = input_line ch in
  Seq.of_dispenser (fun () -> In_channel.input_line ch) |> Seq.find_map find_rss

(** [get_rss_slow ()] returns the Resident Set Size of the current process.

    See [proc_pid_statm(5)]: the RSS values reported in [/proc/self/stat],
    [/proc/self/statm], and [/proc/self/status] are inaccurate. Accurate values
    are in [/proc/self/smaps] and [/proc/self/smaps_rollup] although these are
    slower to query.

    This function is used in unit tests, so accuracy is preferred.

    There is no POSIX function to retrieve current RSS usage, [getrusage(2)] can
    only return MaxRSS. *)
let get_rss_slow () =
  Gc.compact ();
  let r =
    In_channel.with_open_text "/proc/self/smaps_rollup" find_rss_slow
    |> Option.get
  in
  Gc.compact ();
  r

let n = 1 lsl 14
let m = 509 (* 509 + 3 words overhead for large arrays -> 512*8 = 4096 *)

let test () =
  try
    let rss0 = get_rss_slow () in
    let a = Array.make 4 [||] in

    a.(0) <- Array.make_matrix n m 0;
    a.(1) <- Array.make_matrix 1 m 0;
    a.(2) <- Array.make_matrix n m 0;
    a.(3) <- Array.make_matrix 1 m 0;

    (* RSS should've increase here *)
    let rss1 = get_rss_slow () in

    (* Now free the middle values.
         Do not free the last value, that'd get immediately returned by glibc.
       *)
    a.(0) <- [||];
    a.(2) <- [||];

    (* This frees the values from the OCaml side,
         but glibc might retain them *)
    Gc.compact ();

    let rss2 = get_rss_slow () in

    (* keep it alive across the [Gc.compact] *)
    let _alive = Sys.opaque_identity a in
    Gc.compact ();

    let rss3 = get_rss_slow () in
    Printf.printf "RSS0: %d kB\n" rss0;
    Printf.printf "RSS1: %d kB\n" rss1;
    Printf.printf "RSS2: %d kB\n" rss2;
    Printf.printf "RSS3: %d kB\n" rss3;
    assert (rss0 < rss1);

    (* not accounting for OCaml value overhead the 2 arrays
         are at least this many bytes
       *)
    let expected_kb = 2 * n * m * Sys.word_size / 8 / 1024 in
    Printf.printf "Expected decrease: %d kB\n" expected_kb;
    let actual_kb = rss1 - rss2 in
    Printf.printf "Actual decrease RSS1-RSS2: %d kB\n" actual_kb;
    if actual_kb < expected_kb then
      failwith "OCaml released memory, but libc didn't"
  with Sys_error e ->
    (* maybe the kernel doesn't have support compiled in *)
    Printf.eprintf "SKIP: %s\n" e

let () =
  (* ensure module is linked and initializers run *)
  Mirage_runtime.set_name "test_malloc_trim";
  test ();
  test ();
  Printf.printf "Disabling malloc_trim workaround\n";
  Gc.delete_alarm Mirage_runtime.malloc_trim_alarm;
  try
    test ();
    (* the behaviour of glibc can change over time, so don't fail if it works
       without malloc_trim
     *)
    Printf.printf "Succeeded even without malloc_trim"
  with Failure e -> Printf.eprintf "Ignoring expected failure: %s\n" e
