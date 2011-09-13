open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)


let read_line () =
  OS.Time.sleep (Random.float 2.5) >>=
  fun () ->
    Lwt.return (String.make (Random.int 20) 'a')


let rec echo_server num_lines =
  if 0 == num_lines then
    return ()
  else 
    read_line () >>=
    fun s ->
      Console.log s;
      echo_server (num_lines - 1)


let main () =
  Random.self_init ();
  echo_server 10

