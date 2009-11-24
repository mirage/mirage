#ifndef XG_PRIVATE_H
#define XG_PRIVATE_H

#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "xenctrl.h"
#include "xenguest.h"
#include "xc_private.h"

#include <xen/memory.h>
#include <xen/elfnote.h>

#ifndef ELFSIZE
#include <limits.h>
#if UINT_MAX == ULONG_MAX
#define ELFSIZE 32
#else
#define ELFSIZE 64
#endif
#endif

char *xc_read_image(const char *filename, unsigned long *size);
char *xc_inflate_buffer(const char *in_buf,
                        unsigned long in_size,
                        unsigned long *out_size);

unsigned long csum_page (void * page);

#define _PAGE_PRESENT   0x001
#define _PAGE_RW        0x002
#define _PAGE_USER      0x004
#define _PAGE_PWT       0x008
#define _PAGE_PCD       0x010
#define _PAGE_ACCESSED  0x020
#define _PAGE_DIRTY     0x040
#define _PAGE_PAT       0x080
#define _PAGE_PSE       0x080
#define _PAGE_GLOBAL    0x100

#define L1_PAGETABLE_SHIFT_I386       12
#define L2_PAGETABLE_SHIFT_I386       22
#define L1_PAGETABLE_ENTRIES_I386   1024
#define L2_PAGETABLE_ENTRIES_I386   1024

#define L1_PAGETABLE_SHIFT_PAE        12
#define L2_PAGETABLE_SHIFT_PAE        21
#define L3_PAGETABLE_SHIFT_PAE        30
#define L1_PAGETABLE_ENTRIES_PAE     512
#define L2_PAGETABLE_ENTRIES_PAE     512
#define L3_PAGETABLE_ENTRIES_PAE       4

#define L1_PAGETABLE_SHIFT_X86_64     12
#define L2_PAGETABLE_SHIFT_X86_64     21
#define L3_PAGETABLE_SHIFT_X86_64     30
#define L4_PAGETABLE_SHIFT_X86_64     39
#define L1_PAGETABLE_ENTRIES_X86_64  512
#define L2_PAGETABLE_ENTRIES_X86_64  512
#define L3_PAGETABLE_ENTRIES_X86_64  512
#define L4_PAGETABLE_ENTRIES_X86_64  512

#if defined(__i386__)
#define L1_PAGETABLE_SHIFT     L1_PAGETABLE_SHIFT_I386
#define L2_PAGETABLE_SHIFT     L2_PAGETABLE_SHIFT_I386
#define L1_PAGETABLE_ENTRIES   L1_PAGETABLE_ENTRIES_I386
#define L2_PAGETABLE_ENTRIES   L2_PAGETABLE_ENTRIES_I386
#elif defined(__x86_64__)
#define L1_PAGETABLE_SHIFT     L1_PAGETABLE_SHIFT_X86_64
#define L2_PAGETABLE_SHIFT     L2_PAGETABLE_SHIFT_X86_64
#define L3_PAGETABLE_SHIFT     L3_PAGETABLE_SHIFT_X86_64
#define L4_PAGETABLE_SHIFT     L4_PAGETABLE_SHIFT_X86_64
#define L1_PAGETABLE_ENTRIES   L1_PAGETABLE_ENTRIES_X86_64
#define L2_PAGETABLE_ENTRIES   L2_PAGETABLE_ENTRIES_X86_64
#define L3_PAGETABLE_ENTRIES   L3_PAGETABLE_ENTRIES_X86_64
#define L4_PAGETABLE_ENTRIES   L4_PAGETABLE_ENTRIES_X86_64
#endif

typedef uint32_t l1_pgentry_32_t;
typedef uint32_t l2_pgentry_32_t;
typedef uint64_t l1_pgentry_64_t;
typedef uint64_t l2_pgentry_64_t;
typedef uint64_t l3_pgentry_64_t;
typedef uint64_t l4_pgentry_64_t;

#if defined(__i386__)
typedef l1_pgentry_32_t l1_pgentry_t;
typedef l2_pgentry_32_t l2_pgentry_t;
#elif defined(__x86_64__)
typedef l1_pgentry_64_t l1_pgentry_t;
typedef l2_pgentry_64_t l2_pgentry_t;
typedef l3_pgentry_64_t l3_pgentry_t;
typedef l4_pgentry_64_t l4_pgentry_t;
#endif

