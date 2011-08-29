open Printf

let block_size = 1024

let f = ref Unix.stdin

let opendevice filename =
  f := Unix.openfile filename [ Unix.O_RDONLY ] 0o0

let rec really_read fd string off n =
  if n=0 then () else
    let m = Unix.read fd string off n in
    if m = 0 then raise End_of_file;
    really_read fd string (off+m) (n-m)

let read_block n =
  Unix.lseek !f (n * block_size) Unix.SEEK_SET;
  let results = String.create block_size in
  really_read !f results 0 block_size;
  results

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

  (* Load a real fat structure *)
  let bits = Bitstring.bitstring_of_string (read_block 1) in
  ()
