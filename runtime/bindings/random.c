/* XXX static random seed for OCaml random, to replace when minios settles down */

#include <caml/mlvalues.h>

CAMLprim value caml_sys_random_seed(value n)
{
   intnat seed = 1;
   return Val_long(seed);
}
