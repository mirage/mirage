#ifndef __ARCH_DESC_H
#define __ARCH_DESC_H

/*
 * Xen reserves a memory page of GDT entries.
 * No guest GDT entries exist beyond the Xen reserved area.
 */
#define NR_RESERVED_GDT_PAGES   1
#define NR_RESERVED_GDT_BYTES   (NR_RESERVED_GDT_PAGES * PAGE_SIZE)
#define NR_RESERVED_GDT_ENTRIES (NR_RESERVED_GDT_BYTES / 8)

#define LAST_RESERVED_GDT_PAGE  \
    (FIRST_RESERVED_GDT_PAGE + NR_RESERVED_GDT_PAGES - 1)
#define LAST_RESERVED_GDT_BYTE  \
    (FIRST_RESERVED_GDT_BYTE + NR_RESERVED_GDT_BYTES - 1)
#define LAST_RESERVED_GDT_ENTRY \
    (FIRST_RESERVED_GDT_ENTRY + NR_RESERVED_GDT_ENTRIES - 1)

#define LDT_ENTRY_SIZE 8

#if defined(__x86_64__)

#define FLAT_COMPAT_RING1_CS 0xe019  /* GDT index 259 */
#define FLAT_COMPAT_RING1_DS 0xe021  /* GDT index 260 */
#define FLAT_COMPAT_RING1_SS 0xe021  /* GDT index 260 */
#define FLAT_COMPAT_RING3_CS 0xe02b  /* GDT index 261 */
#define FLAT_COMPAT_RING3_DS 0xe033  /* GDT index 262 */
#define FLAT_COMPAT_RING3_SS 0xe033  /* GDT index 262 */

#define FLAT_COMPAT_KERNEL_DS FLAT_COMPAT_RING1_DS
#define FLAT_COMPAT_KERNEL_CS FLAT_COMPAT_RING1_CS
#define FLAT_COMPAT_KERNEL_SS FLAT_COMPAT_RING1_SS
#define FLAT_COMPAT_USER_DS   FLAT_COMPAT_RING3_DS
#define FLAT_COMPAT_USER_CS   FLAT_COMPAT_RING3_CS
#define FLAT_COMPAT_USER_SS   FLAT_COMPAT_RING3_SS

#define TSS_ENTRY (FIRST_RESERVED_GDT_ENTRY + 8)
#define LDT_ENTRY (TSS_ENTRY + 2)
#define PER_CPU_GDT_ENTRY (LDT_ENTRY + 2)

#elif defined(__i386__)

#define FLAT_COMPAT_KERNEL_CS FLAT_KERNEL_CS
#define FLAT_COMPAT_KERNEL_DS FLAT_KERNEL_DS
#define FLAT_COMPAT_KERNEL_SS FLAT_KERNEL_SS
#define FLAT_COMPAT_USER_CS   FLAT_USER_CS
#define FLAT_COMPAT_USER_DS   FLAT_USER_DS
#define FLAT_COMPAT_USER_SS   FLAT_USER_SS

#define DOUBLEFAULT_TSS_ENTRY FIRST_RESERVED_GDT_ENTRY

#define TSS_ENTRY (FIRST_RESERVED_GDT_ENTRY + 8)
#define LDT_ENTRY (TSS_ENTRY + 1)
#define PER_CPU_GDT_ENTRY (LDT_ENTRY + 1)

#endif

#ifndef __ASSEMBLY__

#if defined(__x86_64__)
#define GUEST_KERNEL_RPL(d) (is_pv_32bit_domain(d) ? 1 : 3)
#elif defined(__i386__)
#define GUEST_KERNEL_RPL(d) ((void)(d), 1)
#endif

/* Fix up the RPL of a guest segment selector. */
#define __fixup_guest_selector(d, sel)                             \
({                                                                 \
    uint16_t _rpl = GUEST_KERNEL_RPL(d);                           \
    (sel) = (((sel) & 3) >= _rpl) ? (sel) : (((sel) & ~3) | _rpl); \
})

/* Stack selectors don't need fixing up if the kernel runs in ring 0. */
#ifdef CONFIG_X86_SUPERVISOR_MODE_KERNEL
#define fixup_guest_stack_selector(d, ss) ((void)0)
#else
#define fixup_guest_stack_selector(d, ss) __fixup_guest_selector(d, ss)
#endif

/*
 * Code selectors are always fixed up. It allows the Xen exit stub to detect
 * return to guest context, even when the guest kernel runs in ring 0.
 */
#define fixup_guest_code_selector(d, cs)  __fixup_guest_selector(d, cs)

/*
 * We need this function because enforcing the correct guest kernel RPL is
 * unsufficient if the selector is poked into an interrupt, trap or call gate.
 * The selector RPL is ignored when a gate is accessed. We must therefore make
 * sure that the selector does not reference a Xen-private segment.
 * 
 * Note that selectors used only by IRET do not need to be checked. If the
 * descriptor DPL fiffers from CS RPL then we'll #GP.
 * 
 * Stack and data selectors do not need to be checked. If DS, ES, FS, GS are
 * DPL < CPL then they'll be cleared automatically. If SS RPL or DPL differs
 * from CS RPL then we'll #GP.
 */
