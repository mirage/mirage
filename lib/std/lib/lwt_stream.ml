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

exception Empty

type 'a t = {
  next : unit -> 'a option Lwt.t;
  (* The source of the stream *)
  queue : 'a option Queue.t;
  (* Queue of pending elements, which are not yet consumed *)
  clones : 'a option Queue.t Weak.t ref;
  (* List of queues of all clones of this event (including this
     event) *)
  mutex : Lwt_mutex.t;
  (* Mutex to prevent concurrent access to [next] *)
}

let add_clone wa q =
  let len = Weak.length !wa in
  (* loop search for a free cell in [wa] and fill it with [q]: *)
  let rec loop i =
    if i = len then begin
      (* Growing *)
      let clones = Weak.create (len + 1) in
      Weak.blit !wa 0 clones 0 len;
      wa := clones;
      Weak.set clones len (Some q)
    end else if Weak.check !wa i then
      loop (i + 1)
    else
      Weak.set !wa i (Some q)
  in
  loop 0

let clone s =
  let s' = {
    next = s.next;
    queue = Queue.copy s.queue;
    clones = s.clones;
    mutex = s.mutex;
  } in
  add_clone s'.clones s'.queue;
  s'

let from f =
  let s = {
    next = f;
    queue = Queue.create ();
    clones = ref(Weak.create 1);
    mutex = Lwt_mutex.create ();
  } in
  Weak.set !(s.clones) 0 (Some s.queue);
  s

let of_list l =
  let l = ref l in
  from (fun () ->
          match !l with
            | [] -> return None
            | x :: l' -> l := l'; return (Some x))

let of_array a =
  let len = Array.length a and i = ref 0 in
  from (fun () ->
          if !i = len then
            return None
          else begin
            let c = Array.unsafe_get a !i in
            incr i;
            return (Some c)
          end)

let of_string s =
  let len = String.length s and i = ref 0 in
  from (fun () ->
          if !i = len then
            return None
          else begin
            let c = String.unsafe_get s !i in
            incr i;
            return (Some c)
          end)

module EQueue :
sig
  type 'a t
  val create : unit -> 'a t * ('a option -> unit)
  val pop : 'a t -> 'a option Lwt.t
end =
struct
  type 'a state =
    | No_mail
    | Waiting of 'a option Lwt.u
    | Full of 'a option Queue.t

  type 'a t = {
    mutable state : 'a state;
  }

  let create () =
    let box = { state = No_mail } in
    let push v =
      match box.state with
	| No_mail ->
	    let q = Queue.create () in
	    Queue.push v q;
	    box.state <- Full q
	| Waiting wakener ->
            box.state <- No_mail;
            wakeup wakener v
	| Full q ->
	    Queue.push v q
    in
    (box, push)

  let pop b = match b.state with
    | No_mail ->
	let waiter, wakener = task () in
        Lwt.on_cancel waiter (fun () -> b.state <- No_mail);
	b.state <- Waiting wakener;
	waiter
    | Waiting _ ->
        (* Calls to next are serialized, so this case will never
           happened *)
	assert false
    | Full q ->
	let v = Queue.take q in
	if Queue.is_empty q then b.state <- No_mail;
        return v
end

let create () =
  let box, push = EQueue.create () in
  (from (fun () -> EQueue.pop box), push)

let push_clones wa x =
  for i = 0 to Weak.length wa - 1 do
    match Weak.get wa i with
      | Some q ->
          Queue.push x q
      | None ->
          ()
  done

let peek s =
  if Queue.is_empty s.queue then
    Lwt_mutex.with_lock s.mutex begin fun () ->
      if Queue.is_empty s.queue then begin
        lwt result = s.next () in
        push_clones !(s.clones) result;
        return result
      end else
        return (Queue.top s.queue)
    end
  else
    return (Queue.top s.queue)

let rec force n s =
  if Queue.length s.queue >= n then
    return ()
  else
    Lwt_mutex.with_lock s.mutex begin fun () ->
      if Queue.length s.queue >= n then
        return false
      else begin
        lwt result = s.next () in
        push_clones !(s.clones) result;
        if result = None then
          return false
        else
          return true
      end
    end >>= function
      | true ->
          force n s
      | false ->
          return ()

let npeek n s =
  lwt () = force n s in
  let l, _ =
    Queue.fold
      (fun (l, n) x ->
         if n > 0 then
           match x with
             | Some x ->  (x :: l, n - 1)
             | None -> (l, n)
         else
           (l, n))
      ([], n) s.queue
  in
  return (List.rev l)

