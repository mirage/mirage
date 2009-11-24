/*
 * Copyright (c) 2007, 2008 Advanced Micro Devices, Inc.
 * Author: Christoph Egger <Christoph.Egger@amd.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef ASM_TRAP_H
#define ASM_TRAP_H

struct softirq_trap {
	struct domain *domain;  /* domain to inject trap */
	struct vcpu *vcpu;	/* vcpu to inject trap */
	int processor;		/* physical cpu to inject trap */
};

struct cpu_user_regs;

extern void machine_check_vector(struct cpu_user_regs *regs, long error_code);
 
/**
 * guest_has_trap_callback
 *
 * returns true (non-zero) if guest registered a trap handler
 */
extern int guest_has_trap_callback(struct domain *d, uint16_t vcpuid,
				unsigned int trap_nr);

/**
 * send_guest_trap
 *
 * delivers trap to guest analogous to send_guest_global_virq
 * return 0 on successful delivery
 */
extern int send_guest_trap(struct domain *d, uint16_t vcpuid,
				unsigned int trap_nr);

/* Guest vMCE MSRs virtualization */
extern void mce_init_msr(struct domain *d);
extern int mce_wrmsr(uint32_t msr, uint64_t val);
extern int mce_rdmsr(uint32_t msr, uint64_t *val);

#endif /* ASM_TRAP_H */