#define guest_gate_selector_okay(d, sel)                                \
    ((((sel)>>3) < FIRST_RESERVED_GDT_ENTRY) || /* Guest seg? */        \
     ((sel) == (!is_pv_32on64_domain(d) ?                               \
                FLAT_KERNEL_CS :                /* Xen default seg? */  \
                FLAT_COMPAT_KERNEL_CS)) ||                              \
     ((sel) & 4))                               /* LDT seg? */

#endif /* __ASSEMBLY__ */

/* These are bitmasks for the high 32 bits of a descriptor table entry. */
#define _SEGMENT_TYPE    (15<< 8)
#define _SEGMENT_WR      ( 1<< 9) /* Writeable (data) or Readable (code)
                                     segment */
#define _SEGMENT_EC      ( 1<<10) /* Expand-down or Conforming segment */
#define _SEGMENT_CODE    ( 1<<11) /* Code (vs data) segment for non-system
                                     segments */
#define _SEGMENT_S       ( 1<<12) /* System descriptor (yes iff S==0) */
#define _SEGMENT_DPL     ( 3<<13) /* Descriptor Privilege Level */
#define _SEGMENT_P       ( 1<<15) /* Segment Present */
#ifdef __x86_64__
#define _SEGMENT_L       ( 1<<21) /* 64-bit segment */
#else
#define _SEGMENT_L       0
#endif
#define _SEGMENT_DB      ( 1<<22) /* 16- or 32-bit segment */
#define _SEGMENT_G       ( 1<<23) /* Granularity */

#ifndef __ASSEMBLY__

struct desc_struct {
    u32 a, b;
};

#if defined(__x86_64__)

typedef struct {
    u64 a, b;
} idt_entry_t;

#define _set_gate(gate_addr,type,dpl,addr)               \
do {                                                     \
    (gate_addr)->a = 0;                                  \
    wmb(); /* disable gate /then/ rewrite */             \
    (gate_addr)->b =                                     \
        ((unsigned long)(addr) >> 32);                   \
    wmb(); /* rewrite /then/ enable gate */              \
    (gate_addr)->a =                                     \
        (((unsigned long)(addr) & 0xFFFF0000UL) << 32) | \
        ((unsigned long)(dpl) << 45) |                   \
        ((unsigned long)(type) << 40) |                  \
        ((unsigned long)(addr) & 0xFFFFUL) |             \
        ((unsigned long)__HYPERVISOR_CS64 << 16) |       \
        (1UL << 47);                                     \
} while (0)

#define _set_tssldt_desc(desc,addr,limit,type)           \
do {                                                     \
    (desc)[0].b = (desc)[1].b = 0;                       \
    wmb(); /* disable entry /then/ rewrite */            \
    (desc)[0].a =                                        \
        ((u32)(addr) << 16) | ((u32)(limit) & 0xFFFF);   \
    (desc)[1].a = (u32)(((unsigned long)(addr)) >> 32);  \
    wmb(); /* rewrite /then/ enable entry */             \
    (desc)[0].b =                                        \
        ((u32)(addr) & 0xFF000000U) |                    \
        ((u32)(type) << 8) | 0x8000U |                   \
        (((u32)(addr) & 0x00FF0000U) >> 16);             \
} while (0)

#elif defined(__i386__)

typedef struct desc_struct idt_entry_t;

#define _set_gate(gate_addr,type,dpl,addr)               \
do {                                                     \
    (gate_addr)->b = 0;                                  \
    wmb(); /* disable gate /then/ rewrite */             \
    (gate_addr)->a =                                     \
        ((unsigned long)(addr) & 0xFFFFUL) |             \
        ((unsigned long)__HYPERVISOR_CS << 16);          \
    wmb(); /* rewrite /then/ enable gate */              \
    (gate_addr)->b =                                     \
        ((unsigned long)(addr) & 0xFFFF0000UL) |         \
        ((unsigned long)(dpl) << 13) |                   \
        ((unsigned long)(type) << 8) |                   \
        (1UL << 15);                                     \
} while (0)

#define _set_tssldt_desc(desc,addr,limit,type)           \
do {                                                     \
    (desc)->b = 0;                                       \
    wmb(); /* disable entry /then/ rewrite */            \
    (desc)->a =                                          \
        ((u32)(addr) << 16) | ((u32)(limit) & 0xFFFF);   \
    wmb(); /* rewrite /then/ enable entry */             \
    (desc)->b =                                          \
        ((u32)(addr) & 0xFF000000U) |                    \
        ((u32)(type) << 8) | 0x8000U |                   \
        (((u32)(addr) & 0x00FF0000U) >> 16);             \
} while (0)

DECLARE_PER_CPU(struct tss_struct *, doublefault_tss);

#endif

struct desc_ptr {
	unsigned short limit;
	unsigned long base;
} __attribute__((__packed__)) ;

extern struct desc_struct boot_cpu_gdt_table[];
DECLARE_PER_CPU(struct desc_struct *, gdt_table);
#ifdef CONFIG_COMPAT
extern struct desc_struct boot_cpu_compat_gdt_table[];
DECLARE_PER_CPU(struct desc_struct *, compat_gdt_table);
#else
# define boot_cpu_compat_gdt_table boot_cpu_gdt_table
# define per_cpu__compat_gdt_table per_cpu__gdt_table
#endif

extern void set_intr_gate(unsigned int irq, void * addr);
extern void load_TR(void);

#endif /* !__ASSEMBLY__ */

#endif /* __ARCH_DESC_H */
