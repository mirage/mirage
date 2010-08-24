(**************************************************************************)
(*  Copyright (c) 2005 Christian Szegedy <csdontspam@metamatix.com>       *)
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

(** API for Sqlite 3.* databases *)

(** {2 Exceptions} *)

exception InternalError of string
(** [InternalError reason] is raised when the bindings detect an
    unknown/unsupported situation. *)

exception Error of string
(** [Error reason] is raised when some SQL operation is called on a
    nonexistent handle and the functions does not return a return code,
    or if there is no error code corresponding to this error.
    Functions returning return codes communicate errors by returning
    the specific error code. *)

exception RangeError of int * int
(** [RangeError (index, maximum)] is raised if some column or bind
    operation refers to a nonexistent column or binding.  The first
    entry of the returned tuple is the specified index, the second is
    the limit which was violated. *)


(** {2 Types} *)

type db
(** Database handle.  Used to store information regarding open
    databases and the error code from the last operation if the function
    implementing that operation takes a database handle as a parameter.

    NOTE: DO NOT USE THIS HANDLE WITHIN THREADS OTHER THAN THE ONE THAT
    CREATED IT!!!

    NOTE: database handles are closed (see {!db_close}) automatically
    when they are reclaimed by the GC unless they have already been
    closed earlier by the user.  It is good practice to manually close
    database handles to free resources as quickly as possible.
*)

type stmt
(** Compiled statement handle.  Stores information about compiled
    statements created by the [prepare] or [prepare_tail] functions.

    NOTE: DO NOT USE THIS HANDLE WITHIN THREADS OTHER THAN THE ONE THAT
    CREATED IT!!!
*)

type header = string
(** Type of name of a column returned by queries. *)

type headers = header array
(** Type of names of columns returned by queries. *)

type row = string option array
(** Type of row data (with potential NULL-values) *)

type row_not_null = string array
(** Type of row data (without NULL-values) *)


(** {2 Return codes} *)

module Rc : sig
  type unknown  (** Type of unknown return codes *)

  external int_of_unknown : unknown -> int = "%identity"
  (** [int_of_unknown n] converts unknown return code [rc] to an
      integer. *)

  (** Type of return codes from failed or successful operations. *)
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

  val to_string : t -> string
  (** [to_string rc] converts return code [rc] to a string. *)
end


(** {2 Column data types} *)

module Data : sig
  (** Type of columns *)
  type t =
    | NONE
    | NULL
    | INT of int64
    | FLOAT of float
    | TEXT of string
    | BLOB of string

  val to_string : t -> string
  (** [to_string data] converts [data] to a string.  Both [NONE] and
      [NULL] are converted to the empty string. *)

  val to_string_debug : t -> string
  (** [to_string_debug data] converts [data] to a string including the
      data constructor.  The contents of blobs will not be printed,
      only its length.  Useful for debugging. *)
end


(** {2 General database operations} *)

val db_open : string -> db
(** [db_open filename] opens the database file [filename], and returns
    a database handle. *)

external db_close : db -> bool = "caml_sqlite3_close"
(** [db_close db] closes database [db] and invalidates the handle.
    @return [false] if database was busy (database not closed in this
    case!), [true] otherwise.

    @raise SqliteError if an invalid database handle is passed.
*)

external enable_load_extension :
  db -> bool -> bool = "caml_sqlite3_enable_load_extension" "noalloc"
(** [enable_load_extension db onoff] enable/disable the sqlite3 load
    extension.  @return [false] if the operation fails, [true]
    otherwise. *)

external errcode : db -> Rc.t = "caml_sqlite3_errcode"
(** [errcode db] @return the error code of the last operation on database
    [db].

    @raise SqliteError if an invalid database handle is passed.
*)

external errmsg : db -> string = "caml_sqlite3_errmsg"
(** [errmsg db] @return the error message of the last operation on
    database [db].

    @raise SqliteError if an invalid database handle is passed.
*)

external last_insert_rowid : db -> int64 = "caml_sqlite3_last_insert_rowid"
(** [last_insert_rowid db] @return the index of the row inserted by
    the last operation on database [db].

    @raise SqliteError if an invalid database handle is passed.
*)

