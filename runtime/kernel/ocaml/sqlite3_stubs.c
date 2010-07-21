/**************************************************************************/
/*  Copyright (c) 2005 Christian Szegedy <csdontspam871@metamatix.org>    */
/*                                                                        */
/*  Copyright (c) 2007 Jane Street Holding, LLC                           */
/*                     Author: Markus Mottl <markus.mottl@gmail.com>      */
/*                                                                        */
/*  Permission is hereby granted, free of charge, to any person           */
/*  obtaining a copy of this software and associated documentation files  */
/*  (the "Software"), to deal in the Software without restriction,        */
/*  including without limitation the rights to use, copy, modify, merge,  */
/*  publish, distribute, sublicense, and/or sell copies of the Software,  */
/*  and to permit persons to whom the Software is furnished to do so,     */
/*  subject to the following conditions:                                  */
/*                                                                        */
/*  The above copyright notice and this permission notice shall be        */
/*  included in all copies or substantial portions of the Software.       */
/*                                                                        */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/*  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES       */
/*  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              */
/*  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS   */
/*  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN    */
/*  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN     */
/*  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE      */
/*  SOFTWARE.                                                             */
/**************************************************************************/

#include <stdio.h>
#include <string.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/signals.h>

#include <sqlite3.h>

#if __GNUC__ >= 3
# define inline inline __attribute__ ((always_inline))
# if !defined(__FreeBSD__) && !__APPLE__
# define __unused __attribute__ ((unused))
# endif
#else
# define __unused
# define inline
#endif

#if SQLITE_VERSION_NUMBER >= 3003009
# define my_sqlite3_prepare sqlite3_prepare_v2
#else
# define my_sqlite3_prepare sqlite3_prepare
#endif

/* Utility definitions */

static const value Val_None = Val_int(0);

static inline value Val_Some(value v_arg)
{
  CAMLparam1(v_arg);
  value v_res = caml_alloc_small(1, 0);
  Field(v_res, 0) = v_arg;
  CAMLreturn(v_res);
}

static inline value Val_string_option(const char *str)
{ return (str == NULL) ? Val_None : Val_Some(caml_copy_string(str)); }


/* Type definitions */

typedef struct user_function {
  value v_fun;
  struct user_function *next;
} user_function;

typedef struct db_wrap {
  sqlite3 *db;
  int rc;
  int ref_count;
  user_function *user_functions;
} db_wrap;

typedef struct stmt_wrap {
  sqlite3_stmt *stmt;
  char *sql;
  int sql_len;
  char *tail;
  db_wrap *db_wrap;
} stmt_wrap;


/* Macros to access the wrapper structures stored in the custom blocks */

#define Sqlite3_val(x) (*((db_wrap **) (Data_custom_val(x))))
#define Sqlite3_stmtw_val(x) (*((stmt_wrap **) (Data_custom_val(x))))


/* Exceptions */

static value *caml_sqlite3_InternalError = NULL;
static value *caml_sqlite3_Error = NULL;
static value *caml_sqlite3_RangeError = NULL;

static inline void raise_with_two_args(value v_tag, value v_arg1, value v_arg2)
{
  CAMLparam3(v_tag, v_arg1, v_arg2);
  value v_exc = caml_alloc_small(3, 0);
  Field(v_exc, 0) = v_tag;
  Field(v_exc, 1) = v_arg1;
  Field(v_exc, 2) = v_arg2;
  caml_raise(v_exc);
  CAMLnoreturn;
}

static inline void raise_sqlite3_InternalError(char *msg) Noreturn;

static inline void raise_sqlite3_InternalError(char *msg)
{
  caml_raise_with_string(*caml_sqlite3_InternalError, msg);
}

static inline void range_check(int v, int max)
{
  if (v < 0 || v >= max)
    raise_with_two_args(*caml_sqlite3_RangeError, Val_int(v), Val_int(max));
}

static void raise_sqlite3_Error(const char *fmt, ...) Noreturn;

static void raise_sqlite3_Error(const char *fmt, ...)
{
  char buf[1024];
  va_list args;

  va_start(args, fmt);
  vsnprintf(buf, sizeof buf, fmt, args);
  va_end(args);

  caml_raise_with_string(*caml_sqlite3_Error, buf);
}

static void raise_sqlite3_misuse_db(db_wrap *dbw, const char *fmt, ...)
{
  char buf[1024];
  va_list args;

  dbw->rc = SQLITE_MISUSE;

  va_start(args, fmt);
  vsnprintf(buf, sizeof buf, fmt, args);
  va_end(args);

  raise_sqlite3_Error("%s", buf);
}

static inline void raise_sqlite3_current(sqlite3 *db, char *loc)
{
  const char *what = sqlite3_errmsg(db);
  if (!what) what = "<No error>";
  raise_sqlite3_Error("Sqlite3.%s: %s", loc, what);
}

