/******************************************************************************
 * include/asm-x86/hap.h
 *
 * hardware-assisted paging
 * Copyright (c) 2007 Advanced Micro Devices (Wei Huang)
 *
 * Parts of this code are Copyright (c) 2006 by XenSource Inc.
 * Parts of this code are Copyright (c) 2006 by Michael A Fetterman
 * Parts based on earlier work by Michael A Fetterman, Ian Pratt et al.
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

#ifndef _XEN_HAP_H
#define _XEN_HAP_H

#define HAP_PRINTK(_f, _a...)                                         \
    debugtrace_printk("hap: %s(): " _f, __func__, ##_a)
#define HAP_ERROR(_f, _a...)                                          \
    printk("hap error: %s(): " _f, __func__, ##_a)

/************************************************/
/*          hap domain page mapping             */
/************************************************/
static inline void *
hap_map_domain_page(mfn_t mfn)
{
    return map_domain_page(mfn_x(mfn));
}

static inline void
hap_unmap_domain_page(void *p)
{
    unmap_domain_page(p);
}

/************************************************/
/*           locking for hap code               */
/************************************************/
#define hap_lock_init(_d)                                   \
    do {                                                    \
        spin_lock_init(&(_d)->arch.paging.hap.lock);        \
        (_d)->arch.paging.hap.locker = -1;                  \
        (_d)->arch.paging.hap.locker_function = "nobody";   \
    } while (0)

#define hap_locked_by_me(_d)                     \
    (current->processor == (_d)->arch.paging.hap.locker)

#define hap_lock(_d)                                                       \
    do {                                                                   \
        if ( unlikely((_d)->arch.paging.hap.locker == current->processor) )\
        {                                                                  \
            printk("Error: hap lock held by %s\n",                         \
                   (_d)->arch.paging.hap.locker_function);                 \
            BUG();                                                         \
        }                                                                  \
        spin_lock(&(_d)->arch.paging.hap.lock);                            \
        ASSERT((_d)->arch.paging.hap.locker == -1);                        \
        (_d)->arch.paging.hap.locker = current->processor;                 \
        (_d)->arch.paging.hap.locker_function = __func__;                  \
    } while (0)

#define hap_unlock(_d)                                              \
    do {                                                            \
        ASSERT((_d)->arch.paging.hap.locker == current->processor); \
        (_d)->arch.paging.hap.locker = -1;                          \
        (_d)->arch.paging.hap.locker_function = "nobody";           \
        spin_unlock(&(_d)->arch.paging.hap.lock);                   \
    } while (0)

/************************************************/
/*        hap domain level functions            */
/************************************************/
void  hap_domain_init(struct domain *d);
int   hap_domctl(struct domain *d, xen_domctl_shadow_op_t *sc,
                 XEN_GUEST_HANDLE(void) u_domctl);
int   hap_enable(struct domain *d, u32 mode);
void  hap_final_teardown(struct domain *d);
void  hap_teardown(struct domain *d);
void  hap_vcpu_init(struct vcpu *v);
void  hap_logdirty_init(struct domain *d);
int   hap_track_dirty_vram(struct domain *d,
                           unsigned long begin_pfn,
                           unsigned long nr,
                           XEN_GUEST_HANDLE_64(uint8) dirty_bitmap);

#endif /* XEN_HAP_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 */
