/* -*-  Mode:C; c-basic-offset:4; tab-width:4; indent-tabs-mode:nil -*- */
/*
 * vmx_mm_def.h: 
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
 *      Kun Tian (Kevin Tian) (kevin.tian@intel.com)
 */
#ifndef _MM_DEF_H_
#define _MM_DEF_H_


/* VHPT size 4M */
//#define VHPT_SIZE_PS    22
//#define VHPT_SIZE   (1 << VHPT_SIZE_PS)
#define ARCH_PAGE_SHIFT   12
#define ARCH_PAGE_SIZE    PSIZE(ARCH_PAGE_SHIFT)
#define MAX_PHYS_ADDR_BITS  50
#define GUEST_IMPL_VA_MSB   59
#define PMASK(size)         (~((size) - 1))
#define PSIZE(size)         (1UL<<(size))
//#define PAGE_SIZE_4K        PSIZE(12)
#define POFFSET(vaddr, ps)  ((vaddr) & (PSIZE(ps) - 1))
#define PPN_2_PA(ppn)       ((ppn)<<12)
#define CLEARLSB(ppn, nbits)    ((((uint64_t)ppn) >> (nbits)) << (nbits))
#define PAGEALIGN(va, ps)	CLEARLSB(va, ps)

#define TLB_AR_R        0
#define TLB_AR_RX       1
#define TLB_AR_RW       2
#define TLB_AR_RWX      3
#define TLB_AR_R_RW     4
#define TLB_AR_RX_RWX       5
#define TLB_AR_RWX_RW       6
#define TLB_AR_XP       7

#define IA64_ISR_CODE_MASK0     0xf
#define IA64_UNIMPL_DADDR_FAULT     0x30
#define IA64_UNIMPL_IADDR_TRAP      0x10
#define IA64_RESERVED_REG_FAULT     0x30
#define IA64_REG_NAT_CONSUMPTION_FAULT  0x10
#define IA64_NAT_CONSUMPTION_FAULT  0x20
#define IA64_PRIV_OP_FAULT      0x10

#define DEFER_NONE      0
#define DEFER_ALWAYS        0x1
#define DEFER_DM        0x100       /* bit 8 */
#define DEFER_DP        0X200       /* bit 9 */
#define DEFER_DK        0x400       /* bit 10 */
#define DEFER_DX        0x800       /* bit 11 */
#define DEFER_DR        0x1000      /* bit 12 */
#define DEFER_DA        0x2000      /* bit 13 */
#define DEFER_DD        0x4000      /* bit 14 */

#define ACCESS_RIGHT(a) ((a) & (ACCESS_FETCHADD - 1))

#define ACCESS_READ     0x1
#define ACCESS_WRITE        0x2
#define ACCESS_EXECUTE      0x4
#define ACCESS_XP0      0x8
#define ACCESS_XP1      0x10
#define ACCESS_XP2      0x20
#define ACCESS_FETCHADD     0x40
#define ACCESS_XCHG     0x80
#define ACCESS_CMPXCHG      0x100

#define ACCESS_SIZE_1       0x10000 
#define ACCESS_SIZE_2       0x20000
#define ACCESS_SIZE_4       0x40000
#define ACCESS_SIZE_8       0x80000
#define ACCESS_SIZE_10      0x100000
#define ACCESS_SIZE_16      0x200000

#define STLB_TC         0
#define STLB_TR         1

#define IA64_RR_SHIFT       61

#define PHYS_PAGE_SHIFT     PPN_SHIFT

#define STLB_SZ_SHIFT       8       // 256
#define STLB_SIZE       (1UL<<STLB_SZ_SHIFT)
#define STLB_PPS_SHIFT      12
#define STLB_PPS        (1UL<<STLB_PPS_SHIFT)
#define GUEST_TRNUM     8

/* Virtual address memory attributes encoding */
#define VA_MATTR_WB     0x0
#define VA_MATTR_UC     0x4
#define VA_MATTR_UCE        0x5
#define VA_MATTR_WC     0x6
#define VA_MATTR_NATPAGE    0x7

#define VRN_MASK        0xe000000000000000
#define PTA_BASE_MASK       0x3fffffffffffL
#define PTA_BASE_SHIFT      15
#define VHPT_OFFSET_MASK    0x7fff

#define BITS_SHIFT_256MB    28
#define SIZE_256MB      (1UL<<BITS_SHIFT_256MB)
#define TLB_GR_RV_BITS      ((1UL<<1) | (3UL<<50))
#define HPA_MAPPING_ATTRIBUTE   0x61  //ED:0;AR:0;PL:0;D:1;A:1;P:1
#define VPN_2_VRN(vpn)  ((vpn << PPN_SHIFT) >> IA64_VRN_SHIFT)

#ifndef __ASSEMBLY__
typedef enum { INSTRUCTION, DATA, REGISTER } miss_type;

//typedef enum { MVHPT, STLB } vtlb_loc_type_t;
typedef enum { DATA_REF, NA_REF, INST_REF, RSE_REF } vhpt_ref_t;

static __inline__ uint64_t
bits_v(uint64_t v, uint32_t bs, uint32_t be)
{
    uint64_t    result;
    __asm __volatile("shl %0=%1, %2;; shr.u %0=%0, %3;;"
        : "=r" (result): "r"(v), "r"(63-be), "r" (bs+63-be) );
    return result;
}

#define bits(val, bs, be)                                         \
({                                                              \
        u64        ret;                                    \
                                                                \
        __asm __volatile("extr.u %0=%1, %2, %3"                 \
                : "=r" (ret): "r"(val),                           \
                  "M" ((bs)),                                   \
                  "M" ((be) - (bs) + 1) );                      \
        ret;                                                    \
})

/*
 * clear bits (pos, len) from v.
 *
 */
#define clearbits(v, pos, len)                                  \
({                                                              \
        u64        ret;                                    \
                                                                \
        __asm __volatile("dep.z %0=%1, %2, %3"                  \
                : "=r" (ret): "r"(v),                           \
                  "M" ((pos)),                                  \
                  "M" ((len)));                                 \
         ret;                                                   \
 })
#endif

#endif
