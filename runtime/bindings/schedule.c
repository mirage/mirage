#include <caml/mlvalues.h>

void schedule(void);

CAMLprim value mirage_schedule(value t)
{
  enter_blocking_section();
  schedule();
  leave_blocking_section();
  return Val_unit;
}
