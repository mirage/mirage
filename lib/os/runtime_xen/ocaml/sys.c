/***********************************************************************/
/*                                                                     */
/*                           Objective Caml                            */
/*                                                                     */
/*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         */
/*                                                                     */
/*  Copyright 1996 Institut National de Recherche en Informatique et   */
/*  en Automatique.  All rights reserved.  This file is distributed    */
/*  under the terms of the GNU Library General Public License, with    */
/*  the special exception on linking described in file ../LICENSE.     */
/*                                                                     */
/***********************************************************************/

/* $Id: sys.c 7944 2007-03-01 13:37:39Z xleroy $ */

/* Basic system calls */

#include <mini-os/x86/os.h>
#include <mini-os/sched.h>
#include "config.h"
#include "alloc.h"
#include "debugger.h"
#include "fail.h"
#include "mlvalues.h"
#include "osdeps.h"
#include "signals.h"
#include "stacks.h"
#include "sys.h"

char * caml_exe_name;
static char ** caml_main_argv;

CAMLexport void caml_sys_error(value arg)
{
  CAMLparam1 (arg);
  char * err;
  CAMLlocal1 (str);

  err = "unknown error";
  if (arg == NO_ARG) {
    str = caml_copy_string(err);
  } else {
    int err_len = strlen(err);
    int arg_len = caml_string_length(arg);
    str = caml_alloc_string(arg_len + 2 + err_len);
    memmove(&Byte(str, 0), String_val(arg), arg_len);
    memmove(&Byte(str, arg_len), ": ", 2);
    memmove(&Byte(str, arg_len + 2), err, err_len);
  }
  caml_raise_sys_error(str);
  CAMLnoreturn;
}

CAMLexport void caml_sys_io_error(value arg)
{
  caml_sys_error(arg);
}

void caml_sys_init(char * exe_name, char **argv)
{
  caml_exe_name = exe_name;
  caml_main_argv = argv;
}

CAMLprim value caml_sys_exit(value retcode)
{
  _exit(Int_val(retcode));
  return Val_unit;
}

CAMLprim value caml_sys_random_seed (value unit)
{
  intnat seed;
  seed = monotonic_clock ();
  return Val_long(seed);
}

CAMLprim void caml_sys_open(value path, value vflags, value vperm)
{
  CAMLparam3(path, vflags, vperm);
  caml_sys_io_error(NO_ARG);
  CAMLnoreturn;
}

CAMLprim value caml_sys_get_config(value unit)
{
  CAMLparam0 ();   /* unit is unused */
  CAMLlocal2 (result, ostype);

  ostype = caml_copy_string(OCAML_OS_TYPE);
  result = caml_alloc_small (2, 0);
  Field(result, 0) = ostype;
  Field(result, 1) = Val_long (8 * sizeof(value));
  CAMLreturn (result);
}
