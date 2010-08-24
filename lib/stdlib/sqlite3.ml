(**************************************************************************)
(*  Copyright (c) 2003 Christian Szegedy <csdontspam871@metamatix.org>    *)
(*                                                                        *)
(*  Copyright (c) 2007 Jane Street Holding, LLC                           *)
(*                     Author: Markus Mottl <markus.mottl@gmail.com>      *)
(*                                                                        *)
(*  Permission is hereby granted, free of charge, to any person           *)
(*  obtaining a copy of this software and associated documentation files  *)
(*  (the "Software"), to deal in the Software without restriction,        *)
(*  including without limitation the rights to use, copy, modify, merge,  *)
(*  publish, distribute, sublicense, and/or sell copies of the Software,  *)
(*  and to permit persons to whom the Software is furnished to do so,     *)
(*  subject to the following conditions:                                  *)
(*                                                                        *)
(*  The above copyright notice and this permission notice shall be        *)
(*  included in all copies or substantial portions of the Software.       *)
(*                                                                        *)
(*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       *)
(*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES       *)
(*  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              *)
(*  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS   *)
(*  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN    *)
(*  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN     *)
(*  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE      *)
(*  SOFTWARE.                                                             *)
(**************************************************************************)

open Pervasives
open Printf

exception InternalError of string
exception Error of string
exception RangeError of int * int

type db
type stmt

module Rc = struct
  type unknown

  external int_of_unknown : unknown -> int = "%identity"

  type t =
    | OK
    | ERROR
    | INTERNAL
    | PERM
    | ABORT
    | BUSY
    | LOCKED
    | NOMEM
    | READONLY
    | INTERRUPT
    | IOERR
    | CORRUPT
    | NOTFOUND
    | FULL
    | CANTOPEN
    | PROTOCOL
    | EMPTY
    | SCHEMA
    | TOOBIG
    | CONSTRAINT
    | MISMATCH
    | MISUSE
    | NOFLS
    | AUTH
    | FORMAT
    | RANGE
    | NOTADB
    | ROW
    | DONE
    | UNKNOWN of unknown

  let to_string = function
    | OK -> "OK"
    | ERROR -> "ERROR"
    | INTERNAL -> "INTERNAL"
    | PERM -> "PERM"
    | ABORT  -> "ABORT"
    | BUSY  -> "BUSY"
    | LOCKED -> "LOCKED"
    | NOMEM -> "NOMEM"
    | READONLY -> "READONLY"
    | INTERRUPT -> "INTERRUPT"
    | IOERR -> "IOERR"
    | CORRUPT -> "CORRUPT"
    | NOTFOUND -> "NOTFOUND"
    | FULL -> "FULL"
    | CANTOPEN -> "CANTOPEN"
    | PROTOCOL -> "PROTOCOL"
    | EMPTY -> "EMPTY"
    | SCHEMA -> "SCHEMA"
    | TOOBIG -> "TOOBIG"
    | CONSTRAINT -> "CONSTRAINT"
    | MISMATCH -> "MISMATCH"
    | MISUSE -> "MISUSE"
    | NOFLS -> "NOLFS"
    | AUTH -> "AUTH"
    | FORMAT -> "FORMAT"
    | RANGE -> "RANGE"
    | NOTADB -> "NOTADB"
    | ROW -> "ROW"
    | DONE -> "DONE"
    | UNKNOWN n -> sprintf "UNKNOWN %d" (int_of_unknown n)
end

module Data = struct
  type t =
    | NONE
    | NULL
    | INT of int64
    | FLOAT of float
    | TEXT of string
    | BLOB of string

  let to_string = function
    | NONE | NULL -> ""
    | INT i -> Int64.to_string i
    | FLOAT f -> string_of_float f
    | TEXT t | BLOB t -> t

  let to_string_debug = function
    | NONE -> "NONE"
    | NULL -> "NULL"
    | INT i -> sprintf "INT <%Ld>" i
    | FLOAT f -> sprintf "FLOAT <%f>" f
    | TEXT t -> sprintf "TEXT <%S>" t
    | BLOB b -> sprintf "BLOB <%d>" (String.length b)
end

type header = string
type headers = header array
type row = string option array
type row_not_null = string array

external db_close : db -> bool = "caml_sqlite3_close"

external errcode : db -> Rc.t = "caml_sqlite3_errcode"
external errmsg : db -> string = "caml_sqlite3_errmsg"
external last_insert_rowid : db -> int64 = "caml_sqlite3_last_insert_rowid"

external exec :
  db -> ?cb : (string option array -> headers -> unit) -> string -> Rc.t
  = "caml_sqlite3_exec"

