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

external error_message : error -> string = "unix_error_message"

type file_descr = int

let stdin = 0
let stdout = 1
let stderr = 2

type open_flag =
    O_RDONLY
  | O_WRONLY
  | O_RDWR
  | O_NONBLOCK
  | O_APPEND
  | O_CREAT
  | O_TRUNC
  | O_EXCL
  | O_NOCTTY
  | O_DSYNC
  | O_SYNC
  | O_RSYNC

external close : file_descr -> unit = "unix_close"
external unsafe_read : file_descr -> string -> int -> int -> int = "unix_read"
external unsafe_write : file_descr -> string -> int -> int -> int = "unix_write"
external unsafe_single_write : file_descr -> string -> int -> int -> int = "unix_single_write"

let read fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "Unix.read"
  else unsafe_read fd buf ofs len
let write fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "Unix.write"
  else unsafe_write fd buf ofs len
(* write misbehaves because it attempts to write all data by making repeated
   calls to the Unix write function (see comment in write.c and unix.mli).
   partial_write fixes this by never calling write twice. *)
let single_write fd buf ofs len =
  if ofs < 0 || len < 0 || ofs > String.length buf - len
  then invalid_arg "Unix.single_write"
  else unsafe_single_write fd buf ofs len

external gettimeofday : unit -> float = "unix_gettimeofday"
external sleep : int -> unit = "unix_sleep"
external schedule : unit -> unit = "mirage_schedule"

type inet_addr = string

external inet_addr_of_string : string -> inet_addr
                                    = "unix_inet_addr_of_string"
external string_of_inet_addr : inet_addr -> string
                                    = "unix_string_of_inet_addr"

let inet_addr_any = inet_addr_of_string "0.0.0.0"
let inet_addr_loopback = inet_addr_of_string "127.0.0.1"

type socket_domain =
  | PF_INET

type socket_type =
    SOCK_STREAM
  | SOCK_DGRAM
  | SOCK_RAW

type sockaddr =
  | ADDR_INET of inet_addr * int

let domain_of_sockaddr = function
  | ADDR_INET(a, _) -> PF_INET

type shutdown_command =
    SHUTDOWN_RECEIVE
  | SHUTDOWN_SEND
  | SHUTDOWN_ALL

type msg_flag =
    MSG_OOB
  | MSG_DONTROUTE
  | MSG_PEEK

external socket : socket_domain -> socket_type -> int -> file_descr
                                  = "unix_socket"
external accept : file_descr -> file_descr * sockaddr = "unix_accept"
external bind : file_descr -> sockaddr -> unit = "unix_bind"
external connect : file_descr -> sockaddr -> unit = "unix_connect"
external listen : file_descr -> int -> unit = "unix_listen"
external shutdown : file_descr -> shutdown_command -> unit = "unix_shutdown" 
external getsockname : file_descr -> sockaddr = "unix_getsockname"
external getpeername : file_descr -> sockaddr = "unix_getpeername"

type socket_bool_option =
    SO_DEBUG
  | SO_BROADCAST
  | SO_REUSEADDR
  | SO_KEEPALIVE
  | SO_DONTROUTE
  | SO_OOBINLINE
  | SO_ACCEPTCONN
  | TCP_NODELAY

type socket_int_option =
    SO_SNDBUF
  | SO_RCVBUF
  | SO_ERROR
  | SO_TYPE
  | SO_RCVLOWAT
  | SO_SNDLOWAT

type socket_optint_option = SO_LINGER

type socket_float_option =
    SO_RCVTIMEO
  | SO_SNDTIMEO

type socket_error_option = SO_ERROR

module SO: sig
  type ('opt, 'v) t
  val bool: (socket_bool_option, bool) t
  val int: (socket_int_option, int) t
  val optint: (socket_optint_option, int option) t
  val float: (socket_float_option, float) t
  val error: (socket_error_option, error option) t
  val get: ('opt, 'v) t -> file_descr -> 'opt -> 'v
  val set: ('opt, 'v) t -> file_descr -> 'opt -> 'v -> unit
end = struct
  type ('opt, 'v) t = int
  let bool = 0
  let int = 1
  let optint = 2
  let float = 3
  let error = 4
  external get: ('opt, 'v) t -> file_descr -> 'opt -> 'v 
              = "unix_getsockopt"
  external set: ('opt, 'v) t -> file_descr -> 'opt -> 'v -> unit
              = "unix_setsockopt"
end

let getsockopt fd opt = SO.get SO.bool fd opt
let setsockopt fd opt v = SO.set SO.bool fd opt v

let getsockopt_int fd opt = SO.get SO.int fd opt
let setsockopt_int fd opt v = SO.set SO.int fd opt v

let getsockopt_optint fd opt = SO.get SO.optint fd opt
let setsockopt_optint fd opt v = SO.set SO.optint fd opt v

let getsockopt_float fd opt = SO.get SO.float fd opt
let setsockopt_float fd opt v = SO.set SO.float fd opt v

let getsockopt_error fd = SO.get SO.error fd SO_ERROR