external exec :
  db -> ?cb : (row -> headers -> unit) -> string -> Rc.t = "caml_sqlite3_exec"
(** [exec db ?cb sql] performs SQL-operation [sql] on database [db].
    If the operation contains query statements, then the callback function
    [cb] will be called for each matching row.  The first parameter of
    the callback is the contents of the row, the second paramater are the
    headers of the columns associated with the row.  Exceptions raised
    within the callback will abort the execution and escape {!exec}.

    @return the return code of the operation.

    @param cb default = no callback

    @raise SqliteError if an invalid database handle is passed.
*)

external exec_no_headers :
  db -> cb : (row -> unit) -> string -> Rc.t = "caml_sqlite3_exec_no_headers"
(** [exec_no_headers db ?cb sql] performs SQL-operation [sql] on database
    [db].  If the operation contains query statements, then the callback
    function [cb] will be called for each matching row.  The parameter
    of the callback is the contents of the row.  Exceptions raised within
    the callback will abort the execution and escape {!exec_no_headers}.

    @return the return code of the operation.

    @raise SqliteError if an invalid database handle is passed.
*)

external exec_not_null :
  db -> cb : (row_not_null -> headers -> unit) -> string
  -> Rc.t = "caml_sqlite3_exec_not_null"
(** [exec_not_null db ~cb sql] performs SQL-operation [sql] on database
    [db].  If the operation contains query statements, then the callback
    function [cb] will be called for each matching row.  The first
    parameter of the callback is the contents of the row, which must
    not contain NULL-values, the second paramater are the headers of
    the columns associated with the row.  Exceptions raised within the
    callback will abort the execution and escape {!exec_not_null}.

    @return the return code of the operation.

    @raise SqliteError if an invalid database handle is passed.
    @raise SqliteError if a row contains NULL.
*)

external exec_not_null_no_headers :
  db -> cb : (row_not_null -> unit) -> string
  -> Rc.t = "caml_sqlite3_exec_not_null_no_headers"
(** [exec_not_null_no_headers db ~cb sql] performs SQL-operation [sql]
    on database [db].  If the operation contains query statements, then
    the callback function [cb] will be called for each matching row.
    The parameter of the callback is the contents of the row, which must
    not contain NULL-values.  Exceptions raised within the callback will
    abort the execution and escape {!exec_not_null_no_headers}.

    @return the return code of the operation.

    @raise SqliteError if an invalid database handle is passed.
    @raise SqliteError if a row contains NULL.
*)

external changes : db -> int = "caml_sqlite3_changes"
(** [changes db] @return the number of rows that were changed
    or inserted or deleted by the most recently completed SQL statement
    on database [db].
*)


(** {2 Fine grained query operations} *)

external prepare : db -> string -> stmt = "caml_sqlite3_prepare"
(** [prepare db sql] compile SQL-statement [sql] for database [db]
    into bytecode.  The statement may be only partially compiled.
    In this case {!prepare_tail} can be called on the returned statement
    to compile the remaining part of the SQL-statement.

    NOTE: this really uses the C-function [sqlite3_prepare_v2],
    i.e. avoids the older, deprecated [sqlite3_prepare]-function.

    @raise SqliteError if an invalid database handle is passed.
    @raise SqliteError if the statement could not be prepared.
*)

external prepare_tail : stmt -> stmt option = "caml_sqlite3_prepare_tail"
(** [prepare_tail stmt] compile the remaining part of the SQL-statement
    [stmt] to bytecode.  @return [None] if there was no remaining part,
    or [Some remaining_part] otherwise.

    NOTE: this really uses the C-function [sqlite3_prepare_v2],
    i.e. avoids the older, deprecated [sqlite3_prepare]-function.

    @raise SqliteError if the statement could not be prepared.
*)

external recompile : stmt -> unit = "caml_sqlite3_recompile"
(** [recompile stmt] recompiles the SQL-statement associated with [stmt]
    to bytecode.  The statement may be only partially compiled.  In this
    case {!prepare_tail} can be called on the statement to compile the
    remaining part of the SQL-statement.  Call this function if the
    statement expires due to some schema change.

    @raise SqliteError if the statement could not be recompiled.
*)