static inline void check_db(db_wrap *dbw, char *loc)
{
  if (!dbw->db)
    raise_sqlite3_misuse_db(dbw, "Sqlite3.%s called with closed database", loc);
}

static void raise_sqlite3_misuse_stmt(const char *fmt, ...)
{
  char buf[1024];
  va_list args;

  va_start(args, fmt);
  vsnprintf(buf, sizeof buf, fmt, args);
  va_end(args);

  caml_raise_with_string(*caml_sqlite3_Error, buf);
}

static inline void check_stmt(stmt_wrap *stw, char *loc)
{
  if (stw->stmt == NULL)
    raise_sqlite3_misuse_stmt("Sqlite3.%s called with finalized stmt", loc);
}

static inline stmt_wrap * safe_get_stmtw(char *loc, value v_stmt)
{
  stmt_wrap *stmtw = Sqlite3_stmtw_val(v_stmt);
  check_stmt(stmtw, loc);
  return stmtw;
}


/* Initialisation */

CAMLprim value caml_sqlite3_init(value __unused v_unit)
{
  caml_sqlite3_InternalError = caml_named_value("Sqlite3.InternalError");
  caml_sqlite3_Error = caml_named_value("Sqlite3.Error");
  caml_sqlite3_RangeError = caml_named_value("Sqlite3.RangeError");
  return Val_unit;
}


/* Conversion from return values */

static inline value Val_rc(int rc)
{
  value v_res;
  if (rc >= 0) {
    if (rc <= 26) return Val_int(rc);
    if (rc == 100 || rc == 101) return Val_int(rc - 73);
  }
  v_res = caml_alloc_small(1, 0);
  Field(v_res, 0) = Val_int(rc);
  return v_res;
}


/* Copying rows */

static inline value copy_string_option_array(const char** strs, int len)
{
  if (!len) return Atom(0);
  else {
    CAMLparam0();
    CAMLlocal2(v_str, v_res);
    int i;

    v_res = caml_alloc(len, 0);

    for (i = 0; i < len; ++i) {
      const char *str = strs[i];
      if (str == NULL) Field(v_res, i) = Val_None;
      else {
        value v_opt;
        v_str = caml_copy_string(str);
        v_opt = caml_alloc_small(1, 0);
        Field(v_opt, 0) = v_str;
        Store_field(v_res, i, v_opt);
      }
    }

    CAMLreturn(v_res);
  }
}

static inline value copy_not_null_string_array(const char** strs, int len)
{
  if (!len) return Atom(0);
  else {
    CAMLparam0();
    CAMLlocal1(v_res);
    int i;

    v_res = caml_alloc(len, 0);

    for (i = 0; i < len; ++i) {
      const char *str = strs[i];
      if (str == NULL) {
        v_res = (value) NULL;
        break;
      }
      else Store_field(v_res, i, caml_copy_string(str));
    }

    CAMLreturn(v_res);
  }
}

static inline value safe_copy_string_array(const char** strs, int len)
{
  value v_res = copy_not_null_string_array(strs, len);
  if (v_res == (value) NULL) raise_sqlite3_Error("Null element in row");
  return v_res;
}


/* Databases */

static inline void ref_count_finalize_dbw(db_wrap *dbw)
{
  if (--dbw->ref_count == 0) {
    user_function *link;
    for (link = dbw->user_functions; link != NULL; link = link->next) {
      caml_remove_generational_global_root(&link->v_fun);
      free(link);
    }
    dbw->user_functions = NULL;
    sqlite3_close(dbw->db);
    free(dbw);
  }
}

static inline void dbw_finalize_gc(value v_dbw)
{
  db_wrap *dbw = Sqlite3_val(v_dbw);
  if (dbw->db) ref_count_finalize_dbw(dbw);
}

CAMLprim value caml_sqlite3_open(value v_file)
{
  sqlite3 *db;
  int res;
  int len = caml_string_length(v_file) + 1;
  char *file = caml_stat_alloc(len);
  memcpy(file, String_val(v_file), len);

  caml_enter_blocking_section();
    res = sqlite3_open(file, &db);
    free(file);
  caml_leave_blocking_section();

  if (res) {
    const char *msg;
    if (db) {
      msg = sqlite3_errmsg(db);
      sqlite3_close(db);
    }
    else msg = "<unknown_error>";
    raise_sqlite3_Error("error opening database: %s", msg);
  } else if (db == NULL)
    raise_sqlite3_InternalError(
      "open returned neither a database nor an error");
  /* "open" succeded */
  {
    db_wrap *dbw;
    value v_res = caml_alloc_final(2, dbw_finalize_gc, 1, 100);
    Sqlite3_val(v_res) = NULL;
    dbw = caml_stat_alloc(sizeof(db_wrap));
    dbw->db = db;
    dbw->rc = SQLITE_OK;
    dbw->ref_count = 1;
    dbw->user_functions = NULL;
    Sqlite3_val(v_res) = dbw;
    return v_res;
  }
}

