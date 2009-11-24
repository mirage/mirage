/*
 * xen/include/asm-ia64/hvm/save.h
 *
 * Copyright (c) 2007, Isaku Yamahata <yamahata at valinux co jp>
 *                     VA Linux Systems Japan K.K.
 *                     IA64 support
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

#ifndef __ASM_IA64_HVM_SUPPORT_H__
#define __ASM_IA64_HVM_SUPPORT_H__

#include <xen/hvm/save.h>

static int hvm_girq_dest_2_vcpu_id(struct domain *d, uint8_t dest,
                                uint8_t dest_mode)
{
    /* TODO */
}

static void hvm_migrate_pirqs(struct vcpu *v)
{
    /* TODO */
}

#endif /* __ASM_IA64_HVM_SUPPORT_H__ */
