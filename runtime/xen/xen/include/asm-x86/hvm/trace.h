#ifndef __ASM_X86_HVM_TRACE_H__
#define __ASM_X86_HVM_TRACE_H__

#include <xen/trace.h>

#define DEFAULT_HVM_TRACE_ON  1
#define DEFAULT_HVM_TRACE_OFF 0

#define DEFAULT_HVM_VMSWITCH   DEFAULT_HVM_TRACE_ON
#define DEFAULT_HVM_PF         DEFAULT_HVM_TRACE_ON
#define DEFAULT_HVM_INJECT     DEFAULT_HVM_TRACE_ON
#define DEFAULT_HVM_IO         DEFAULT_HVM_TRACE_ON
#define DEFAULT_HVM_REGACCESS  DEFAULT_HVM_TRACE_ON
#define DEFAULT_HVM_MISC       DEFAULT_HVM_TRACE_ON
#define DEFAULT_HVM_INTR       DEFAULT_HVM_TRACE_ON

#define DO_TRC_HVM_VMENTRY     DEFAULT_HVM_VMSWITCH
#define DO_TRC_HVM_VMEXIT      DEFAULT_HVM_VMSWITCH
#define DO_TRC_HVM_VMEXIT64    DEFAULT_HVM_VMSWITCH
#define DO_TRC_HVM_PF_XEN      DEFAULT_HVM_PF
#define DO_TRC_HVM_PF_XEN64    DEFAULT_HVM_PF
#define DO_TRC_HVM_PF_INJECT   DEFAULT_HVM_PF
#define DO_TRC_HVM_PF_INJECT64 DEFAULT_HVM_PF
#define DO_TRC_HVM_INJ_EXC     DEFAULT_HVM_INJECT
#define DO_TRC_HVM_INJ_VIRQ    DEFAULT_HVM_INJECT
#define DO_TRC_HVM_REINJ_VIRQ  DEFAULT_HVM_INJECT
#define DO_TRC_HVM_INTR_WINDOW DEFAULT_HVM_INJECT
#define DO_TRC_HVM_IO_READ     DEFAULT_HVM_IO
#define DO_TRC_HVM_IO_WRITE    DEFAULT_HVM_IO
#define DO_TRC_HVM_CR_READ     DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_CR_READ64   DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_CR_WRITE    DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_CR_WRITE64  DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_DR_READ     DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_DR_WRITE    DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_MSR_READ    DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_MSR_WRITE   DEFAULT_HVM_REGACCESS
#define DO_TRC_HVM_CPUID       DEFAULT_HVM_MISC
#define DO_TRC_HVM_INTR        DEFAULT_HVM_INTR
#define DO_TRC_HVM_NMI         DEFAULT_HVM_INTR
#define DO_TRC_HVM_MCE         DEFAULT_HVM_INTR
#define DO_TRC_HVM_SMI         DEFAULT_HVM_INTR
#define DO_TRC_HVM_VMMCALL     DEFAULT_HVM_MISC
#define DO_TRC_HVM_HLT         DEFAULT_HVM_MISC
#define DO_TRC_HVM_INVLPG      DEFAULT_HVM_MISC
#define DO_TRC_HVM_INVLPG64    DEFAULT_HVM_MISC
#define DO_TRC_HVM_IO_ASSIST   DEFAULT_HVM_MISC
#define DO_TRC_HVM_MMIO_ASSIST DEFAULT_HVM_MISC
#define DO_TRC_HVM_CLTS        DEFAULT_HVM_MISC
#define DO_TRC_HVM_LMSW        DEFAULT_HVM_MISC
#define DO_TRC_HVM_LMSW64      DEFAULT_HVM_MISC


#ifdef __x86_64__
#define TRC_PAR_LONG(par) ((par)&0xFFFFFFFF),((par)>>32)
#else
#define TRC_PAR_LONG(par) (par)
#endif

#define HVMTRACE_ND(evt, cycles, count, d1, d2, d3, d4, d5, d6)         \
    do {                                                                \
        if ( unlikely(tb_init_done) && DO_TRC_HVM_ ## evt )             \
        {                                                               \
            struct {                                                    \
                u32 d[6];                                               \
            } _d;                                                       \
            _d.d[0]=(d1);                                               \
            _d.d[1]=(d2);                                               \
            _d.d[2]=(d3);                                               \
            _d.d[3]=(d4);                                               \
            _d.d[4]=(d5);                                               \
            _d.d[5]=(d6);                                               \
            __trace_var(TRC_HVM_ ## evt, cycles,                        \
                        sizeof(u32)*count+1, (unsigned char *)&_d);     \
        }                                                               \
    } while(0)

#define HVMTRACE_6D(evt, d1, d2, d3, d4, d5, d6)    \
                      HVMTRACE_ND(evt, 0, 6, d1, d2, d3,  d4, d5, d6)
#define HVMTRACE_5D(evt, d1, d2, d3, d4, d5)        \
                      HVMTRACE_ND(evt, 0, 5, d1, d2, d3,  d4, d5, 0)
#define HVMTRACE_4D(evt, d1, d2, d3, d4)               \
                      HVMTRACE_ND(evt, 0, 4, d1, d2, d3,  d4, 0, 0)
#define HVMTRACE_3D(evt, d1, d2, d3)                   \
                      HVMTRACE_ND(evt, 0, 3, d1, d2, d3,  0, 0, 0)
#define HVMTRACE_2D(evt, d1, d2)                       \
                      HVMTRACE_ND(evt, 0, 2, d1, d2,  0,  0, 0, 0)
#define HVMTRACE_1D(evt, d1)                           \
                      HVMTRACE_ND(evt, 0, 1, d1,  0,  0,  0, 0, 0)
#define HVMTRACE_0D(evt)                               \
                      HVMTRACE_ND(evt, 0, 0, 0,  0,  0,  0, 0, 0)



#ifdef __x86_64__
#define HVMTRACE_LONG_1D(evt, d1)                  \
                   HVMTRACE_2D(evt ## 64, (d1) & 0xFFFFFFFF, (d1) >> 32)
#define HVMTRACE_LONG_2D(evt, d1, d2, ...)              \
                   HVMTRACE_3D(evt ## 64, d1, d2)
#define HVMTRACE_LONG_3D(evt, d1, d2, d3, ...)      \
                   HVMTRACE_4D(evt ## 64, d1, d2, d3)
#define HVMTRACE_LONG_4D(evt, d1, d2, d3, d4, ...)  \
                   HVMTRACE_5D(evt ## 64, d1, d2, d3, d4)
#else
#define HVMTRACE_LONG_1D HVMTRACE_1D
#define HVMTRACE_LONG_2D HVMTRACE_2D
#define HVMTRACE_LONG_3D HVMTRACE_3D
#define HVMTRACE_LONG_4D HVMTRACE_4D
#endif

#endif /* __ASM_X86_HVM_TRACE_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