CAMLprim value caml_sqlite3_close(value v_db)
{
  int ret, not_busy;
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "close");
  ret = sqlite3_close(dbw->db);
  not_busy = ret != SQLITE_BUSY;
  if (not_busy) dbw->db = NULL;
  return Val_bool(not_busy);
}

#if HAS_ENABLE_LOAD_EXTENSION
CAMLprim value caml_sqlite3_enable_load_extension(value v_db, value v_onoff)
{
  int ret;
  db_wrap *dbw = Sqlite3_val(v_db);
  ret = sqlite3_enable_load_extension(dbw->db, Bool_val(v_onoff));
  return Val_bool(ret);
}
#else
CAMLprim value caml_sqlite3_enable_load_extension(
  value __unused v_db, value __unused v_onoff)
{
  caml_failwith("enable_load_extension: unsupported");
}
#endif


/* Informational functions */

CAMLprim value caml_sqlite3_errcode(value v_db)
{
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "errcode");
  return Val_rc(sqlite3_errcode(dbw->db));
}

CAMLprim value caml_sqlite3_errmsg(value v_db)
{
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "errmsg");
  return caml_copy_string(sqlite3_errmsg(dbw->db));
}

CAMLprim value caml_sqlite3_last_insert_rowid(value v_db)
{
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "last_insert_rowid");
  return caml_copy_int64(sqlite3_last_insert_rowid(dbw->db));
}


/* Execution and callbacks */

typedef struct callback_with_exn { value *cbp; value *exn; } callback_with_exn;

static inline int exec_callback(
  void *cbx_, int num_columns, char **row, char **header)
{
  callback_with_exn *cbx = cbx_;
  value v_row, v_header, v_ret;

  caml_leave_blocking_section();

    v_row = copy_string_option_array((const char **) row, num_columns);

    Begin_roots1(v_row);
      v_header = safe_copy_string_array((const char **) header, num_columns);
    End_roots();

    v_ret = caml_callback2_exn(*cbx->cbp, v_row, v_header);

    if (Is_exception_result(v_ret)) {
      *cbx->exn = Extract_exception(v_ret);
      caml_enter_blocking_section();
      return 1;
    }

  caml_enter_blocking_section();

  return 0;
}

CAMLprim value caml_sqlite3_exec(value v_db, value v_maybe_cb, value v_sql)
{
  CAMLparam1(v_db);
  CAMLlocal2(v_cb, v_exn);
  callback_with_exn cbx;
  db_wrap *dbw = Sqlite3_val(v_db);
  int len = caml_string_length(v_sql) + 1;
  char *sql;
  int rc;
  sqlite3_callback cb = NULL;

  check_db(dbw, "exec");
  sql = caml_stat_alloc(len);
  memcpy(sql, String_val(v_sql), len);
  cbx.cbp = &v_cb;
  cbx.exn = &v_exn;

  if (v_maybe_cb != Val_None) {
    v_cb = Field(v_maybe_cb, 0);
    cb = exec_callback;
  }

  caml_enter_blocking_section();
    rc = sqlite3_exec(dbw->db, sql, cb, (void *) &cbx, NULL);
    free(sql);
  caml_leave_blocking_section();

  if (rc == SQLITE_ABORT) caml_raise(*cbx.exn);

  CAMLreturn(Val_rc(rc));
}

static inline int exec_callback_no_headers(
  void *cbx_, int num_columns, char **row, char __unused **header)
{
  callback_with_exn *cbx = cbx_;
  value v_row, v_ret;

  caml_leave_blocking_section();

    v_row = copy_string_option_array((const char **) row, num_columns);
    v_ret = caml_callback_exn(*cbx->cbp, v_row);

    if (Is_exception_result(v_ret)) {
      *cbx->exn = Extract_exception(v_ret);
      caml_enter_blocking_section();
      return 1;
    }

  caml_enter_blocking_section();

  return 0;
}

CAMLprim value caml_sqlite3_exec_no_headers(value v_db, value v_cb, value v_sql)
{
  CAMLparam2(v_db, v_cb);
  CAMLlocal1(v_exn);
  callback_with_exn cbx;
  db_wrap *dbw = Sqlite3_val(v_db);
  int len = caml_string_length(v_sql) + 1;
  char *sql;
  int rc;

  check_db(dbw, "exec_no_headers");
  sql = caml_stat_alloc(len);
  memcpy(sql, String_val(v_sql), len);
  cbx.cbp = &v_cb;
  cbx.exn = &v_exn;

  caml_enter_blocking_section();
    rc =
      sqlite3_exec(dbw->db, sql, exec_callback_no_headers, (void *) &cbx, NULL);
    free(sql);
  caml_leave_blocking_section();

  if (rc == SQLITE_ABORT) caml_raise(*cbx.exn);

  CAMLreturn(Val_rc(rc));
}

