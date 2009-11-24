#ifndef __ASM_TRACE_H__
#define __ASM_TRACE_H__

#include <asm/page.h>

void __trace_pv_trap(int trapnr, unsigned long eip,
                     int use_error_code, unsigned error_code);
static inline void trace_pv_trap(int trapnr, unsigned long eip,
                                 int use_error_code, unsigned error_code)
{
    if ( unlikely(tb_init_done) )
        __trace_pv_trap(trapnr, eip, use_error_code, error_code);
}

void __trace_pv_page_fault(unsigned long addr, unsigned error_code);
static inline void trace_pv_page_fault(unsigned long addr,
                                       unsigned error_code)
{
    if ( unlikely(tb_init_done) )
        __trace_pv_page_fault(addr, error_code);
}

void __trace_trap_one_addr(unsigned event, unsigned long va);
static inline void trace_trap_one_addr(unsigned event, unsigned long va)
{
    if ( unlikely(tb_init_done) )
        __trace_trap_one_addr(event, va);
}

void __trace_trap_two_addr(unsigned event, unsigned long va1,
                           unsigned long va2);
static inline void trace_trap_two_addr(unsigned event, unsigned long va1,
                                       unsigned long va2)
{
    if ( unlikely(tb_init_done) )
        __trace_trap_two_addr(event, va1, va2);
}

void __trace_ptwr_emulation(unsigned long addr, l1_pgentry_t npte);
static inline void trace_ptwr_emulation(unsigned long addr, l1_pgentry_t npte)
{
    if ( unlikely(tb_init_done) )
        __trace_ptwr_emulation(addr, npte);
}

#endif /* __ASM_TRACE_H__ */
