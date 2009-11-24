#ifndef XC_PTRACE_
#define XC_PTRACE_

#define X86_CR0_PE              0x00000001 /* Enable Protected Mode    (RW) */
#define X86_CR0_PG              0x80000000 /* Paging                   (RW) */
#define BSD_PAGE_MASK (PAGE_SIZE-1)
#define PSL_T  0x00000100 /* trace enable bit */

#ifdef __x86_64__
struct gdb_regs
{
  unsigned long r15;
  unsigned long r14;
  unsigned long r13;
  unsigned long r12;
  unsigned long rbp;
  unsigned long rbx;
  unsigned long r11;
  unsigned long r10;
  unsigned long r9;
  unsigned long r8;
  unsigned long rax;
  unsigned long rcx;
  unsigned long rdx;
  unsigned long rsi;
  unsigned long rdi;
  unsigned long orig_rax;
  unsigned long rip;
  unsigned long xcs;
  unsigned long rflags;
  unsigned long rsp;
  unsigned long xss;
  unsigned long fs_base;
  unsigned long gs_base;
  unsigned long xds;
  unsigned long xes;
  unsigned long xfs;
  unsigned long xgs;
};

#define SET_PT_REGS(pt, xc)                     \
{                                               \
    pt.r8 = xc.r8;                              \
    pt.r9 = xc.r9;                              \
    pt.r10 = xc.r10;                            \
    pt.r11 = xc.r11;                            \
    pt.r12 = xc.r12;                            \
    pt.r13 = xc.r13;                            \
    pt.r14 = xc.r14;                            \
    pt.r15 = xc.r15;                            \
    pt.rbx = xc.rbx;                            \
    pt.rcx = xc.rcx;                            \
    pt.rdx = xc.rdx;                            \
    pt.rsi = xc.rsi;                            \
    pt.rdi = xc.rdi;                            \
    pt.rbp = xc.rbp;                            \
    pt.rax = xc.rax;                            \
    pt.rip = xc.rip;                            \
    pt.xcs = xc.cs;                             \
    pt.rflags = xc.rflags;                      \
    pt.rsp = xc.rsp;                            \
    pt.xss = xc.ss;                             \
    pt.xes = xc.es;                             \
    pt.xds = xc.ds;                             \
    pt.xfs = xc.fs;                             \
    pt.xgs = xc.gs;                             \
}

#define SET_XC_REGS(pt, xc)                     \
{                                               \
    xc.r8 = pt->r8;                             \
    xc.r9 = pt->r9;                             \
    xc.r10 = pt->r10;                           \
    xc.r11 = pt->r11;                           \
    xc.r12 = pt->r12;                           \
    xc.r13 = pt->r13;                           \
    xc.r14 = pt->r14;                           \
    xc.r15 = pt->r15;                           \
    xc.rbx = pt->rbx;                           \
    xc.rcx = pt->rcx;                           \
    xc.rdx = pt->rdx;                           \
    xc.rsi = pt->rsi;                           \
    xc.rdi = pt->rdi;                           \
    xc.rbp = pt->rbp;                           \
    xc.rax = pt->rax;                           \
    xc.rip = pt->rip;                           \
    xc.cs = pt->xcs;                            \
    xc.rflags = pt->rflags & 0xffffffff;        \
    xc.rsp = pt->rsp;                           \
    xc.ss = pt->xss;                            \
    xc.es = pt->xes;                            \
    xc.ds = pt->xds;                            \
    xc.fs = pt->xfs;                            \
    xc.gs = pt->xgs;                            \
}

#elif __i386__

struct gdb_regs {
    long ebx; /* 0 */
    long ecx; /* 4 */
    long edx; /* 8 */
    long esi; /* 12 */
    long edi; /* 16 */
    long ebp; /* 20 */
    long eax; /* 24 */
    int  xds; /* 28 */
    int  xes; /* 32 */
    int  xfs; /* 36 */
    int  xgs; /* 40 */
    long orig_eax; /* 44 */
    long eip;    /* 48 */
    int  xcs;    /* 52 */
    long eflags; /* 56 */
    long esp;    /* 60 */
    int  xss;    /* 64 */
};

#define SET_PT_REGS(pt, xc)                     \
{                                               \
    pt.ebx = xc.ebx;                            \
    pt.ecx = xc.ecx;                            \
    pt.edx = xc.edx;                            \
    pt.esi = xc.esi;                            \
    pt.edi = xc.edi;                            \
    pt.ebp = xc.ebp;                            \
    pt.eax = xc.eax;                            \
    pt.eip = xc.eip;                            \
    pt.xcs = xc.cs;                             \
    pt.eflags = xc.eflags;                      \
    pt.esp = xc.esp;                            \
    pt.xss = xc.ss;                             \
    pt.xes = xc.es;                             \
    pt.xds = xc.ds;                             \
    pt.xfs = xc.fs;                             \
    pt.xgs = xc.gs;                             \
}

#define SET_XC_REGS(pt, xc)                     \
{                                               \
    xc.ebx = pt->ebx;                           \
    xc.ecx = pt->ecx;                           \
    xc.edx = pt->edx;                           \
    xc.esi = pt->esi;                           \
    xc.edi = pt->edi;                           \
    xc.ebp = pt->ebp;                           \
    xc.eax = pt->eax;                           \
    xc.eip = pt->eip;                           \
    xc.cs = pt->xcs;                            \
    xc.eflags = pt->eflags;                     \
    xc.esp = pt->esp;                           \
    xc.ss = pt->xss;                            \
    xc.es = pt->xes;                            \
    xc.ds = pt->xds;                            \
    xc.fs = pt->xfs;                            \
    xc.gs = pt->xgs;                            \
}
#endif

void *map_domain_va_core(unsigned long domfd, int cpu, void *guest_va);
int xc_waitdomain_core(int xc_handle, int domain, int *status, int options);
vcpu_guest_context_any_t *xc_ptrace_get_vcpu_ctxt(unsigned int nr_cpus);


#endif /* XC_PTRACE */