static inline int exec_not_null_callback(
  void *cbx_, int num_columns, char **row, char **header)
{
  callback_with_exn *cbx = cbx_;
  value v_row, v_header, v_ret;

  caml_leave_blocking_section();

    v_row = copy_not_null_string_array((const char **) row, num_columns);

    if (v_row == (value) NULL) return 1;

    Begin_roots1(v_row);
      v_header = safe_copy_string_array((const char **) header, num_columns);
    End_roots();

    v_ret = caml_callback2_exn(*cbx->cbp, v_row, v_header);

    if (Is_exception_result(v_ret)) {
      *cbx->exn = Extract_exception(v_ret);
      caml_enter_blocking_section();
      return 1;
    }

  caml_enter_blocking_section();

  return 0;
}

CAMLprim value caml_sqlite3_exec_not_null(value v_db, value v_cb, value v_sql)
{
  CAMLparam2(v_db, v_cb);
  CAMLlocal1(v_exn);
  callback_with_exn cbx;
  db_wrap *dbw = Sqlite3_val(v_db);
  int len = caml_string_length(v_sql) + 1;
  char *sql;
  int rc;

  check_db(dbw, "exec_not_null");
  sql = caml_stat_alloc(len);
  memcpy(sql, String_val(v_sql), len);
  cbx.cbp = &v_cb;
  cbx.exn = &v_exn;

  caml_enter_blocking_section();
    rc =
      sqlite3_exec(dbw->db, sql, exec_not_null_callback, (void *) &cbx, NULL);
    free(sql);
  caml_leave_blocking_section();

  if (rc == SQLITE_ABORT) {
    if (*cbx.exn != 0) caml_raise(*cbx.exn);
    else raise_sqlite3_Error("Null element in row");
  }
  CAMLreturn(Val_rc(rc));
}

static inline int exec_not_null_no_headers_callback(
  void *cbx_, int num_columns, char **row, char __unused **header)
{
  callback_with_exn *cbx = cbx_;
  value v_row, v_ret;

  caml_leave_blocking_section();

    v_row = copy_not_null_string_array((const char **) row, num_columns);
    if (v_row == (value) NULL) return 1;
    v_ret = caml_callback_exn(*cbx->cbp, v_row);

    if (Is_exception_result(v_ret)) {
      *cbx->exn = Extract_exception(v_ret);
      caml_enter_blocking_section();
      return 1;
    }

  caml_enter_blocking_section();

  return 0;
}

CAMLprim value caml_sqlite3_exec_not_null_no_headers(
  value v_db, value v_cb, value v_sql)
{
  CAMLparam2(v_db, v_cb);
  CAMLlocal1(v_exn);
  callback_with_exn cbx;
  db_wrap *dbw = Sqlite3_val(v_db);
  int len = caml_string_length(v_sql) + 1;
  char *sql;
  int rc;

  check_db(dbw, "exec_not_null_no_headers");
  sql = caml_stat_alloc(len);
  memcpy(sql, String_val(v_sql), len);
  cbx.cbp = &v_cb;
  cbx.exn = &v_exn;

  caml_enter_blocking_section();
    rc =
      sqlite3_exec(
        dbw->db, sql, exec_not_null_no_headers_callback, (void *) &cbx, NULL);
    free(sql);
  caml_leave_blocking_section();

  if (rc == SQLITE_ABORT) {
    if (*cbx.exn != 0) caml_raise(*cbx.exn);
    else raise_sqlite3_Error("Null element in row");
  }
  CAMLreturn(Val_rc(rc));
}


/* Statements */

static inline void finalize_stmt_gc(value v_stmt)
{
  stmt_wrap *stmtw = Sqlite3_stmtw_val(v_stmt);
  sqlite3_stmt *stmt = stmtw->stmt;
  if (stmt) sqlite3_finalize(stmt);
  if (stmtw->sql) free(stmtw->sql);
  ref_count_finalize_dbw(stmtw->db_wrap);
  free(stmtw);
}

CAMLprim value caml_sqlite3_stmt_finalize(value v_stmt)
{
  stmt_wrap *stmtw = safe_get_stmtw("finalize", v_stmt);
  int rc = sqlite3_finalize(stmtw->stmt);
  stmtw->stmt = NULL;
  return Val_rc(rc);
}

CAMLprim value caml_sqlite3_stmt_reset(value v_stmt)
{
  sqlite3_stmt *stmt = safe_get_stmtw("reset", v_stmt)->stmt;
  return Val_rc(sqlite3_reset(stmt));
}

