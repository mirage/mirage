open Lwt 
open Printf

let main () = 
  Log.info "Ping" "starting server";
  Net.Manager.create (fun mgr interface id ->
    let ip = Net.Nettypes.(
      (Net.Nettypes.ipv4_addr_of_tuple (10l,0l,0l,2l),
       ipv4_addr_of_tuple (255l,255l,255l,0l),
       [ ipv4_addr_of_tuple (10l,0l,0l,1l) ]
      ))
    in
    Net.Manager.configure interface (`IPv4 ip)
    >> (let icmp_t, th = 
          Net.Icmp.create (Net.Manager.ipv4_of_interface interface)
        in th)
    >> return (OS.Console.log "success!\n")
  )
