#define CAML_NAME_SPACE
#include "caml/mlvalues.h"

#ifdef __GLIBC__
#include <malloc.h>
#else

static int malloc_trim(size_t pad) { return 0; }
#endif

CAMLprim value stub_malloc_trim_noalloc(value const val_pad) {
  long const pad = Long_val(val_pad);
  return Val_bool(pad >= 0 && malloc_trim(pad));
}

