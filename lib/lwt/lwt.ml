(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt
 * Copyright (C) 2005-2008 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *                    2009 Jérémie Dimino
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

exception Canceled

type +'a t
type -'a u

(* Reason for a thread to be a sleeping thread: *)
type sleep_reason =
  | Task
      (* It is a cancealable task *)
  | Wait
      (* It is a thread created with [wait] *)
  | Temp of (unit -> unit)
      (* [Temp cancel] is a temporary thread that is meant to be later
         connected to another one. [cancel] is the function used to
         cancel the thread. *)

and 'a thread_state =
  | Return of 'a
      (* [Return v] a terminated thread which has successfully
         terminated with the value [v] *)
  | Fail of exn
      (* [Fail exn] a terminated thread which has failed with the
         exception [exn] *)
  | Sleep of sleep_reason * ('a t -> unit) Lwt_sequence.t
      (* [Sleep(sleep_reason, waiters)] is a sleeping
         thread.

         - [sleep_reason] is the reason why the thread is sleeping
         - [waiters] is the list of waiters, which are thunk functions
      *)
  | Repr of 'a thread_repr
      (* [Repr t] a thread which behaves the same as [t] *)

and 'a thread_repr = 'a thread_state ref

external thread_repr : 'a t -> 'a thread_repr = "%identity"
external thread : 'a thread_repr -> 'a t = "%identity"
external wakener : 'a thread_repr -> 'a u = "%identity"
external wakener_repr : 'a u -> 'a thread_repr = "%identity"

(* Returns the represent of a thread, updating non-direct references: *)
let rec repr_rec t =
  match !t with
    | Repr t' -> let t'' = repr_rec t' in if t'' != t' then t := Repr t''; t''
    | _       -> t
let repr t = repr_rec (thread_repr t)

let run_waiters waiters t =
  Lwt_sequence.iter_l (fun f -> f (thread t)) waiters

(* Restarts a sleeping thread [t]:

   - run all its waiters
   - set his state to the terminated state [state]
*)
let restart t state caller =
  let t = repr_rec (wakener_repr t) in
  match !t with
    | Sleep((Wait | Task), waiters) ->
        t := state;
        run_waiters waiters t
    | Fail Canceled ->
        (* Do not fail if the thread has been canceled: *)
        ()
    | _ ->
        invalid_arg caller

let wakeup t v = restart t (Return v) "wakeup"
let wakeup_exn t e = restart t (Fail e) "wakeup_exn"

let cancel t =
  match !(repr t) with
    | Sleep(Task, _) ->
        wakeup_exn (wakener (thread_repr t)) Canceled
    | Sleep(Temp f, _) ->
        f ()
    | _ ->
        ()

(* Connects the two processes [t1] and [t2] when [t2] finishes up,
   where [t1] must be a sleeping thread.

   Connecting means running all the waiters for [t2] and assigning the
   state of [t2] to [t1].
*)
let rec connect t1 t2 =
  let t1 = repr t1 and t2 = repr t2 in
  match !t1 with
    | Sleep(_, waiters1) ->
        if t1 == t2 then
          (* Do nothing if the two threads already have the same
             representation *)
          ()
        else begin
          match !t2 with
            | Sleep(_, waiters2) ->
                (* If [t2] is sleeping, then makes [t1] behave as [t2]: *)
                t1 := Repr t2;
                Lwt_sequence.transfer_l waiters1 waiters2
            | state2 ->
                (* [t2] has already terminated, assing its state to [t1]: *)
                t1 := state2;
                (* and run all the waiters of [t1]: *)
                run_waiters waiters1 t1
        end
    | _ ->
        (* [t1] is not asleep: *)
        invalid_arg "connect"

let return v = thread (ref (Return v))
let fail e = thread (ref (Fail e))
let temp f = thread (ref (Sleep(Temp f, Lwt_sequence.create ())))
let wait _ =
  let t = ref (Sleep(Wait, Lwt_sequence.create ())) in (thread t, wakener t)
let task _ =
  let t = ref (Sleep(Task, Lwt_sequence.create ())) in (thread t, wakener t)

(* apply function, reifying explicit exceptions into the thread type
   apply: ('a -(exn)-> 'b t) -> ('a -(n)-> 'b t)
   semantically a natural transformation TE -> T, where T is the thread
   monad, which is layered over exception monad E.
*)
let apply f x = try f x with e -> fail e

let new_waiter waiters f =
  Lwt_sequence.add_r f waiters

let add_waiter waiters f =
  ignore (new_waiter waiters f)

let on_cancel t f =
  let t = repr t in
  match !t with
    | Sleep(_, waiters) ->
        add_waiter waiters (fun x ->
                              match !(repr x) with
                                | Fail Canceled -> (try f () with _ -> ())
                                | _ -> ())
    | Fail Canceled ->
        f ()
    | _ ->
        ()

let rec bind t f =
  match !(repr t) with
    | Return v ->
        (* we don't use apply here so that tail recursion is not
           broken *)
        f v
    | Fail e ->
        fail e
    | Sleep(_, waiters) ->
        let res = temp (fun _ -> cancel t) in
        add_waiter waiters (fun x -> connect res (bind x (apply f)));
        res
    | Repr _ ->
        assert false
let (>>=) t f = bind t f
let (=<<) f t = bind t f

let map f t = bind t (fun x -> return (f x))
let (>|=) t f = map f t
let (=|<) f t = map f t

let rec catch_rec t f =
  match !(repr t) with
    | Return v ->
        t
    | Fail e ->
        f e
    | Sleep(_, waiters) ->
        let res = temp (fun _ -> cancel t) in
        add_waiter waiters (fun x -> connect res (catch_rec x (apply f)));
        res
    | Repr _ ->
        assert false

let catch x f = catch_rec (apply x ()) f

let rec try_bind_rec t f g =
  match !(repr t) with
    | Return v ->
        f v
    | Fail e ->
        apply g e
    | Sleep(_, waiters) ->
        let res = temp (fun _ -> cancel t) in
        add_waiter waiters (fun x -> connect res (try_bind_rec x (apply f) g));
        res
    | Repr _ ->
        assert false

let try_bind x f = try_bind_rec (apply x ()) f

let poll t =
  match !(repr t) with
    | Fail e -> raise e
    | Return v -> Some v
    | Sleep _ -> None
    | Repr _ -> assert false

let rec ignore_result t =
  match !(repr t) with
    | Return v ->
        ()
    | Fail e ->
        raise e
    | Sleep(_, waiters) ->
        add_waiter waiters (fun x -> ignore_result x)
    | Repr _ ->
        assert false

let rec nth_ready l n =
  match l with
      [] ->
        assert false
    | x :: rem ->
        let x = repr x in
        match !x with
          | Sleep _ ->
              nth_ready rem n
          | _ when n > 0 ->
              nth_ready rem (n - 1)
          | _ ->
              thread x

let ready_count l =
  List.fold_left (fun acc x -> match !(repr x) with Sleep _ -> acc | _ -> acc + 1) 0 l

let choose l =
  let ready = ready_count l in
  if ready > 0 then
    nth_ready l (Random.int ready)
  else begin
    let res = temp (fun _ -> List.iter cancel l) in
    (* The list of nodes used for the waiter: *)
    let nodes = ref [] in
    let clear t =
      (* Removes all nodes so we do not leak memory: *)
      List.iter Lwt_sequence.remove !nodes;
      (* This will not fail because it is called at most one time,
         since all other waiters have been removed: *)
      connect res t
    in
    List.iter begin fun t ->
      match !(repr t) with
        | Sleep(_, waiters) ->
            nodes := new_waiter waiters clear :: !nodes
        | _ ->
            assert false
    end l;
    res
  end

let select l =
  let ready = ready_count l in
  if ready > 0 then
    nth_ready l (Random.int ready)
  else begin
    let res = temp (fun _ -> List.iter cancel l) in
    let nodes = ref [] in
    let clear t =
      List.iter Lwt_sequence.remove !nodes;
      (* Cancel all other threads: *)
      List.iter cancel l;
      connect res t
    in
    List.iter begin fun t ->
      match !(repr t) with
        | Sleep(_, waiters) ->
            nodes := new_waiter waiters clear :: !nodes
        | _ ->
            assert false
    end l;
    res
  end

let join l =
  let res = temp (fun _ -> List.iter cancel l)
    (* Number of threads still sleeping: *)
  and sleeping = ref 0
    (* The list of nodes used for the waiter: *)
  and nodes = ref [] in
  (* Handle the termination of one threads: *)
  let handle t = match !(repr t) with
    | Fail exn ->
        (* The thread has failed, exit immediatly without waiting for
           other threads *)
        List.iter Lwt_sequence.remove !nodes;
        connect res t
    | _ ->
        decr sleeping;
        (* Everybody has finished, we can wakeup the result: *)
        if !sleeping = 0 then connect res t
  in
  let rec bind_sleepers = function
    | [] ->
        (* If no thread is sleeping, returns now: *)
        if !sleeping = 0 then thread_repr res := Return ();
        res
    | t :: l -> match !(repr t) with
        | Fail exn ->
            (* One of the thread has already failed, fail now *)
            t
        | Sleep(_, waiters) ->
            incr sleeping;
            nodes := new_waiter waiters handle :: !nodes;
            bind_sleepers l
        | _ ->
            bind_sleepers l
  in
  bind_sleepers l

let ( <?> ) t1 t2 = choose [t1; t2]
let ( <&> ) t1 t2 = join [t1; t2]

let finalize f g =
  try_bind f
    (fun x -> g () >>= fun () -> return x)
    (fun e -> g () >>= fun () -> fail e)

module State = struct
  type 'a state =
    | Return of 'a
    | Fail of exn
    | Sleep
end

let state t = match !(repr t) with
  | Return v -> State.Return v
  | Fail exn -> State.Fail exn
  | Sleep _ -> State.Sleep
  | Repr _ -> assert false

include State
