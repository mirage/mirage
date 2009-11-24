
#ifndef _REGIONREG_H_
#define _REGIONREG_H_

#define XEN_DEFAULT_RID         7
#define IA64_MIN_IMPL_RID_MSB   17
#define _REGION_ID(x)           ({ia64_rr _v; _v.rrval = (long)(x); _v.rid;})
#define _REGION_PAGE_SIZE(x)    ({ia64_rr _v; _v.rrval = (long)(x); _v.ps;})
#define _REGION_HW_WALKER(x)    ({ia64_rr _v; _v.rrval = (long)(x); _v.ve;})
#define _MAKE_RR(r, sz, v)      ({ia64_rr _v; _v.rrval=0; _v.rid=(r); \
                                        _v.ps=(sz); _v.ve=(v); _v.rrval;})

typedef union ia64_rr {
    struct {
        unsigned long  ve        :  1;  /* enable hw walker */
        unsigned long  reserved0 :  1;  /* reserved */
        unsigned long  ps        :  6;  /* log page size */
        unsigned long  rid       : 24;  /* region id */
        unsigned long  reserved1 : 32;  /* reserved */
    };
    unsigned long rrval;
} ia64_rr;

//
// region register macros
//
#define RR_TO_VE(arg)   (((arg) >> 0) & 0x0000000000000001)
#define RR_VE(arg)      (((arg) & 0x0000000000000001) << 0)
#define RR_VE_MASK      0x0000000000000001L
#define RR_VE_SHIFT     0
#define RR_TO_PS(arg)   (((arg) >> 2) & 0x000000000000003f)
#define RR_PS(arg)      (((arg) & 0x000000000000003f) << 2)
#define RR_PS_MASK      0x00000000000000fcL
#define RR_PS_SHIFT     2
#define RR_TO_RID(arg)  (((arg) >> 8) & 0x0000000000ffffff)
#define RR_RID(arg)     (((arg) & 0x0000000000ffffff) << 8)
#define RR_RID_MASK     0x00000000ffffff00L

DECLARE_PER_CPU(unsigned long, domain_shared_info);
DECLARE_PER_CPU(unsigned long, inserted_vhpt);
DECLARE_PER_CPU(unsigned long, inserted_shared_info);
DECLARE_PER_CPU(unsigned long, inserted_mapped_regs);
DECLARE_PER_CPU(unsigned long, inserted_vpd);

extern cpumask_t percpu_set;

int set_one_rr(unsigned long rr, unsigned long val);
int set_one_rr_efi(unsigned long rr, unsigned long val);
void set_one_rr_efi_restore(unsigned long rr, unsigned long val);

// This function is purely for performance... apparently scrambling
//  bits in the region id makes for better hashing, which means better
//  use of the VHPT, which means better performance
// Note that the only time a RID should be mangled is when it is stored in
//  a region register; anytime it is "viewable" outside of this module,
//  it should be unmangled

// NOTE: this function is also implemented in assembly code in hyper_set_rr!!
// Must ensure these two remain consistent!
static inline unsigned long
vmMangleRID(unsigned long RIDVal)
{
    union bits64 {
        unsigned char bytes[4];
        unsigned long uint;
    };
    union bits64 t;
    unsigned char tmp;

    t.uint = RIDVal;
    tmp = t.bytes[1];
    t.bytes[1] = t.bytes[3];
    t.bytes[3] = tmp;

    return t.uint;
}

// since vmMangleRID is symmetric, use it for unmangling also
#define vmUnmangleRID(x)    vmMangleRID(x)

extern void init_rid_allocator (void);

struct domain;

/* Allocate RIDs range and metaphysical RIDs for domain d.
   If ridbits is 0, a default value is used instead.  */
extern int allocate_rid_range(struct domain *d, unsigned long ridbits);
extern int deallocate_rid_range(struct domain *d);

struct vcpu;
extern void init_all_rr(struct vcpu *v);

extern void set_virtual_rr0(void);
extern void set_metaphysical_rr0(void);

extern void load_region_regs(struct vcpu *v);

extern int is_reserved_rr_rid(struct vcpu *vcpu, u64 reg_value);
extern int is_reserved_rr_field(struct vcpu *vcpu, u64 reg_value);

#endif /* !_REGIONREG_H_ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
