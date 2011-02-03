(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_sequence
 * Copyright (C) 2009 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

exception Empty

type 'a t = {
  mutable prev : 'a t;
  mutable next : 'a t;
}

type 'a node = {
  mutable node_prev : 'a t;
  mutable node_next : 'a t;
  mutable node_data : 'a;
  mutable node_active : bool;
}

external seq_of_node : 'a node -> 'a t = "%identity"
external node_of_seq : 'a t -> 'a node = "%identity"

(* +-----------------------------------------------------------------+
   | Operations on nodes                                             |
   +-----------------------------------------------------------------+ *)

let get node =
  node.node_data

let set node data =
  node.node_data <- data

let remove node =
  if node.node_active then begin
    node.node_active <- false;
    let seq = seq_of_node node in
    seq.prev.next <- seq.next;
    seq.next.prev <- seq.prev
  end

(* +-----------------------------------------------------------------+
   | Operations on sequences                                         |
   +-----------------------------------------------------------------+ *)

let create () =
  let rec seq = { prev = seq; next = seq } in
  seq

let is_empty seq = seq.next == seq

let add_l data seq =
  let node = { node_prev = seq; node_next = seq.next; node_data = data; node_active = true } in
  seq.next.prev <- seq_of_node node;
  seq.next <- seq_of_node node;
  node

let add_r data seq =
  let node = { node_prev = seq.prev; node_next = seq; node_data = data; node_active = true } in
  seq.prev.next <- seq_of_node node;
  seq.prev <- seq_of_node node;
  node

let take_l seq =
  if is_empty seq then
    raise Empty
  else begin
    let node = node_of_seq seq.next in
    remove node;
    node.node_data
  end

let take_r seq =
  if is_empty seq then
    raise Empty
  else begin
    let node = node_of_seq seq.prev in
    remove node;
    node.node_data
  end

let peek_l seq =
  if is_empty seq then
    raise Empty
  else begin
    let node = node_of_seq seq.next in
    node.node_data
  end

let peek_r seq =
  if is_empty seq then
    raise Empty
  else begin
    let node = node_of_seq seq.prev in
    node.node_data
  end

let take_opt_l seq =
  if is_empty seq then
    None
  else begin
    let node = node_of_seq seq.next in
    remove node;
    Some node.node_data
  end

let take_opt_r seq =
  if is_empty seq then
    None
  else begin
    let node = node_of_seq seq.prev in
    remove node;
    Some node.node_data
  end

let peek_opt_l seq =
  if is_empty seq then
    None
  else begin
   let node = node_of_seq seq.next in
   Some node.node_data
  end

let peek_opt_r seq =
  if is_empty seq then
    None
  else begin
    let node = node_of_seq seq.prev in
    Some node.node_data
  end

let transfer_l s1 s2 =
  s2.next.prev <- s1.prev;
  s1.prev.next <- s2.next;
  s2.next <- s1.next;
  s1.next.prev <- s2;
  s1.prev <- s1;
  s1.next <- s1

let transfer_r s1 s2 =
  s2.prev.next <- s1.next;
  s1.next.prev <- s2.prev;
  s2.prev <- s1.prev;
  s1.prev.next <- s2;
  s1.prev <- s1;
  s1.next <- s1

let iter_l f seq =
  let rec loop curr =
    if curr != seq then begin
      let node = node_of_seq curr in
      if node.node_active then f node.node_data;
      loop node.node_next
    end
  in
  loop seq.next

let iter_r f seq =
  let rec loop curr =
    if curr != seq then begin
      let node = node_of_seq curr in
      if node.node_active then f node.node_data;
      loop node.node_prev
    end
  in
  loop seq.prev

let iter_node_l f seq =
  let rec loop curr =
    if curr != seq then begin
      let node = node_of_seq curr in
      if node.node_active then f node;
      loop node.node_next
    end
  in
  loop seq.next

let iter_node_r f seq =
  let rec loop curr =
    if curr != seq then begin
      let node = node_of_seq curr in
      if node.node_active then f node;
      loop node.node_prev
    end
  in
  loop seq.prev

let fold_l f seq acc =
  let rec loop curr acc =
    if curr == seq then
      acc
    else
      let node = node_of_seq curr in
      if node.node_active then
        loop node.node_next (f node.node_data acc)
      else
        loop node.node_next acc
  in
  loop seq.next acc

let fold_r f seq acc =
  let rec loop curr acc =
    if curr == seq then
      acc
    else
      let node = node_of_seq curr in
      if node.node_active then
        loop node.node_prev (f node.node_data acc)
      else
        loop node.node_next acc
  in
  loop seq.prev acc
