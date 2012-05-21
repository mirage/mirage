open Lwt
open OS

let main () =
  lwt () = Console.log_s "Sleeping 5s" in
  lwt () = Time.sleep 5. in
  lwt () = Console.log_s "Rebooting" in
  OS.Sched.shutdown OS.Sched.Reboot;
  lwt () = Console.log_s "Error: failed to reboot" in
  return ()