static inline value alloc_stmt(db_wrap *dbw)
{
  value v_stmt = caml_alloc_final(2, finalize_stmt_gc, 1, 100);
  stmt_wrap *stmtw;
  Sqlite3_stmtw_val(v_stmt) = NULL;
  stmtw = caml_stat_alloc(sizeof(stmt_wrap));
  stmtw->db_wrap = dbw;
  dbw->ref_count++;
  stmtw->stmt = NULL;
  stmtw->sql = NULL;
  Sqlite3_stmtw_val(v_stmt) = stmtw;
  return v_stmt;
}

static inline void prepare_it(
  db_wrap *dbw, value v_stmt, const char *sql, int sql_len, char *loc)
{
  int rc;
  stmt_wrap *stmtw = Sqlite3_stmtw_val(v_stmt);
  stmtw->sql = caml_stat_alloc(sql_len + 1);
  memcpy(stmtw->sql, sql, sql_len);
  stmtw->sql[sql_len] = '\0';
  stmtw->sql_len = sql_len;
  rc = my_sqlite3_prepare(dbw->db, stmtw->sql, sql_len,
                          &(stmtw->stmt), (const char **) &(stmtw->tail));
  if (rc != SQLITE_OK) raise_sqlite3_current(dbw->db, loc);
  if (!stmtw->stmt) raise_sqlite3_Error("No code compiled from %s", sql);
}

CAMLprim value caml_sqlite3_prepare(value v_db, value v_sql)
{
  CAMLparam2(v_db, v_sql);
  char *loc = "prepare";
  db_wrap *dbw = Sqlite3_val(v_db);
  value v_stmt;
  check_db(dbw, loc);
  v_stmt = alloc_stmt(dbw);
  prepare_it(dbw, v_stmt, String_val(v_sql), caml_string_length(v_sql), loc);
  CAMLreturn(v_stmt);
}

CAMLprim value caml_sqlite3_prepare_tail(value v_stmt)
{
  CAMLparam1(v_stmt);
  char *loc = "prepare_tail";
  stmt_wrap *stmtw = Sqlite3_stmtw_val(v_stmt);
  if (stmtw->sql && stmtw->tail && *(stmtw->tail)) {
    db_wrap *dbw = stmtw->db_wrap;
    value v_new_stmt = alloc_stmt(dbw);
    int tail_len = stmtw->sql_len - (stmtw->tail - stmtw->sql);
    prepare_it(dbw, v_new_stmt, stmtw->tail, tail_len, loc);
    CAMLreturn(Val_Some(v_new_stmt));
  }
  else CAMLreturn(Val_None);
}

CAMLprim value caml_sqlite3_recompile(value v_stmt)
{
  CAMLparam1(v_stmt);
  stmt_wrap *stmtw = Sqlite3_stmtw_val(v_stmt);
  sqlite3_stmt *stmt = stmtw->stmt;
  int rc;
  if (stmt) {
    sqlite3_finalize(stmt);
    stmtw->stmt = NULL;
  }
  rc =
    my_sqlite3_prepare(stmtw->db_wrap->db, stmtw->sql, stmtw->sql_len,
                       &(stmtw->stmt),
                       (const char **) &(stmtw->tail));
  if (rc != SQLITE_OK) raise_sqlite3_current(stmtw->db_wrap->db, "recompile");
  else if (!stmtw->stmt)
    raise_sqlite3_Error("No code recompiled from %s", stmtw->sql);
  CAMLreturn(Val_unit);
}

CAMLprim value caml_sqlite3_bind_parameter_name(value v_stmt, value v_index)
{
  CAMLparam1(v_stmt);
  sqlite3_stmt *stmt = safe_get_stmtw("bind_parameter_name", v_stmt)->stmt;
  int i = Int_val(v_index);
  range_check(i - 1, sqlite3_bind_parameter_count(stmt));
  CAMLreturn(Val_string_option(sqlite3_bind_parameter_name(stmt, i)));
}

CAMLprim value caml_sqlite3_bind_parameter_index(value v_stmt, value v_name)
{
  sqlite3_stmt *stmt = safe_get_stmtw("bind_parameter_index", v_stmt)->stmt;
  char *parm_name = String_val(v_name);
  int index = sqlite3_bind_parameter_index(stmt, parm_name);
  if (!index) caml_raise_not_found();
  return Val_int(index);
}

CAMLprim value caml_sqlite3_bind_parameter_count(value v_stmt)
{
  sqlite3_stmt *stmt = safe_get_stmtw("bind_parameter_count", v_stmt)->stmt;
  return Val_int(sqlite3_bind_parameter_count(stmt));
}