let rec get s =
  if Queue.is_empty s.queue then
    Lwt_mutex.with_lock s.mutex begin fun () ->
      if Queue.is_empty s.queue then begin
        lwt x = s.next () in
        (* This prevent from calling s.next when the stream has
           terminated: *)
        if x = None then Queue.push None s.queue;
        let wa = !(s.clones) in
        for i = 0 to Weak.length wa - 1 do
          match Weak.get wa i with
            | Some q when q != s.queue ->
                Queue.push x q
            | _ ->
                ()
        done;
        return x
      end else begin
        let x = Queue.take s.queue in
        if x = None then Queue.push None s.queue;
        return x
      end
    end
  else begin
    let x = Queue.take s.queue in
    if x = None then Queue.push None s.queue;
    return x
  end

let nget n s =
  let rec loop n =
    if n <= 0 then
      return []
    else
      get s >>= function
        | Some x ->
            lwt l = loop (n - 1) in
            return (x :: l)
        | None ->
            return []
  in
  loop n

let get_while f s =
  let rec loop () =
    peek s >>= function
      | Some x ->
          let test = f x in
          if test then begin
            ignore (Queue.take s.queue);
            lwt l = loop () in
            return (x :: l)
          end else
            return []
      | None ->
          return []
  in
  loop ()

let get_while_s f s =
  let rec loop () =
    peek s >>= function
      | Some x ->
          lwt test = f x in
          if test then begin
            ignore (Queue.take s.queue);
            lwt l = loop () in
            return (x :: l)
          end else
            return []
      | None ->
          return []
  in
  loop ()

let next s = get s >>= function
  | Some x -> return x
  | None -> raise_lwt Empty

let last_new s =
  match Lwt.state (peek s) with
    | Return None ->
        raise_lwt Empty
    | Sleep ->
        next s
    | Fail exn ->
        raise_lwt exn
    | Return(Some x) ->
        let _ = Queue.take s.queue in
        let rec loop last =
          match Lwt.state (peek s) with
            | Sleep | Return None ->
                return last
            | Return(Some x) ->
                let _ = Queue.take s.queue in
                loop x
            | Fail exn ->
                raise_lwt exn
        in
        loop x

let to_list s =
  let rec loop () =
    get s >>= function
      | Some x ->
          lwt l = loop () in
          return (x :: l)
      | None ->
          return []
  in
  loop ()

let to_string s =
  let buf = Buffer.create 42 in
  let rec loop () =
    get s >>= function
      | Some x ->
          Buffer.add_char buf x;
          loop ()
      | None ->
          return (Buffer.contents buf)
  in
  loop ()

let junk s =
  lwt _ = get s in
  return ()

let njunk n s =
  let rec loop n =
    if n <= 0 then
      return ()
    else
      lwt _ = get s in
      loop (n - 1)
  in
  loop n

let junk_while f s =
  let rec loop () =
    peek s >>= function
      | Some x ->
          let test = f x in
          if test then begin
            ignore (Queue.take s.queue);
            loop ()
          end else
            return ()
      | None ->
          return ()
  in
  loop ()

let junk_while_s f s =
  let rec loop () =
    peek s >>= function
      | Some x ->
          lwt test = f x in
          if test then begin
            ignore (Queue.take s.queue);
            loop ()
          end else
            return ()
      | None ->
          return ()
  in
  loop ()

let junk_old s =
  let rec loop () =
    match Lwt.state (peek s) with
      | Sleep ->
          return ()
      | _ ->
          ignore (Queue.take s.queue);
          loop ()
  in
  loop ()

let get_available s =
  let rec loop () =
    match Lwt.state (peek s) with
      | Sleep | Return None ->
          []
      | Return(Some x) ->
          ignore (Queue.take s.queue);
          x :: loop ()
      | Fail exn ->
          raise exn
  in
  loop ()

let get_available_up_to n s =
  let rec loop = function
    | 0 ->
        []
    | n ->
        match Lwt.state (peek s) with
          | Sleep | Return None ->
              []
          | Return(Some x) ->
              ignore (Queue.take s.queue);
              x :: loop (n - 1)
          | Fail exn ->
              raise exn
  in
  loop n

let is_empty s = peek s >|= fun x -> x = None

let map f s =
  from (fun () -> get s >>= function
          | Some x ->
              let x = f x in
              return (Some x)
          | None ->
              return None)

let map_s f s =
  from (fun () -> get s >>= function
          | Some x ->
              lwt x = f x in
              return (Some x)
          | None ->
              return None)

let filter f s =
  let rec next () =
    get s >>= function
      | Some x as result ->
          let test = f x in
          if test then
            return result
          else
            next ()
      | None ->
          return None
  in
  from next

