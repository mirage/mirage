

/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * Copyright (c) 2004, Intel Corporation.
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
 *
 * 
 */

#ifndef _LSAPIC_H
#define _LSAPIC_H
#include <xen/sched.h>
#include <asm/vmx_vcpu.h>
/*
 *Delivery mode
 */
#define SAPIC_DELIV_SHIFT      8
#define SAPIC_FIXED            0x0
#define SAPIC_LOWEST_PRIORITY  0x1
#define SAPIC_PMI              0x2
#define SAPIC_NMI              0x4
#define SAPIC_INIT             0x5
#define SAPIC_EXTINT           0x7

/*
 *Interrupt polarity
 */
#define SAPIC_POLARITY_SHIFT   13
#define SAPIC_POL_HIGH         0
#define SAPIC_POL_LOW          1

/*
 *Trigger mode
 */
#define SAPIC_TRIGGER_SHIFT    15
#define SAPIC_EDGE             0
#define SAPIC_LEVEL            1

/*
 * LSAPIC OFFSET
 */
#define PIB_LOW_HALF(ofst)     !(ofst & (1 << 20))
#define PIB_OFST_INTA          0x1E0000
#define PIB_OFST_XTP           0x1E0008

/*
 *Mask bit
 */
#define SAPIC_MASK_SHIFT       16
#define SAPIC_MASK             (1 << SAPIC_MASK_SHIFT)

#define VLSAPIC_XTP(_v)        VMX(_v, xtp)

extern void vtm_init(struct vcpu *vcpu);
extern void vtm_set_itc(struct  vcpu *vcpu, uint64_t new_itc);
extern void vtm_set_itm(struct vcpu *vcpu, uint64_t val);
extern void vtm_set_itv(struct vcpu *vcpu, uint64_t val);
extern void vmx_vexirq(struct vcpu  *vcpu);
extern void vhpi_detection(struct vcpu *vcpu);
extern int vlsapic_deliver_int(struct domain *d,
			       uint16_t dest, uint64_t dm, uint64_t vector);

extern uint64_t vlsapic_read(struct vcpu *v, uint64_t addr, uint64_t s);
extern void vlsapic_write(struct vcpu *v, uint64_t addr, uint64_t s, uint64_t val);
#endif
