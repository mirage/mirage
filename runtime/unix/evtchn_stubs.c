#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/bigarray.h>

#define NR_EVENTS 128
uint8_t ev_fds[NR_EVENTS];
uint8_t ev_callback_ml[NR_EVENTS];

CAMLprim value
caml_evtchn_init(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal1(v_arr);
  v_arr = alloc_bigarray_dims(BIGARRAY_UINT8 | BIGARRAY_C_LAYOUT, 1,
    ev_callback_ml, NR_EVENTS);
  CAMLreturn(v_arr);
}