let filter_s f s =
  let rec next () =
    get s >>= function
      | Some x as result ->
          lwt test = f x in
          if test then
            return result
          else
            next ()
      | None ->
          return None
  in
  from next

let filter_map f s =
  let rec next () =
    get s >>= function
      | Some x ->
          let x = f x in
          (match x with
             | Some _ ->
                 return x
             | None ->
                 next ())
      | None ->
          return None
  in
  from next

let filter_map_s f s =
  let rec next () =
    get s >>= function
      | Some x ->
          lwt x = f x in
          (match x with
             | Some _ ->
                 return x
             | None ->
                 next ())
      | None ->
          return None
  in
  from next

let map_list f s =
  let pendings = ref [] in
  let rec next () =
    match !pendings with
      | [] ->
          get s >>= (function
                                | Some x ->
                                    let l = f x in
                                    pendings := l;
                                    next ()
                                | None ->
                                    return None)
      | x :: l ->
          pendings := l;
          return (Some x)
  in
  from next

let map_list_s f s =
  let pendings = ref [] in
  let rec next () =
    match !pendings with
      | [] ->
          get s >>= (function
                       | Some x ->
                           lwt l = f x in
                           pendings := l;
                           next ()
                       | None ->
                           return None)
      | x :: l ->
          pendings := l;
          return (Some x)
  in
  from next

let flatten s =
  map_list (fun l -> l) s

let fold f s acc =
  let rec loop acc =
    get s >>= function
      | Some x ->
          let acc = f x acc in
          loop acc
      | None ->
          return acc
  in
  loop acc

let fold_s f s acc =
  let rec loop acc =
    get s >>= function
      | Some x ->
          lwt acc = f x acc in
          loop acc
      | None ->
          return acc
  in
  loop acc

let iter f s =
  let rec loop () =
    get s >>= function
      | Some x ->
          let () = f x in
          loop ()
      | None ->
          return ()
  in
  loop ()

let iter_s f s =
  let rec loop () =
    get s >>= function
      | Some x ->
          lwt () = f x in
          loop ()
      | None ->
          return ()
  in
  loop ()

let iter_p f s =
  let rec loop () =
    get s >>= function
      | Some x ->
          f x <&> loop ()
      | None ->
          return ()
  in
  loop ()

let find f s =
  let rec loop () =
    get s >>= function
      | Some x as result ->
          let test = f x in
          if test then
            return result
          else
            loop ()
      | None ->
          return None
  in
  loop ()

let find_s f s =
  let rec loop () =
    get s >>= function
      | Some x as result ->
          lwt test = f x in
          if test then
            return result
          else
            loop ()
      | None ->
          return None
  in
  loop ()

let rec find_map f s =
  let rec loop () =
    get s >>= function
      | Some x ->
          let x = f x in
          (match x with
             | Some _ ->
                 return x
             | None ->
                 loop ())
      | None ->
          return None
  in
  loop ()

let rec find_map_s f s =
  let rec loop () =
    get s >>= function
      | Some x ->
          lwt x = f x in
          (match x with
             | Some _ ->
                 return x
             | None ->
                 loop ())
      | None ->
          return None
  in
  loop ()

let rec combine s1 s2 =
  let next () =
    lwt n1 = get s1 and n2 = get s2 in
    match n1, n2 with
      | Some x1, Some x2 ->
          return (Some(x1, x2))
      | _ ->
          return None
  in
  from next

let append s1 s2 =
  let current_s = ref s1 and s1_finished = ref false in
  let rec next () =
    get !current_s >>= function
      | Some _ as result ->
          return result
      | None ->
          if !s1_finished then
            return None
          else begin
            s1_finished := true;
            current_s := s2;
            next ()
          end
  in
  from next

let concat s_top =
  let current_s = ref(from(fun () -> return None)) in
  let rec next () =
    get !current_s >>= function
      | Some _ as result ->
          return result
      | None ->
          get s_top >>= function
            | Some s ->
                current_s := s;
                next ()
            | None ->
                return None
  in
  from next

let choose streams =
  let source s = (s, peek s >|= fun x -> (s, x)) in
  let streams = ref (List.rev_map source streams) in
  let rec next () =
    match !streams with
      | [] ->
          return None
      | l ->
          lwt s, x = Lwt.choose (List.map snd l) in
          let l = List.remove_assq s l in
          match x with
            | Some _ ->
                lwt () = junk s in
                streams := source s :: l;
                return x
            | None ->
                next ()
  in
  from next

let parse s f =
  let s' = clone s in
  try_lwt
    f s
  with exn ->
    Queue.clear s.queue;
    Queue.transfer s'.queue s.queue;
    raise_lwt exn

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
