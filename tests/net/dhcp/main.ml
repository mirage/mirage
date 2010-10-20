open Lwt 
open Printf
open Mlnet

let main () =
  lwt vifs = OS.Ethif.enumerate () in
  let vif_t = List.map (fun id ->
    lwt (ip,thread) = Ipv4.create id in
    let udp,_ = Udp.create ip in
    lwt () = OS.Time.sleep 5. in
    lwt _ = Dhcp.Client.create ip udp in
    thread
  ) vifs in
  pick (OS.Time.sleep 120. :: vif_t) >>
  return (printf "success\n%!")

let _ = OS.Main.run (main ())
