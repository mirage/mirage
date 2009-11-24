#ifndef __ASM_X86_MTRR_H__
#define __ASM_X86_MTRR_H__

#include <xen/config.h>
#include <asm/mm.h>

/* These are the region types. They match the architectural specification. */
#define MTRR_TYPE_UNCACHABLE 0
#define MTRR_TYPE_WRCOMB     1
#define MTRR_TYPE_WRTHROUGH  4
#define MTRR_TYPE_WRPROT     5
#define MTRR_TYPE_WRBACK     6
#define MTRR_NUM_TYPES       7
#define MEMORY_NUM_TYPES     MTRR_NUM_TYPES
#define NO_HARDCODE_MEM_TYPE    MTRR_NUM_TYPES

#define NORMAL_CACHE_MODE          0
#define NO_FILL_CACHE_MODE         2

enum {
    PAT_TYPE_UNCACHABLE=0,
    PAT_TYPE_WRCOMB=1,
    PAT_TYPE_RESERVED=2,
    PAT_TYPE_WRTHROUGH=4,
    PAT_TYPE_WRPROT=5,
    PAT_TYPE_WRBACK=6,
    PAT_TYPE_UC_MINUS=7,
    PAT_TYPE_NUMS
};

#define INVALID_MEM_TYPE PAT_TYPE_NUMS

/* In the Intel processor's MTRR interface, the MTRR type is always held in
   an 8 bit field: */
typedef u8 mtrr_type;

struct mtrr_var_range {
	u32 base_lo;
	u32 base_hi;
	u32 mask_lo;
	u32 mask_hi;
};

#define NUM_FIXED_RANGES 88
#define NUM_FIXED_MSR 11
struct mtrr_state {
	struct mtrr_var_range *var_ranges;
	mtrr_type fixed_ranges[NUM_FIXED_RANGES];
	unsigned char enabled;
	unsigned char have_fixed;
	mtrr_type def_type;

	u64       mtrr_cap;
	/* ranges in var MSRs are overlapped or not:0(no overlapped) */
	bool_t    overlapped;
};

extern void mtrr_save_fixed_ranges(void *);
extern void mtrr_save_state(void);
extern int mtrr_add(unsigned long base, unsigned long size,
                    unsigned int type, char increment);
extern int mtrr_add_page(unsigned long base, unsigned long size,
                         unsigned int type, char increment);
extern int mtrr_del(int reg, unsigned long base, unsigned long size);
extern int mtrr_del_page(int reg, unsigned long base, unsigned long size);
extern void mtrr_centaur_report_mcr(int mcr, u32 lo, u32 hi);
extern u32 get_pat_flags(struct vcpu *v, u32 gl1e_flags, paddr_t gpaddr,
                  paddr_t spaddr, uint8_t gmtrr_mtype);
extern uint8_t epte_get_entry_emt(struct domain *d, unsigned long gfn,
                                  mfn_t mfn, uint8_t *igmt, int direct_mmio);
extern void ept_change_entry_emt_with_range(
    struct domain *d, unsigned long start_gfn, unsigned long end_gfn);
extern unsigned char pat_type_2_pte_flags(unsigned char pat_type);
extern int hold_mtrr_updates_on_aps;
extern void mtrr_aps_sync_begin(void);
extern void mtrr_aps_sync_end(void);
extern void mtrr_bp_restore(void);

extern bool_t mtrr_var_range_msr_set(struct mtrr_state *v,
				uint32_t msr, uint64_t msr_content);
extern bool_t mtrr_fix_range_msr_set(struct mtrr_state *v,
				uint32_t row, uint64_t msr_content);
extern bool_t mtrr_def_type_msr_set(struct mtrr_state *v, uint64_t msr_content);
extern bool_t pat_msr_set(uint64_t *pat, uint64_t msr);

bool_t is_var_mtrr_overlapped(struct mtrr_state *m);
bool_t mtrr_pat_not_equal(struct vcpu *vd, struct vcpu *vs);

#endif /* __ASM_X86_MTRR_H__ */