external step : stmt -> Rc.t = "caml_sqlite3_step"
(** [step stmt] performs one step of the query associated with
    SQL-statement [stmt].

    @return the return code of this operation.

    @raise SqliteError if the step could not be executed.
*)

external finalize : stmt -> Rc.t = "caml_sqlite3_stmt_finalize"
(** [finalize stmt] finalizes the statement [stmt].  After finalization,
    the only valid usage of the statement is to use it in {!prepare_tail},
    or to {!recompile} it.

    @return the return code of this operation.

    @raise SqliteError if the statement could not be finalized.
*)

external reset : stmt -> Rc.t = "caml_sqlite3_stmt_reset"
(** [reset stmt] resets the statement [stmt], e.g. to restart the query,
    perhaps with different bindings.

    @return the return code of this operation.

    @raise SqliteError if the statement could not be reset.
*)


(** {2 Data query} *)

external data_count : stmt -> int = "caml_sqlite3_data_count"
(** [data_count stmt] @return the number of columns in the result of
    the last step of statement [stmt].

    @raise SqliteError if the statement is invalid.
*)

external column_count : stmt -> int = "caml_sqlite3_column_count"
(** [column_count stmt] @return the number of columns that would be
    returned by executing statement [stmt].

    @raise SqliteError if the statement is invalid.
*)

external column : stmt -> int -> Data.t = "caml_sqlite3_column"
(** [column stmt n] @return the data in column [n] of the
    result of the last step of statement [stmt].

    @raise RangeError if [n] is out of range.
    @raise SqliteError if the statement is invalid.
*)

external column_name : stmt -> int -> header = "caml_sqlite3_column_name"
(** [column_name stmt n] @return the header of column [n] in the
    result set of statement [stmt].

    @raise RangeError if [n] is out of range.
    @raise SqliteError if the statement is invalid.
*)

external column_decltype :
  stmt -> int -> string option = "caml_sqlite3_column_decltype"
(** [column_decltype stmt n] @return the declared type of the specified
    column in the result set of statement [stmt].

    @raise RangeError if [n] is out of range.
    @raise SqliteError if the statement is invalid.
*)


(** {2 Binding data to the query} *)

external bind : stmt -> int -> Data.t -> Rc.t = "caml_sqlite3_bind"
(** [bind stmt n data] binds the value [data] to the free variable at
    position [n] of statement [stmt].  NOTE: the first variable has
    index [1]!

    @return the return code of this operation.

    @raise RangeError if [n] is out of range.
    @raise SqliteError if the statement is invalid.
*)

external bind_parameter_count :
  stmt -> int = "caml_sqlite3_bind_parameter_count"
(** [bind_parameter_count stmt] @return the number of free variables in
    statement [stmt].

    @raise SqliteError if the statement is invalid.
*)

external bind_parameter_name :
  stmt -> int -> string option = "caml_sqlite3_bind_parameter_name"
(** [bind_parameter_name stmt n] @return [Some parameter_name] of the free
    variable at position [n] of statement [stmt], or [None] if it is
    ordinary ("?").

    @raise RangeError if [n] is out of range.
    @raise SqliteError if the statement is invalid.
*)

external bind_parameter_index :
  stmt -> string -> int = "caml_sqlite3_bind_parameter_index"
(** [bind_parameter_index stmt name] @return the position of the free
    variable with name [name] in statement [stmt].

    @raise Not_found if [name] was not found.
    @raise SqliteError if the statement is invalid.
*)

(* TODO: these give linking errors on some platforms *)
(* external sleep : int -> int = "caml_sqlite3_sleep" *)
(* external clear_bindings : stmt -> Rc.t = "caml_sqlite3_clear_bindings" *)


(** {2 Stepwise query convenience functions} *)

val row_data : stmt -> Data.t array
(** [row_data stmt] @return all data values in the row returned by the
    last query step performed with statement [stmt].

    @raise SqliteError if the statement is invalid.
*)

