/******************************************************************************
 * vmx_vcpu_save.h
 *
 * Copyright (c) 2007 Isaku Yamahata <yamahata at valinux co jp>
 *                    VA Linux Systems Japan K.K.
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
 *
 */
#ifndef __ASM_IA64_VMX_VCPU_SAVE_H__
#define __ASM_IA64_VMX_VCPU_SAVE_H__

#include <xen/sched.h>
#include <xen/domain.h>

void vmx_arch_get_info_guest(struct vcpu *v, vcpu_guest_context_u c);
int vmx_arch_set_info_guest(struct vcpu *v, vcpu_guest_context_u c);

#endif /* __ASM_IA64_VMX_VCPU_SAVE_H__ */
/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
