/*
 * asid.h: handling ASIDs in SVM.
 * Copyright (c) 2007, Advanced Micro Devices, Inc.
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

#ifndef __ASM_X86_HVM_SVM_ASID_H__
#define __ASM_X86_HVM_SVM_ASID_H__

#include <xen/config.h>
#include <asm/types.h>
#include <asm/hvm/hvm.h>
#include <asm/hvm/support.h>
#include <asm/hvm/svm/svm.h>
#include <asm/hvm/svm/vmcb.h>
#include <asm/percpu.h>

void svm_asid_init(struct cpuinfo_x86 *c);
void svm_asid_init_vcpu(struct vcpu *v);
void svm_asid_inv_asid(struct vcpu *v);
void svm_asid_inc_generation(void);

static inline void svm_asid_g_invlpg(struct vcpu *v, unsigned long g_vaddr)
{
#if 0
    /* Optimization? */
    asm volatile (".byte 0x0F,0x01,0xDF    \n"
                  : /* output */
                  : /* input */
                  "a" (g_vaddr), "c"(v->arch.hvm_svm.vmcb->guest_asid) );
#endif

    /* Safe fallback. Take a new ASID. */
    svm_asid_inv_asid(v);
}

#endif /* __ASM_X86_HVM_SVM_ASID_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
