(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_list
 * Copyright (C) 2010 Jérémie Dimino
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

open Lwt

let rec iter_s f l =
  match l with
    | [] ->
        return ()
    | x :: l ->
        lwt () = f x in
        iter_s f l

let rec iter_p f l =
  match l with
    | [] ->
        return ()
    | x :: l ->
        let t = f x and lt = iter_p f l in
        lwt () = t in
        lt

let rec map_s f l =
  match l with
    | [] ->
        return []
    | x :: l ->
        lwt x = f x in
        lwt l = map_s f l in
        return (x :: l)

let rec map_p f l =
  match l with
    | [] ->
        return []
    | x :: l ->
        lwt x = f x and l = map_p f l in
        return (x :: l)

let rec rev_map_append_s acc f l =
  match l with
    | [] ->
        return acc
    | x :: l ->
        lwt x = f x in
        rev_map_append_s (x :: acc) f l

let rev_map_s f l =
  rev_map_append_s [] f l

let rec rev_map_append_p acc f l =
  match l with
    | [] ->
        acc
    | x :: l ->
        rev_map_append_p (lwt x = f x and l = acc in return (x :: l)) f l

let rev_map_p f l =
  rev_map_append_p (return []) f l

let rec fold_left_s f acc l =
  match l with
    | [] ->
        return acc
    | x :: l ->
        lwt acc = f acc x in
        fold_left_s f acc l

let rec fold_right_s f l acc =
  match l with
    | [] ->
        return acc
    | x :: l ->
        lwt acc = fold_right_s f l acc in
        f x acc

let rec for_all_s f l =
  match l with
    | [] ->
        return true
    | x :: l ->
        f x >>= function
          | true ->
              for_all_s f l
          | false ->
              return false

let rec for_all_p f l =
  match l with
    | [] ->
        return true
    | x :: l ->
        lwt bx = f x and bl = for_all_p f l in
        return (bx && bl)

let rec exists_s f l =
  match l with
    | [] ->
        return false
    | x :: l ->
        f x >>= function
          | true ->
              return true
          | false ->
              exists_s f l

let rec exists_p f l =
  match l with
    | [] ->
        return false
    | x :: l ->
        lwt bx = f x and bl = exists_p f l in
        return (bx || bl)

let rec find_s f l =
  match l with
    | [] ->
        raise_lwt Not_found
    | x :: l ->
        f x >>= function
          | true ->
              return x
          | false ->
              find_s f l

let rec filter_s f l =
  match l with
    | [] ->
        return []
    | x :: l ->
        f x >>= function
          | true ->
              lwt l = filter_s f l in
              return (x :: l)
          | false ->
              filter_s f l

let rec filter_p f l =
  match l with
    | [] ->
        return []
    | x :: l ->
        lwt bx = f x and l = filter_p f l in
        if bx then
          return (x :: l)
        else
          return l

let rec partition_s f l =
  match l with
    | [] ->
        return ([], [])
    | x :: l ->
        lwt bx = f x in
        lwt l_l, l_r = partition_s f l in
        if bx then
          return (x :: l_l, l_r)
        else
          return (l_l, x :: l_r)

let rec partition_p f l =
  match l with
    | [] ->
        return ([], [])
    | x :: l ->
        lwt bx = f x and l_l, l_r = partition_p f l in
        if bx then
          return (x :: l_l, l_r)
        else
          return (l_l, x :: l_r)
