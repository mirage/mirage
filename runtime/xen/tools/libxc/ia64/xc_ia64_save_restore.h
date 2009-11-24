/******************************************************************************
 * xc_ia64_save_restore.h
 *
 * Copyright (c) 2006 Isaku Yamahata <yamahata at valinux co jp>
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

#ifndef XC_IA64_SAVE_RESTORE_H
#define XC_IA64_SR_H

        /* introduced changeset 10692:306d7857928c of xen-ia64-unstable.ht */
#define XC_IA64_SR_FORMAT_VER_ONE       1UL
        /* using foreign p2m exposure version */
#define XC_IA64_SR_FORMAT_VER_TWO       2UL
        /* only pv change: send vcpumap and all vcpu context */
#define XC_IA64_SR_FORMAT_VER_THREE     3UL
#define XC_IA64_SR_FORMAT_VER_MAX       3UL

#define XC_IA64_SR_FORMAT_VER_CURRENT   XC_IA64_SR_FORMAT_VER_THREE

/*
** During (live) save/migrate, we maintain a number of bitmaps to track
** which pages we have to send, and to skip.
*/
#define BITS_PER_LONG (sizeof(unsigned long) * 8)

#define BITMAP_ENTRY(_nr,_bmap) \
   ((unsigned long *)(_bmap))[(_nr)/BITS_PER_LONG]

#define BITMAP_SHIFT(_nr) ((_nr) % BITS_PER_LONG)

static inline int __test_bit(int nr, void * addr)
{
    return (BITMAP_ENTRY(nr, addr) >> BITMAP_SHIFT(nr)) & 1;
}

static inline void __set_bit(int nr, void * addr)
{
    BITMAP_ENTRY(nr, addr) |= (1UL << BITMAP_SHIFT(nr));
}

#endif /* XC_IA64_SAVE_RESTORE_H */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
