(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Pa_lwt
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

(** Syntactic sugars for lwt *)

(** This extension add the following sugars:

    - anonymous bind:

      {[
         put_string stdio "Hello, " >>
         put_string stdio "world!" >>
         x := 1;
         sleep 1.0 >>
         return 1
      ]}

    - lwt-binding:

      {[
         lwt ch = get_char stdin in
         code
      ]}

      is the same as [bind (get_char stdin) (fun ch -> code)]

      Moreover it supports parallel binding:

      {[
         lwt x = do_something1 ()
         and y = do_something2 in
         code
      ]}

      will let [do_something1 ()] and [do_something2 ()] runs then
      bind their result to [x] and [y]. It is the same as:

      {[
         let t1 = do_something1
         and t2 = do_something2 in
         bind t1 (fun x -> bind t2 (fun y -> code))
      ]}

    - exception catching:

      {[
         try_lwt
           <expr>
      ]},

      {[
         try_lwt
           <expr>
         with
           <branches>
      ]},

      {[
         try_lwt
           <expr>
         finally
           <expr>
       ]}

    and:

      {[
         try_lwt
           <expr>
         with
           <branches>
         finally
           <expr>
      ]}

    For example:

      {[
         try_lwt
           f x
         with
           | Failure msg ->
               prerr_endline msg;
               return ()
      ]}

    is expanded to:

      {[
         catch (fun _ -> f x)
           (function
              | Failure msg ->
                  prerr_endline msg;
                  return ()
              | exn ->
                  Lwt.fail exn)
      ]}

    Note that the [exn -> Lwt.fail exn] branch is automatically addedd
    when needed.

    The construction [try_lwt <expr>] just catch regular exception
    into lwt exception. i.e. it is the same as [catch (fun _ -> <expr>) fail].

    - for loop:

      {[
        for_lwt i = <expr> to <expr> do
          <expr>
        done
      ]}

    and:

      {[
        for_lwt i = <expr> downto <expr> do
          <expr>
        done
      ]}

    - iteration over streams:

      {[
        for_lwt <patt> in <expr> do
          <expr>
        done
      ]}
*)
