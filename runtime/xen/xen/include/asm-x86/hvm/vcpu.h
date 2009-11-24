/*
 * vcpu.h: HVM per vcpu definitions
 *
 * Copyright (c) 2005, International Business Machines Corporation.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307 USA.
 */

#ifndef __ASM_X86_HVM_VCPU_H__
#define __ASM_X86_HVM_VCPU_H__

#include <asm/hvm/io.h>
#include <asm/hvm/vlapic.h>
#include <asm/hvm/vmx/vmcs.h>
#include <asm/hvm/svm/vmcb.h>
#include <asm/mtrr.h>

enum hvm_io_state {
    HVMIO_none = 0,
    HVMIO_dispatched,
    HVMIO_awaiting_completion,
    HVMIO_handle_mmio_awaiting_completion,
    HVMIO_completed
};

struct hvm_vcpu {
    /* Guest control-register and EFER values, just as the guest sees them. */
    unsigned long       guest_cr[5];
    unsigned long       guest_efer;

    /*
     * Processor-visible control-register values, while guest executes.
     *  CR0, CR4: Used as a cache of VMCS contents by VMX only.
     *  CR1, CR2: Never used (guest_cr[2] is always processor-visible CR2).
     *  CR3:      Always used and kept up to date by paging subsystem.
     */
    unsigned long       hw_cr[5];

    /*
     * The save area for Processor Extended States and the bitmask of the
     * XSAVE/XRSTOR features. They are used by: 1) when a vcpu (which has
     * dirtied FPU/SSE) is scheduled out we XSAVE the states here; 2) in
     * #NM handler, we XRSTOR the states we XSAVE-ed;
     */
    void *xsave_area;
    uint64_t xfeature_mask;

    struct vlapic       vlapic;
    s64                 cache_tsc_offset;
    u64                 guest_time;

    /* Lock and list for virtual platform timers. */
    spinlock_t          tm_lock;
    struct list_head    tm_list;

    int                 xen_port;

    bool_t              flag_dr_dirty;
    bool_t              debug_state_latch;
    bool_t              single_step;

    union {
        struct arch_vmx_struct vmx;
        struct arch_svm_struct svm;
    } u;

    struct tasklet      assert_evtchn_irq_tasklet;

    struct mtrr_state   mtrr;
    u64                 pat_cr;

    /* In mode delay_for_missed_ticks, VCPUs have differing guest times. */
    int64_t             stime_offset;

    /* Which cache mode is this VCPU in (CR0:CD/NW)? */
    u8                  cache_mode;

    /* I/O request in flight to device model. */
    enum hvm_io_state   io_state;
    unsigned long       io_data;

    /*
     * HVM emulation:
     *  Virtual address @mmio_gva maps to MMIO physical frame @mmio_gpfn.
     *  The latter is known to be an MMIO frame (not RAM).
     *  This translation is only valid if @mmio_gva is non-zero.
     */
    unsigned long       mmio_gva;
    unsigned long       mmio_gpfn;
    /* Callback into x86_emulate when emulating FPU/MMX/XMM instructions. */
    void (*fpu_exception_callback)(void *, struct cpu_user_regs *);
    void *fpu_exception_callback_arg;
    /* We may read up to m128 as a number of device-model transactions. */
    paddr_t mmio_large_read_pa;
    uint8_t mmio_large_read[16];
    unsigned int mmio_large_read_bytes;
    /* We may write up to m128 as a number of device-model transactions. */
    paddr_t mmio_large_write_pa;
    unsigned int mmio_large_write_bytes;
};

#endif /* __ASM_X86_HVM_VCPU_H__ */