CAMLprim value caml_sqlite3_bind(value v_stmt, value v_index, value v_data)
{
  sqlite3_stmt *stmt = safe_get_stmtw("bind", v_stmt)->stmt;
  int i = Int_val(v_index);
  range_check(i - 1, sqlite3_bind_parameter_count(stmt));
  if (Is_long(v_data)) {
    switch Int_val(v_data) {
      case 1 : return Val_rc(sqlite3_bind_null(stmt, i));
      default : return Val_rc(SQLITE_ERROR);
    }
  } else {
    value v_field = Field(v_data, 0);
    switch (Tag_val(v_data)) {
      case 0 : return Val_rc(sqlite3_bind_int64(stmt, i, Int64_val(v_field)));
      case 1 : return Val_rc(sqlite3_bind_double(stmt, i, Double_val(v_field)));
      case 2 :
        return Val_rc(sqlite3_bind_text(stmt, i,
                                        String_val(v_field),
                                        caml_string_length(v_field),
                                        SQLITE_TRANSIENT));
      case 3 :
        return Val_rc(sqlite3_bind_blob(stmt, i,
                                        String_val(v_field),
                                        caml_string_length(v_field),
                                        SQLITE_TRANSIENT));
    }
  }
  return Val_rc(SQLITE_ERROR);
}

/* FIXME */

/* Sorry this gives a linking error! */
#if 0
CAMLprim value caml_sqlite3_clear_bindings(value v_stmt)
{
  sqlite3_stmt *stmt = safe_get_stmtw("clear_bindings", v_stmt)->stmt;
  return Val_rc(sqlite3_clear_bindings(stmt));
}
#endif

CAMLprim value caml_sqlite3_column_name(value v_stmt, value v_index)
{
  CAMLparam1(v_stmt);
  sqlite3_stmt *stmt = safe_get_stmtw("column_name", v_stmt)->stmt;
  int i = Int_val(v_index);
  range_check(i, sqlite3_column_count(stmt));
  CAMLreturn(caml_copy_string(sqlite3_column_name(stmt, i)));
}

CAMLprim value caml_sqlite3_column_decltype(value v_stmt, value v_index)
{
  CAMLparam1(v_stmt);
  sqlite3_stmt *stmt = safe_get_stmtw("column_decltype", v_stmt)->stmt;
  int i = Int_val(v_index);
  range_check(i, sqlite3_column_count(stmt));
  CAMLreturn(Val_string_option(sqlite3_column_decltype(stmt, i)));
}

CAMLprim value caml_sqlite3_step(value v_stmt)
{
  CAMLparam1(v_stmt);
  sqlite3_stmt *stmt = safe_get_stmtw("step", v_stmt)->stmt;
  int rc;
  caml_enter_blocking_section();
    rc = sqlite3_step(stmt);
  caml_leave_blocking_section();
  CAMLreturn(Val_rc(rc));
}

CAMLprim value caml_sqlite3_data_count(value v_stmt)
{
  sqlite3_stmt *stmt = safe_get_stmtw("data_count", v_stmt)->stmt;
  return Val_int(sqlite3_data_count(stmt));
}

CAMLprim value caml_sqlite3_column_count(value v_stmt)
{
  sqlite3_stmt *stmt = safe_get_stmtw("column_count", v_stmt)->stmt;
  return Val_int(sqlite3_column_count(stmt));
}

CAMLprim value caml_sqlite3_column(value v_stmt, value v_index)
{
  CAMLparam1(v_stmt);
  CAMLlocal1(v_tmp);
  value v_res;
  sqlite3_stmt *stmt = safe_get_stmtw("column", v_stmt)->stmt;
  int len, i = Int_val(v_index);
  range_check(i, sqlite3_column_count(stmt));
  switch (sqlite3_column_type(stmt, i)) {
    case SQLITE_INTEGER :
      v_tmp = caml_copy_int64(sqlite3_column_int64(stmt, i));
      v_res = caml_alloc_small(1, 0);
      Field(v_res, 0) = v_tmp;
      break;
    case SQLITE_FLOAT :
      v_tmp = caml_copy_double(sqlite3_column_double(stmt, i));
      v_res = caml_alloc_small(1, 1);
      Field(v_res, 0) = v_tmp;
      break;
    case SQLITE3_TEXT :
      len = sqlite3_column_bytes(stmt, i);
      v_tmp = caml_alloc_string(len);
      memcpy(String_val(v_tmp), (char *) sqlite3_column_text(stmt, i), len);
      v_res = caml_alloc_small(1, 2);
      Field(v_res, 0) = v_tmp;
      break;
    case SQLITE_BLOB :
      len = sqlite3_column_bytes(stmt, i);
      v_tmp = caml_alloc_string(len);
      memcpy(String_val(v_tmp), (char *) sqlite3_column_blob(stmt, i), len);
      v_res = caml_alloc_small(1, 3);
      Field(v_res, 0) = v_tmp;
      break;
    case SQLITE_NULL :
      v_res = Val_int(1);
      break;
    default:
      v_res = Val_None;
  }
  CAMLreturn(v_res);
}

/* FIXME */

