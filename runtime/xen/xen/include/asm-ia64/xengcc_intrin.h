#ifndef _ASM_IA64_XENGCC_INTRIN_H
#define _ASM_IA64_XENGCC_INTRIN_H
/*
 * Flushrs instruction stream.
 */
#define ia64_flushrs() asm volatile ("flushrs;;":::"memory")

#define ia64_loadrs() asm volatile ("loadrs;;":::"memory")

#define ia64_get_rsc()                          \
({                                  \
    unsigned long val;                     \
    asm volatile ("mov %0=ar.rsc;;" : "=r"(val) :: "memory");  \
    val;                               \
})

#define ia64_set_rsc(val)                       \
    asm volatile ("mov ar.rsc=%0;;" :: "r"(val) : "memory")

#define ia64_get_bspstore()     \
({                                  \
    unsigned long val;                     \
    asm volatile ("mov %0=ar.bspstore;;" : "=r"(val) :: "memory");  \
    val;                               \
})

#define ia64_set_bspstore(val)                       \
    asm volatile ("mov ar.bspstore=%0;;" :: "r"(val) : "memory")

#define ia64_get_rnat()     \
({                                  \
    unsigned long val;                     \
    asm volatile ("mov %0=ar.rnat;" : "=r"(val) :: "memory");  \
    val;                               \
})

#define ia64_set_rnat(val)                       \
    asm volatile ("mov ar.rnat=%0;;" :: "r"(val) : "memory")

#define ia64_ttag(addr)							\
({										\
	__u64 ia64_intri_res;							\
	asm volatile ("ttag %0=%1" : "=r"(ia64_intri_res) : "r" (addr));	\
	ia64_intri_res;								\
})

#define ia64_get_dcr()                          \
({                                      \
    __u64 result;                               \
    asm volatile ("mov %0=cr.dcr" : "=r"(result) : );           \
    result;                                 \
})

#define ia64_set_dcr(val)                           \
({                                      \
    asm volatile ("mov cr.dcr=%0" :: "r"(val) );            \
})

#endif /* _ASM_IA64_XENGCC_INTRIN_H */
