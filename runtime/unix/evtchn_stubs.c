#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/bigarray.h>

#define NR_EVENTS 128
uint8_t ev_fds[NR_EVENTS];
uint8_t ev_callback_ml[NR_EVENTS];

CAMLprim value
caml_nr_events(value v_unit)
{
   return Val_int(NR_EVENTS);
}

CAMLprim value
caml_evtchn_test_and_clear(value v_idx)
{
   int idx = Int_val(v_idx) % NR_EVENTS;
   if (ev_callback_ml[idx] > 0) {
      ev_callback_ml[idx] = 0;
      return Val_int(1);
   } else
      return Val_int(0);
}
