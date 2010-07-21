/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/* The Mirage "select" loop which decides to wake up timeouts, I/O or
   Xenstore traffic. */

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
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
    force_evtchn_callback();
    CAMLreturn(Val_unit);
}