/* Sorry, this gives a linking error! */
#if 0
CAMLprim value caml_sqlite3_sleep(value v_duration)
{
  int res;
  caml_enter_blocking_section();
    res = sqlite3_sleep(Int_val(v_duration));
  caml_leave_blocking_section();
  return (Int_val(res));
}
#endif


/* User-defined functions */

static inline value caml_sqlite3_wrap_values(int argc, sqlite3_value **args)
{
  if (argc <= 0 || args == NULL) return Atom(0);
  else {
    int i, len;
    CAMLparam0();
    CAMLlocal2(v_arr, v_tmp);
    value v_res;
    v_arr = caml_alloc(argc, 0);
    for (i = 0; i < argc; ++i) {
      sqlite3_value *arg = args[i];
      switch (sqlite3_value_type(arg)) {
        case SQLITE_INTEGER :
          v_tmp = caml_copy_int64(sqlite3_value_int64(arg));
          v_res = caml_alloc_small(1, 0);
          Field(v_res, 0) = v_tmp;
          break;
        case SQLITE_FLOAT :
          v_tmp = caml_copy_double(sqlite3_value_double(arg));
          v_res = caml_alloc_small(1, 1);
          Field(v_res, 0) = v_tmp;
          break;
        case SQLITE3_TEXT :
          len = sqlite3_value_bytes(arg);
          v_tmp = caml_alloc_string(len);
          memcpy(String_val(v_tmp), (char *) sqlite3_value_text(arg), len);
          v_res = caml_alloc_small(1, 2);
          Field(v_res, 0) = v_tmp;
          break;
        case SQLITE_BLOB :
          len = sqlite3_value_bytes(arg);
          v_tmp = caml_alloc_string(len);
          memcpy(String_val(v_tmp), (char *) sqlite3_value_blob(arg), len);
          v_res = caml_alloc_small(1, 3);
          Field(v_res, 0) = v_tmp;
          break;
        case SQLITE_NULL :
          v_res = Val_int(1);
          break;
        default:
          v_res = Val_None;
      }
      Store_field(v_arr, i, v_res);
    }
    CAMLreturn(v_arr);
  }
}

static inline void check_exception_result(sqlite3_context *ctx, value v_res)
{
  if (Is_exception_result(v_res))
    sqlite3_result_error(ctx, "OCaml callback raised an exception", -1);
}

static inline void set_sqlite3_result(sqlite3_context *ctx, value v_res)
{
  check_exception_result(ctx, v_res);
  if (Is_long(v_res)) sqlite3_result_null(ctx);
  else {
    value v = Field(v_res, 0);
    switch (Tag_val(v_res)) {
      case 0 : sqlite3_result_int64(ctx, Int64_val(v)); break;
      case 1 : sqlite3_result_double(ctx, Double_val(v)); break;
      case 2 :
        sqlite3_result_text(
          ctx, String_val(v), caml_string_length(v), SQLITE_TRANSIENT);
        break;
      case 3 :
        sqlite3_result_blob(
          ctx, String_val(v), caml_string_length(v), SQLITE_TRANSIENT);
        break;
      default :
        sqlite3_result_error(ctx, "unknown value returned by callback", -1);
    }
  }
}

static inline void
caml_sqlite3_user_function(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  user_function *data = sqlite3_user_data(ctx);
  value v_args, v_res;
  caml_leave_blocking_section();
    v_args = caml_sqlite3_wrap_values(argc, argv);
    v_res = caml_callback_exn(Field(data->v_fun, 1), v_args);
    set_sqlite3_result(ctx, v_res);
  caml_enter_blocking_section();
}

typedef struct agg_ctx { int initialized; value v_acc; } agg_ctx;

static inline void caml_sqlite3_user_function_step(
  sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  value v_args, v_res;
  user_function *data = sqlite3_user_data(ctx);
  agg_ctx *agg_ctx = sqlite3_aggregate_context(ctx, sizeof(agg_ctx));
  caml_leave_blocking_section();
    if (!agg_ctx->initialized) {
      agg_ctx->v_acc = Field(data->v_fun, 1);
      /* Not a generational global root, because it is hard to imagine
         that there will ever be more than at most a few instances
         (quite probably only one in most cases). */
      caml_register_global_root(&agg_ctx->v_acc);
      agg_ctx->initialized = 1;
    }
    v_args = caml_sqlite3_wrap_values(argc, argv);
    v_res = caml_callback2_exn(Field(data->v_fun, 2), agg_ctx->v_acc, v_args);
    check_exception_result(ctx, v_res);
    agg_ctx->v_acc = v_res;
  caml_enter_blocking_section();
}