external exec_no_headers :
  db -> cb : (string option array -> unit) -> string -> Rc.t
  = "caml_sqlite3_exec_no_headers"

external exec_not_null :
  db -> cb : (string array -> headers -> unit) -> string -> Rc.t
  = "caml_sqlite3_exec_not_null"

external exec_not_null_no_headers :
  db -> cb : (string array -> unit) -> string -> Rc.t
  = "caml_sqlite3_exec_not_null_no_headers"

(* XXX for Mirage, ensure journaling is in memory only until
   unaligned writes work *)
external _db_open : string -> db = "caml_sqlite3_open"
let db_open file =
  let db = _db_open file in 
  match exec db "PRAGMA journal_mode=truncate" with
  |Rc.OK -> db
  |_ -> failwith "pragma failed"

external changes : db -> int = "caml_sqlite3_changes"

external prepare : db -> string -> stmt = "caml_sqlite3_prepare"
external prepare_tail : stmt -> stmt option = "caml_sqlite3_prepare_tail"
external recompile : stmt -> unit = "caml_sqlite3_recompile"

external step : stmt -> Rc.t = "caml_sqlite3_step"
external reset : stmt -> Rc.t = "caml_sqlite3_stmt_reset"
external finalize : stmt -> Rc.t = "caml_sqlite3_stmt_finalize"

external data_count : stmt -> int = "caml_sqlite3_data_count"
external column_count : stmt -> int = "caml_sqlite3_column_count"
external column : stmt -> int -> Data.t = "caml_sqlite3_column"
external column_name : stmt -> int -> string = "caml_sqlite3_column_name"

external column_decltype :
  stmt -> int -> string option = "caml_sqlite3_column_decltype"

external bind : stmt -> int -> Data.t -> Rc.t = "caml_sqlite3_bind"

external bind_parameter_count :
  stmt -> int = "caml_sqlite3_bind_parameter_count"

external bind_parameter_name :
  stmt -> int -> string option = "caml_sqlite3_bind_parameter_name"

external bind_parameter_index :
  stmt -> string -> int = "caml_sqlite3_bind_parameter_index"

external busy_timeout : db -> int -> unit = "caml_sqlite3_busy_timeout"

external enable_load_extension :
  db -> bool -> bool = "caml_sqlite3_enable_load_extension" "noalloc"

(* TODO: these give linking errors on some platforms *)
(* external sleep : int -> int = "caml_sqlite3_sleep" *)
(* external clear_bindings : stmt -> Rc.t = "caml_sqlite3_clear_bindings" *)

let row_data stmt = Array.init (data_count stmt) (column stmt)
let row_names stmt = Array.init (data_count stmt) (column_name stmt)
let row_decltypes stmt = Array.init (data_count stmt) (column_decltype stmt)


(* Function registration *)

external create_function :
  db -> string -> int -> (Data.t array -> Data.t) -> unit =
  "caml_sqlite3_create_function"

let create_funN db name f = create_function db name (-1) f
let create_fun0 db name f = create_function db name 0 (fun _ -> f ())
let create_fun1 db name f = create_function db name 1 (fun args -> f args.(0))

let create_fun2 db name f =
  create_function db name 2 (fun args -> f args.(0) args.(1))

let create_fun3 db name f =
  create_function db name 3 (fun args -> f args.(0) args.(1) args.(2))

external delete_function : db -> string -> unit = "caml_sqlite3_delete_function"

module Aggregate = struct
  external create_function :
    db -> string -> int ->
    'a -> ('a -> Data.t array -> 'a) -> ('a -> Data.t) -> unit =
    "caml_sqlite3_create_aggregate_function_bc"
    "caml_sqlite3_create_aggregate_function_nc"

  let create_funN db name ~init ~step ~final =
    create_function db name (-1) init step final

  let create_fun0 db name ~init ~step ~final =
    create_function db name 0 init (fun acc _ -> step acc) final

  let create_fun1 db name ~init ~step ~final =
    create_function db name 1 init (fun acc args -> step acc args.(0)) final

  let create_fun2 db name ~init ~step ~final =
    create_function db name 2 init
      (fun acc args -> step acc args.(0) args.(1)) final

  let create_fun3 db name ~init ~step ~final =
    create_function db name 3 init
      (fun acc args -> step acc args.(0) args.(1) args.(2)) final
end


(* Initialisation *)

external init : unit -> unit = "caml_sqlite3_init"

let () =
  Callback.register_exception "Sqlite3.InternalError" (InternalError "");
  Callback.register_exception "Sqlite3.Error" (Error "");
  Callback.register_exception "Sqlite3.RangeError" (RangeError (0, 0));
  init ()
