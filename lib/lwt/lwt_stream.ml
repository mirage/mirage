(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_stream
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

open Lwt

let lazy_from_fun = Lazy.lazy_from_fun

exception Empty

type 'a node =
  | Cons of 'a * 'a lazy_list
  | Nil

and 'a lazy_list = 'a node Lwt.t Lazy.t

type 'a t = 'a lazy_list ref

let of_lazy_list = ref
let to_lazy_list = ( ! )

let make f = ref(Lazy.lazy_from_fun f)

let from f =
  let rec next _ =
    f () >|= function
      | Some x -> Cons(x, lazy_from_fun next)
      | None -> Nil
  in
  make next

let of_list l =
  let rec get = function
    | [] -> return Nil
    | x :: l -> return (Cons(x, lazy(get l)))
  in
  ref(lazy(get l))

let of_string s =
  let rec get i =
    if i = String.length s then
      return Nil
    else
      return (Cons(s.[i], lazy(get (i + 1))))
  in
  ref(lazy(get 0))

let clone s = ref !s

let peek s = Lazy.force !s >|= function
  | Cons(x, _) -> Some x
  | Nil -> None

let npeek n s =
  let rec aux n l =
    if n <= 0 then
      return []
    else
      Lazy.force l >>= function
        | Cons(x, l) ->
            lwt l = aux (n - 1) l in
            return (x :: l)
        | Nil ->
            return []
  in
  aux 0 !s

let get s = Lazy.force !s >|= function
  | Cons(x, l) -> s := l; Some x
  | Nil -> None

let rec nget n s =
  if n <= 0 then
    return []
  else
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          lwt l = nget (n - 1) s in
          return (x :: l)
      | Nil ->
          return []

let rec get_while f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        if f x then begin
          s := l;
          lwt l = get_while f s in
          return (x :: l)
        end else
          return []
    | Nil ->
        return []

let rec get_while_s f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        f x >>= begin function
          | true ->
              s := l;
              lwt l = get_while_s f s in
              return (x :: l)
          | false ->
              return []
        end
    | Nil ->
        return []

let next s = Lazy.force !s >>= function
  | Cons(x, l) -> s := l; return x
  | Nil -> fail Empty

let junk s = Lazy.force !s >>= function
  | Cons(x, l) -> s := l; return ()
  | Nil -> return ()

let rec njunk n s =
  if n <= 0 then
    return ()
  else
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          njunk (n - 1) s
      | Nil ->
          return ()

let rec junk_while f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        if f x then begin
          s := l;
          junk_while f s
        end else
          return ()
    | Nil ->
        return ()

let rec junk_while_s f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        f x >>= begin function
          | true ->
              s := l;
              junk_while_s f s
          | false ->
              return ()
        end
    | Nil ->
        return ()

let rec junk_old s =
  let t = Lazy.force !s in
  match Lwt.state t with
    | Return(Cons(_, l)) ->
        s := l;
        junk_old s
    | Return Nil ->
        return ()
    | Fail e ->
        fail e
    | Sleep ->
        return ()

let is_empty s = Lazy.force !s >|= function
  | Cons _ -> false
  | Nil -> true

let map f s =
  let rec next _ =
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          let x = f x in
          return (Cons(x, lazy_from_fun next))
      | Nil ->
          return Nil
  in
  make next

let map_s f s =
  let rec next _ =
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          lwt x = f x in
          return (Cons(x, lazy_from_fun next))
      | Nil ->
          return Nil
  in
  make next

let filter f s =
  let rec next _ =
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          if f x then
            return (Cons(x, lazy_from_fun next))
          else
            next ()
      | Nil ->
          return Nil
  in
  make next

let filter_s f s =
  let rec next _ =
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          f x >>= begin function
            | true ->
                return (Cons(x, lazy_from_fun next))
            | false ->
                next ()
          end
      | Nil ->
          return Nil
  in
  make next

let filter_map f s =
  let rec next _ =
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          begin match f x with
            | Some x ->
                return (Cons(x, lazy_from_fun next))
            | None ->
                next ()
          end
      | Nil ->
          return Nil
  in
  make next

let filter_map_s f s =
  let rec next _ =
    Lazy.force !s >>= function
      | Cons(x, l) ->
          s := l;
          f x >>= begin function
            | Some x ->
                return (Cons(x, lazy_from_fun next))
            | None ->
                next ()
          end
      | Nil ->
          return Nil
  in
  make next

let rec fold f s acc =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        fold f s (f x acc)
    | Nil ->
        return acc

let rec fold_s f s acc =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        f x acc >>= fold_s f s
    | Nil ->
        return acc

let rec iter f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        f x;
        iter f s
    | Nil ->
        return ()

let rec iter_s f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        f x >> iter f s
    | Nil ->
        return ()

let rec iter_p f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        f x <&> iter f s
    | Nil ->
        return ()

let rec find f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        if f x then
          return (Some x)
        else
          find f s
    | Nil ->
        return None

let rec find_s f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        f x >>= begin function
          | true ->
              return (Some x)
          | false ->
              find_s f s
        end
    | Nil ->
        return None

let rec find_map f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        begin match f x with
          | Some x as n -> return n
          | None -> find_map f s
        end
    | Nil ->
        return None

let rec find_map_s f s =
  Lazy.force !s >>= function
    | Cons(x, l) ->
        s := l;
        f x >>= begin function
          | Some x as n -> return n
          | None -> find_map_s f s
        end
    | Nil ->
        return None

let rec combine s1 s2 =
  let rec next _ =
    lwt n1 = get s1 and n2 = get s2 in
    match n1, n2 with
      | Some x1, Some x2 ->
          return (Cons((x1, x2), lazy_from_fun next))
      | _ ->
          return Nil
  in
  make next

let split s = (map fst (clone s), map snd (clone s))

let partition f s = (filter f s, filter (fun x -> not (f x)) (clone s))
let partition_s f s = (filter_s f s, filter_s (fun x -> f x >|= not) (clone s))

let append s1 s2 =
  let rec next1 _ =
    Lazy.force !s1 >>= function
      | Cons(x, l) ->
          s1 := l;
          return (Cons(x, lazy_from_fun next1))
      | Nil ->
          next2 ()
  and next2 _ =
    Lazy.force !s2 >>= function
      | Cons(x, l) ->
          s2 := l;
          return (Cons(x, lazy_from_fun next2))
      | Nil ->
          return Nil
  in
  make next1

let concat s_top =
  let rec next _ =
    Lazy.force !s_top >>= function
      | Cons(x_top, l_top) ->
          Lazy.force !x_top >>= begin function
            | Cons(x, l) ->
                x_top := l;
                return (Cons(x, lazy_from_fun next))
            | Nil ->
                s_top := l_top;
                next ()
          end
      | Nil ->
          return Nil
  in
  make next

let choose streams =
  let source s = (s, Lazy.force !s >|= fun n -> (s, n)) in
  let rec next = function
    | [] ->
        return Nil
    | streams ->
        Lwt.choose (List.map snd streams) >>= fun (s, n) ->
          let streams = List.remove_assq s streams in
          match n with
            | Cons(x, l) ->
                s := l;
                return (Cons(x, lazy(next (source s :: streams))))
            | Nil ->
                next streams
  in
  ref(lazy(next (List.rev_map source streams)))

let parse s f =
  let s' = clone s in
  lwt x = f s' in
  s := !s';
  return x

let hexdump stream =
  let buf = Buffer.create 80 and num = ref 0 in
  from begin fun _ ->
    nget 16 stream >>= function
      | [] ->
          return None
      | l ->
          Buffer.clear buf;
          Printf.bprintf buf "%08x|  " !num;
          num := !num + 16;
          let rec bytes pos = function
            | [] ->
                blanks pos
            | x :: l ->
                if pos = 8 then Buffer.add_char buf ' ';
                Printf.bprintf buf "%02x " (Char.code x);
                bytes (pos + 1) l
          and blanks pos =
            if pos < 16 then begin
              if pos = 8 then
                Buffer.add_string buf "    "
              else
                Buffer.add_string buf "   ";
              blanks (pos + 1)
            end
          in
          bytes 0 l;
          Buffer.add_string buf " |";
          List.iter (fun ch -> Buffer.add_char buf (if ch >= '\x20' && ch <= '\x7e' then ch else '.')) l;
          Buffer.add_char buf '|';
          return (Some(Buffer.contents buf))
  end
