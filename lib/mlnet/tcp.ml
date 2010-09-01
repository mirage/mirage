(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

(* TCPv4 implementation, heavily based on the lwIP-1.3.2 state machine *)

open Lwt
open Mlnet_types
open Printf

module type UP = sig
  type t
  val input: t -> Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t
  val output: t -> dest_ip:ipv4_addr -> (Mpl.Mpl_stdlib.env -> Mpl.Tcp.o) -> unit Lwt.t
  val listen: t -> int -> (Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t) -> unit
end

module TCP(IP:Ipv4.UP) = struct

  type state =
  |Closed
  |Listen
  |Syn_sent
  |Syn_received
  |Established
  |Fin_wait_1
  |Fin_wait_2
  |Close_wait
  |Closing
  |Last_ack
  |Time_wait

  type flags = {
    ack_delay: bool;     (* Delayed ACK *)
    ack_now: bool;       (* Immediate ACK *)
    fast_recovery: bool; (* Fast recovery mode *)
    timestamp: bool;     (* Timestamp option enabled *)
    fin: bool;           (* Local connection closed *)
    no_delay: bool;      (* Disable nagle *)
  }

  type pcb = {

    state: state;        (* Connection state *)
    flags: flags;        (* Connection flags *)
    remote_port: int;    (* Remote TCP port *)

    (* Receiver info *)
    rcv_nxt: int32;      (* Next expected sequence no *)
    rcv_wnd: int;        (* Receiver window available *)
    rcv_ann_wnd: int;    (* Receiver window to announce *)
    rcv_ann_edge: int32; (* Announced right edge of window *)
    mss: int;            (* Maximum segment size *)

    (* RTT estimation variables *)
    rttest: int32;       (* RTT estimate in 500ms ticks *)
    rtseq: int32;        (* Sequence number being timed *)
    rto: int;            (* Retransmission timeout *)
    rtx: int;            (* Number of retransmissions *)
    
    (* Fast transmit/recovery *)
    lastack: int32;      (* Last acknowleged seqno *)
    dupacks: int;
 
    (* Congestion avoidance variables *)
    cwnd: int;
    ssthresh: int;

    (* Sender info *)
    snd_nxt: int32;      (* Next new seqno to be sent *)
    snd_wnd: int;        (* Sender window *)
    snd_wl1: int32;
    snd_wl2: int32;      (* Seq and ack num of last wnd update *) 
    snd_lbb: int32;      (* Seq of next byte to be buffered *)
  }
  
  type t = {
    ip : IP.t;
    listeners: (int, (Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t)) Hashtbl.t
  }

  let state_to_string = function
  |Closed -> "closed"
  |Listen -> "listen"
  |Syn_sent -> "syn_sent"
  |Syn_received -> "syn_recv"
  |Established -> "established"
  |Fin_wait_1 -> "fin_wait_1"
  |Fin_wait_2 -> "fin_wait_2"
  |Close_wait -> "close_wait"
  |Closing -> "closing"
  |Last_ack -> "last_ack"
  |Time_wait -> "time_wait"


  let 
  let input t ip udp =
    let dest_port = udp#dest_port in
    if Hashtbl.mem t.listeners dest_port then begin
      let fn = Hashtbl.find t.listeners dest_port in
      fn ip udp
    end else
      return ()

  let listen t port fn =
    if Hashtbl.mem t.listeners port then
      printf "WARNING: UDP listen port %d already used\n%!" port;
    Hashtbl.replace t.listeners port fn

  let create ip =
    let listeners = Hashtbl.create 1 in
    let t = { ip; listeners } in
    IP.attach ip (`TCP (input t));
    t

end