val row_names : stmt -> headers
(** [row_names stmt] @return all column headers of the row returned by the
    last query step performed with statement [stmt].

    @raise SqliteError if the statement is invalid.
*)

val row_decltypes : stmt -> string option array
(** [row_decltypes stmt] @return all column type declarations of the
    row returned by the last query step performed with statement [stmt].

    @raise SqliteError if the statement is invalid.
*)


(** {2 User-defined functions} *)

val create_funN : db -> string -> (Data.t array -> Data.t) -> unit
(** [create_funN db name f] registers function [f] under name [name]
    with database handle [db].  The function has arity [N].

    @raise SqliteError if an invalid database handle is passed.
*)

val create_fun0 : db -> string -> (unit -> Data.t) -> unit
(** [create_funN db name f] registers function [f] under name [name]
    with database handle [db].  The function has arity [0].

    @raise SqliteError if an invalid database handle is passed.
*)

val create_fun1 : db -> string -> (Data.t -> Data.t) -> unit
(** [create_fun1 db name f] registers function [f] under name [name]
    with database handle [db].  The function has arity [1].

    @raise SqliteError if an invalid database handle is passed.
*)

val create_fun2 : db -> string -> (Data.t -> Data.t -> Data.t) -> unit
(** [create_fun2 db name f] registers function [f] under name [name]
    with database handle [db].  The function has arity [2].

    @raise SqliteError if an invalid database handle is passed.
*)

val create_fun3 : db -> string -> (Data.t -> Data.t -> Data.t-> Data.t) -> unit
(** [create_fun3 db name f] registers function [f] under name [name]
    with database handle [db].  The function has arity [3].

    @raise SqliteError if an invalid database handle is passed.
*)

external delete_function : db -> string -> unit = "caml_sqlite3_delete_function"
(** [delete_function db name] deletes function with name [name] from
    database handle [db].

    @raise SqliteError if an invalid database handle is passed.
*)

val busy_timeout : db -> int -> unit
(** [busy_timeout db ms] sets a busy handler that sleeps for a
    specified amount of time when a table is locked.  The handler will
    sleep multiple times until at least [ms] milliseconds of sleeping
    have accumulated.

    @raise SqliteError if an invalid database handle is passed.
*)

module Aggregate : sig
  val create_fun0 :
    db -> string ->
    init : 'a ->
    step : ('a -> 'a) ->
    final : ('a -> Data.t) -> unit
  (** [create_fun0 db name ~init ~step ~final] registers the step and
      finalizer functions under name [name] with database handle [db].
      This function has arity [0].

      @raise SqliteError if an invalid database handle is passed.
  *)

  val create_fun1 :
    db -> string ->
    init : 'a ->
    step : ('a -> Data.t -> 'a) ->
    final : ('a -> Data.t) -> unit
  (** [create_fun1 db name ~init ~step ~final] registers the step and
      finalizer functions under name [name] with database handle [db].
      This function has arity [1].

      @raise SqliteError if an invalid database handle is passed.
  *)

  val create_fun2 :
    db -> string ->
    init : 'a ->
    step : ('a -> Data.t -> Data.t -> 'a) ->
    final : ('a -> Data.t) -> unit
  (** [create_fun2 db name ~init ~step ~final] registers the step and
      finalizer functions under name [name] with database handle [db].
      This function has arity [2].

      @raise SqliteError if an invalid database handle is passed.
  *)

  val create_fun3 :
    db -> string ->
    init : 'a ->
    step : ('a -> Data.t -> Data.t -> Data.t -> 'a) ->
    final : ('a -> Data.t) -> unit
  (** [create_fun3 db name ~init ~step ~final] registers the step and
      finalizer functions under name [name] with database handle [db].
      This function has arity [3].

      @raise SqliteError if an invalid database handle is passed.
  *)

  val create_funN :
    db -> string ->
    init : 'a ->
    step : ('a -> Data.t array -> 'a) ->
    final : ('a -> Data.t) -> unit
  (** [create_funN db name ~init ~step ~final] registers the step and
      finalizer functions under name [name] with database handle [db].
      This function has arity [N].

      @raise SqliteError if an invalid database handle is passed.
  *)
end
