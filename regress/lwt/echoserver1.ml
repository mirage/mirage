open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)

let read_line () =
  Time.sleep (Random.float 2.5) >>
  return (String.make (Random.int 20) 'a')

let rec echo_server =
  function
  |0 -> return ()
  |num_lines ->
    lwt s = read_line () in
    Console.log s;
    echo_server (num_lines - 1)

let main () =
  Random.self_init ();
  echo_server 10
