(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt 
open Printf
open OS.Clock
open Gc

type stats = {
  mutable bytes: int64;
  mutable packets: int64;
  mutable bin_bytes:int64;
  mutable bin_packets: int64;
  mutable last_time: float;
}

let ip = Net.Nettypes.(
  (ipv4_addr_of_tuple (10l,0l,0l,2l),
   ipv4_addr_of_tuple (255l,255l,255l,0l),
   [ ipv4_addr_of_tuple (10l,0l,0l,2l) ]
  ))

let port = 5001

let print_data st ts_now = 
  Printf.printf ">>>>>>>>>>>>>>>> %f %Ld KBytes/s  totbytes = %Ld  live_words = %d\n%!" ts_now
    (Int64.div st.bin_bytes 1000L) st.bytes Gc.((stat()).live_words); 
  st.last_time <- ts_now;
  st.bin_bytes <- 0L;
  st.bin_packets <- 0L 

let iperf (dip,dpt) chan =
  Log.info "tcp_iperf" "connected";
  let st = {bytes=0L; packets=0L; bin_bytes=0L; bin_packets=0L; last_time =
    (OS.Clock.time ())} in
  try_lwt
    while_lwt true do
      lwt data = (Net.Channel.read_some chan) in
      st.bytes <- (Int64.add st.bytes (Int64.of_int ((Bitstring.bitstring_length data) / 8)));
      st.packets <- (Int64.add st.packets 1L);
      st.bin_bytes <- (Int64.add st.bin_bytes (Int64.of_int ((Bitstring.bitstring_length data) / 8)));
      st.bin_packets <- (Int64.add st.bin_packets 1L);
      let ts_now = (OS.Clock.time ()) in 
      if ((ts_now -. st.last_time) >= 1.0) then begin
        print_data st ts_now;
      end;

      return () 
    done
  with Net.Nettypes.Closed -> return (Log.info "Echo" "closed!")

let main () =
  Log.info "Echo" "starting server";
  Net.Manager.create (fun mgr interface id ->
(*    Net.Manager.configure interface (`IPv4 ip); *)
    Net.Manager.configure interface (`DHCP);
    Net.Channel.listen mgr (`TCPv4 ((None, port), iperf))
    >> return (Log.info "Channel_echo" "done!")
  )


