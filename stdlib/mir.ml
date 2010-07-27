open Pervasives
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../../LICENSE.  *)
(*                                                                     *)
(***********************************************************************)

(* $Id: unix.ml,v 1.68 2008/08/01 13:46:08 xleroy Exp $ *)

type error =
    E2BIG
  | EACCES
  | EAGAIN
  | EBADF
  | EBUSY
  | ECHILD
  | EDEADLK
  | EDOM
  | EEXIST
  | EFAULT
  | EFBIG
  | EINTR
  | EINVAL
  | EIO
  | EISDIR
  | EMFILE
  | EMLINK
  | ENAMETOOLONG
  | ENFILE
  | ENODEV
  | ENOENT
  | ENOEXEC
  | ENOLCK
  | ENOMEM
  | ENOSPC
  | ENOSYS
  | ENOTDIR
  | ENOTEMPTY
  | ENOTTY
  | ENXIO
  | EPERM
  | EPIPE
  | ERANGE
  | EROFS
  | ESPIPE
  | ESRCH
  | EXDEV
  | EWOULDBLOCK
  | EINPROGRESS
  | EALREADY
  | ENOTSOCK
  | EDESTADDRREQ
  | EMSGSIZE
  | EPROTOTYPE
  | ENOPROTOOPT
  | EPROTONOSUPPORT
  | ESOCKTNOSUPPORT
  | EOPNOTSUPP
  | EPFNOSUPPORT
  | EAFNOSUPPORT
  | EADDRINUSE
  | EADDRNOTAVAIL
  | ENETDOWN
  | ENETUNREACH
  | ENETRESET
  | ECONNABORTED
  | ECONNRESET
  | ENOBUFS
  | EISCONN
  | ENOTCONN
  | ESHUTDOWN
  | ETOOMANYREFS
  | ETIMEDOUT
  | ECONNREFUSED
  | EHOSTDOWN
  | EHOSTUNREACH
  | ELOOP
  | EOVERFLOW
  | EUNKNOWNERR of int

exception Unix_error of error * string * string

let _ = Callback.register_exception "Unix.Unix_error"
                                    (Unix_error(E2BIG, "", ""))

external gettimeofday : unit -> float = "unix_gettimeofday"

let prettyprint s =
    let buf1 = Buffer.create 64 in
    let buf2 = Buffer.create 64 in
    let lines1 = ref [] in
    let lines2 = ref [] in
    for i = 0 to String.length s - 1 do
      if i <> 0 && (i mod 8) = 0 then begin
        lines1 := Buffer.contents buf1 :: !lines1;
        lines2 := Buffer.contents buf2 :: !lines2;
        Buffer.reset buf1;
        Buffer.reset buf2;
      end;
      let pchar c =
          let s = String.make 1 c in if Char.escaped c = s then s else "." in
      Buffer.add_string buf1 (Printf.sprintf " %02X" (int_of_char (String.get s i)));
      Buffer.add_string buf2 (Printf.sprintf " %s" (pchar (String.get s i)));
    done;
    if Buffer.length buf1 > 0 then lines1 := Buffer.contents buf1 :: !lines1;
    if Buffer.length buf2 > 0 then lines2 := Buffer.contents buf2 :: !lines2;
    Buffer.reset buf1;
    Buffer.add_char buf1 '\n';
    List.iter2 (fun l1 l2 ->
      Buffer.add_string buf1 (Printf.sprintf "   %-24s   |   %-16s   \n" l1 l2);
    ) (List.rev !lines1) (List.rev !lines2);
    Buffer.contents buf1

