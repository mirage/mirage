open Net
open Lwt 
open Printf
open Nettypes
open Mlnet

let ipaddr = match ipv4_addr_of_string "10.0.0.2" with Some x -> x |None -> assert false
let nm = match ipv4_addr_of_string "255.255.255.0" with Some x -> x |None -> assert false

let use_dhcp = false

let main () =
  OS.Console.log (sprintf "start");
  lwt vifs = OS.Ethif.enumerate () in
  OS.Console.log (sprintf "found %d VIFs" (List.length vifs));
  let vif_t = List.map (fun id ->
    lwt (ip,ip_t) = Ipv4.create id in
    let (icmp,icmp_t) = Icmp.create ip in
    let (udp,udp_t) = Udp.create ip in
    let ipaddr_t = (match use_dhcp with
    | true -> 
      lwt (dhcp,dhcp_t) = Dhcp.Client.create ip udp in
      dhcp_t
    | false ->
      Ipv4.set_netmask ip nm >>
      Ipv4.set_ip ip ipaddr >>
      return ()
    ) in
    let (tcp,tcp_t) = Tcp.create ip in
    Tcp.listen tcp 23 (fun pcb ->
      OS.Console.log "TCP: new connection on port 23";
      let rec fn () =
        lwt r = Tcp.read pcb in
        match r with
        |None ->
          OS.Console.log "MAIN: RX Connection closed"; 
          Tcp.close pcb
        |Some v ->
          let len = Int32.of_int (OS.Istring.View.length v) in
          Tcp.write_wait_for pcb len >>
          Tcp.write pcb (`Frag v) >>
          fn ()
      in fn ()
    );
    join [ ip_t; icmp_t; udp_t; ipaddr_t; tcp_t ]
  ) vifs in
  pick (OS.Time.sleep 120. :: vif_t) >>
  return (OS.Console.log "success\n%!")

let _ = OS.Main.run (main ())
