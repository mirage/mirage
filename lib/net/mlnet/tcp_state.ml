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


type i = [
  | `Listen
  | `Rx_fin
  | `Rx_fin_ack
  | `Syn_acked
  | `Syn_received
  | `Syn_sent
  | `Timeout
  | `Tx_close
  | `Tx_fin
]

type t =
  | Closed
  | Listen
  | Syn_sent
  | Syn_received
  | Established
  | Fin_wait_1
  | Fin_wait_2
  | Close_wait
  | Closing
  | Last_ack
  | Time_wait

exception Bad_transition of (t * i)
exception Bad_state of t * string

let to_string = function
  | Closed -> "Closed"
  | Listen -> "Listen"
  | Syn_sent -> "Syn_sent"
  | Syn_received -> "Syn_received"
  | Established -> "Established"
  | Fin_wait_1 -> "Fin_wait_1"
  | Fin_wait_2 -> "Fin_wait_2"
  | Close_wait -> "Close_wait"
  | Closing -> "Closing"
  | Last_ack -> "Last_ack"
  | Time_wait -> "Time_wait"

let i_to_string (i:i) =
  match i with
  | `Listen -> "listen"
  | `Rx_fin -> "rx_fin"
  | `Rx_fin_ack -> "rx_fin_ack"
  | `Syn_acked -> "syn_acked"
  | `Syn_received -> "syn_received"
  | `Syn_sent -> "syn_sent"
  | `Timeout -> "timeout"
  | `Tx_close -> "tx_close"
  | `Tx_fin  -> "tx_fin"

let tick t (i:i) =
  match t,i with
  | Closed,`Listen -> Listen
  | Listen,`Syn_received -> Syn_received
  | Syn_received, `Syn_sent -> Syn_received
  | Syn_received, `Syn_acked -> Established
  | Established, `Tx_fin -> Fin_wait_1
  | Established, `Rx_fin -> Close_wait
  | Fin_wait_1, `Rx_fin_ack -> Fin_wait_2
  | Fin_wait_1, `Rx_fin -> Closing
  | Fin_wait_2, `Rx_fin -> Time_wait
  | Close_wait, `Tx_close -> Last_ack
  | Closing, `Rx_fin_ack -> Time_wait
  | Last_ack, `Rx_fin_ack -> Closed
  | Time_wait, `Timeout -> Closed
  | _ -> raise (Bad_transition (t,i))

(* True if we have sent a fin indicating tx connection close *)
let fin_sent = function
  | Listen
  | Closed
  | Syn_sent
  | Syn_received
  | Established
  | Close_wait  -> false
  | Closing
  | Last_ack
  | Fin_wait_1
  | Fin_wait_2
  | Time_wait -> true

(* True if we have received a fin indicating rx connection close *)
let fin_received = function
  | Listen
  | Closed
  | Syn_sent
  | Syn_received
  | Established
  | Fin_wait_1
  | Fin_wait_2 -> false
  | Close_wait
  | Closing
  | Last_ack
  | Time_wait -> true