static inline void
caml_sqlite3_user_function_final(sqlite3_context *ctx)
{
  user_function *data = sqlite3_user_data(ctx);
  agg_ctx *agg_ctx = sqlite3_aggregate_context(ctx, sizeof(agg_ctx));
  value v_res;
  caml_leave_blocking_section();
    v_res = caml_callback_exn(Field(data->v_fun, 3), agg_ctx->v_acc);
    set_sqlite3_result(ctx, v_res);
    caml_remove_global_root(&agg_ctx->v_acc);
  caml_enter_blocking_section();
}

static inline void unregister_user_function(db_wrap *db_data, value v_name)
{
  user_function *prev = NULL, *link = db_data->user_functions;
  char *name = String_val(v_name);

  while (link != NULL) {
    if (strcmp(String_val(Field(link->v_fun, 0)), name) == 0) {
      if (prev == NULL) db_data->user_functions = link->next;
      else prev->next = link->next;
      caml_remove_generational_global_root(&link->v_fun);
      free(link);
      break;
    }
    prev = link;
    link = link->next;
  }
}

static inline user_function * register_user_function(
  db_wrap *db_data, value v_cell)
{
  /* Assume parameters are already protected */
  user_function *link = caml_stat_alloc(sizeof *link);
  link->v_fun = v_cell;
  link->next = db_data->user_functions;
  caml_register_generational_global_root(&link->v_fun);
  db_data->user_functions = link;
  return link;
}

static inline user_function * register_scalar_user_function(
  db_wrap *db_data, value v_name, value v_fun)
{
  /* Assume parameters are already protected */
  value v_cell = caml_alloc_small(2, 0);
  Field(v_cell, 0) = v_name;
  Field(v_cell, 1) = v_fun;
  return register_user_function(db_data, v_cell);
}

static inline user_function * register_aggregate_user_function(
  db_wrap *db_data, value v_name,
  value v_init, value v_step, value v_final)
{
  /* Assume parameters are already protected */
  value v_cell = caml_alloc_small(4, 0);
  Field(v_cell, 0) = v_name;
  Field(v_cell, 1) = v_init;
  Field(v_cell, 2) = v_step;
  Field(v_cell, 3) = v_final;
  return register_user_function(db_data, v_cell);
}

CAMLprim value caml_sqlite3_create_function(
  value v_db, value v_name, value v_n_args, value v_fun)
{
  CAMLparam3(v_db, v_name, v_fun);
  user_function *param;
  int rc;
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "create_function");
  param = register_scalar_user_function(dbw, v_name, v_fun);
  rc = sqlite3_create_function(dbw->db, String_val(v_name),
                               Int_val(v_n_args), SQLITE_UTF8, param,
                               caml_sqlite3_user_function, NULL, NULL);
  if (rc != SQLITE_OK) {
    unregister_user_function(dbw, v_name);
    raise_sqlite3_current(dbw->db, "create_function");
  }
  CAMLreturn(Val_unit);
}

CAMLprim value caml_sqlite3_create_aggregate_function_nc(
  value v_db, value v_name, value v_n_args,
  value v_init, value v_stepfn, value v_finalfn)
{
  CAMLparam4(v_db, v_name, v_stepfn, v_finalfn);
  user_function *param;
  int rc;
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "create_aggregate_function");
  param =
    register_aggregate_user_function(dbw, v_name, v_init, v_stepfn, v_finalfn);
  rc = sqlite3_create_function(dbw->db, String_val(v_name),
                               Int_val(v_n_args), SQLITE_UTF8, param,
                               NULL, caml_sqlite3_user_function_step,
                               caml_sqlite3_user_function_final);
  if (rc != SQLITE_OK) {
    unregister_user_function(dbw, v_name);
    raise_sqlite3_current(dbw->db, "create_aggregate_function");
  }
  CAMLreturn(Val_unit);
}

CAMLprim value caml_sqlite3_create_aggregate_function_bc(
  value *argv, int __unused argn)
{
  return
    caml_sqlite3_create_aggregate_function_nc(
      argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
}

CAMLprim value caml_sqlite3_delete_function(value v_db, value v_name)
{
  int rc;
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "delete_function");
  rc = sqlite3_create_function(dbw->db, String_val(v_name),
                               0, SQLITE_UTF8, NULL, NULL, NULL, NULL);
  if (rc != SQLITE_OK) raise_sqlite3_current(dbw->db, "delete_function");
  unregister_user_function(dbw, v_name);
  return Val_unit;
}

CAMLprim value caml_sqlite3_busy_timeout(value v_db, value v_ms)
{
  int rc;
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "busy_timeout");
  rc = sqlite3_busy_timeout(dbw->db, Int_val(v_ms));
  if (rc != SQLITE_OK) raise_sqlite3_current(dbw->db, "busy_timeout");
  return Val_unit;
}

CAMLprim value caml_sqlite3_changes(value v_db)
{
  db_wrap *dbw = Sqlite3_val(v_db);
  check_db(dbw, "changes");
  return Val_int(sqlite3_changes(dbw->db));
}