#define l1_table_offset_i386(_a) \
  (((_a) >> L1_PAGETABLE_SHIFT_I386) & (L1_PAGETABLE_ENTRIES_I386 - 1))
#define l2_table_offset_i386(_a) \
  (((_a) >> L2_PAGETABLE_SHIFT_I386) & (L2_PAGETABLE_ENTRIES_I386 - 1))

#define l1_table_offset_pae(_a) \
  (((_a) >> L1_PAGETABLE_SHIFT_PAE) & (L1_PAGETABLE_ENTRIES_PAE - 1))
#define l2_table_offset_pae(_a) \
  (((_a) >> L2_PAGETABLE_SHIFT_PAE) & (L2_PAGETABLE_ENTRIES_PAE - 1))
#define l3_table_offset_pae(_a) \
  (((_a) >> L3_PAGETABLE_SHIFT_PAE) & (L3_PAGETABLE_ENTRIES_PAE - 1))

#define l1_table_offset_x86_64(_a) \
  (((_a) >> L1_PAGETABLE_SHIFT_X86_64) & (L1_PAGETABLE_ENTRIES_X86_64 - 1))
#define l2_table_offset_x86_64(_a) \
  (((_a) >> L2_PAGETABLE_SHIFT_X86_64) & (L2_PAGETABLE_ENTRIES_X86_64 - 1))
#define l3_table_offset_x86_64(_a) \
  (((_a) >> L3_PAGETABLE_SHIFT_X86_64) & (L3_PAGETABLE_ENTRIES_X86_64 - 1))
#define l4_table_offset_x86_64(_a) \
  (((_a) >> L4_PAGETABLE_SHIFT_X86_64) & (L4_PAGETABLE_ENTRIES_X86_64 - 1))

#if defined(__i386__)
#define l1_table_offset(_a) l1_table_offset_i386(_a)
#define l2_table_offset(_a) l2_table_offset_i386(_a)
#elif defined(__x86_64__)
#define l1_table_offset(_a) l1_table_offset_x86_64(_a)
#define l2_table_offset(_a) l2_table_offset_x86_64(_a)
#define l3_table_offset(_a) l3_table_offset_x86_64(_a)
#define l4_table_offset(_a) l4_table_offset_x86_64(_a)
#endif

#define PAGE_SHIFT_X86          12
#define PAGE_SIZE_X86           (1UL << PAGE_SHIFT_X86)
#define PAGE_MASK_X86           (~(PAGE_SIZE_X86-1))

#define PAGE_SHIFT_IA64         14
#define PAGE_SIZE_IA64          (1UL << PAGE_SHIFT_IA64)
#define PAGE_MASK_IA64          (~(PAGE_SIZE_IA64-1))

#define ROUNDUP(_x,_w) (((unsigned long)(_x)+(1UL<<(_w))-1) & ~((1UL<<(_w))-1))


/* XXX SMH: following skanky macros rely on variable p2m_size being set */
/* XXX TJD: also, "guest_width" should be the guest's sizeof(unsigned long) */

/* Number of xen_pfn_t in a page */

#define FPP             (PAGE_SIZE/(guest_width))

/* Number of entries in the pfn_to_mfn_frame_list_list */
#define P2M_FLL_ENTRIES (((p2m_size)+(FPP*FPP)-1)/(FPP*FPP))

/* Number of entries in the pfn_to_mfn_frame_list */
#define P2M_FL_ENTRIES  (((p2m_size)+FPP-1)/FPP)

/* Size in bytes of the pfn_to_mfn_frame_list     */
#define P2M_GUEST_FL_SIZE ((P2M_FL_ENTRIES) * (guest_width))
#define P2M_TOOLS_FL_SIZE ((P2M_FL_ENTRIES) *                           \
                           MAX((sizeof (xen_pfn_t)), guest_width))

/* Masks for PTE<->PFN conversions */
#define MADDR_BITS_X86  ((guest_width == 8) ? 52 : 44)
#define MFN_MASK_X86    ((1ULL << (MADDR_BITS_X86 - PAGE_SHIFT_X86)) - 1)
#define MADDR_MASK_X86  (MFN_MASK_X86 << PAGE_SHIFT_X86)


#define PAEKERN_no           0
#define PAEKERN_yes          1
#define PAEKERN_extended_cr3 2
#define PAEKERN_bimodal      3

int pin_table(int xc_handle, unsigned int type, unsigned long mfn,
              domid_t dom);

void *xg_memalign(size_t alignment, size_t size);

#endif /* XG_PRIVATE_H */
