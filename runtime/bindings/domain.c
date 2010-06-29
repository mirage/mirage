#include <mlvalues.h>
#include <alloc.h>
#include <memory.h>
#include <mini-os/x86/os.h>
#include <mini-os/sched.h>

CAMLprim value 
mirage_block_domain(value v_timeout)
{
    CAMLparam1(v_timeout);
    unsigned long flags;
    s_time_t secs = (s_time_t)(Double_val(v_timeout) * 1000000000);
    s_time_t until = NOW() + secs;
    local_irq_save(flags);
    block_domain(until);
    force_evtchn_callback();
    local_irq_restore(flags);
    CAMLreturn(Val_unit);
}

