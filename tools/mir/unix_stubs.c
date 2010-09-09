#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/signals.h>
#include <caml/unixsupport.h>

#include <sys/types.h>
#include <sys/param.h>
#include <sys/utsname.h>

CAMLprim value
unix_realpath(value path)
{
  char buffer[PATH_MAX];
  char *r;
  r = realpath(String_val(path), buffer);
  if (r == NULL) caml_failwith("realpath");
  return copy_string(buffer);
}

CAMLprim value
unix_sysname(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(v_str);
  struct utsname u;
  if (uname(&u) < 0)
    caml_failwith("uname");
  v_str = caml_copy_string(u.sysname);
  CAMLreturn(v_str);
}

CAMLprim value
unix_sysmachine(value unit)
{
  CAMLparam1(unit);
  CAMLlocal1(v_str);
  struct utsname u;
  if (uname(&u) < 0)
    caml_failwith("uname");
  v_str = caml_copy_string(u.machine);
  CAMLreturn(v_str);
}
