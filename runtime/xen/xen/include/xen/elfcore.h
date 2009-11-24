/******************************************************************************
 * elfcore.h
 *
 * Based heavily on include/linux/elfcore.h from Linux 2.6.16
 * Naming scheeme based on include/xen/elf.h (not include/linux/elfcore.h)
 *
 */

#ifndef __ELFCOREC_H__
#define __ELFCOREC_H__

#include <xen/types.h>
#include <xen/elf.h>
#include <asm/elf.h>
#include <public/xen.h>

#define NT_PRSTATUS     1

typedef struct
{
    int signo;                       /* signal number */
    int code;                        /* extra code */
    int errno;                       /* errno */
} ELF_Signifo;

/* These seem to be the same length on all architectures on Linux */
typedef int ELF_Pid;
typedef struct {
	long tv_sec;
	long tv_usec;
} ELF_Timeval;

/*
 * Definitions to generate Intel SVR4-like core files.
 * These mostly have the same names as the SVR4 types with "elf_"
 * tacked on the front to prevent clashes with linux definitions,
 * and the typedef forms have been avoided.  This is mostly like
 * the SVR4 structure, but more Linuxy, with things that Linux does
 * not support and which gdb doesn't really use excluded.
 */
typedef struct
{
    ELF_Signifo pr_info;         /* Info associated with signal */
    short pr_cursig;             /* Current signal */
    unsigned long pr_sigpend;    /* Set of pending signals */
    unsigned long pr_sighold;    /* Set of held signals */
    ELF_Pid pr_pid;
    ELF_Pid pr_ppid;
    ELF_Pid pr_pgrp;
    ELF_Pid pr_sid;
    ELF_Timeval pr_utime;        /* User time */
    ELF_Timeval pr_stime;        /* System time */
    ELF_Timeval pr_cutime;       /* Cumulative user time */
    ELF_Timeval pr_cstime;       /* Cumulative system time */
    ELF_Gregset pr_reg;          /* GP registers - from asm header file */
    int pr_fpvalid;              /* True if math co-processor being used.  */
} ELF_Prstatus;

typedef struct {
    unsigned long xen_major_version;
    unsigned long xen_minor_version;
    unsigned long xen_extra_version;
    unsigned long xen_changeset;
    unsigned long xen_compiler;
    unsigned long xen_compile_date;
    unsigned long xen_compile_time;
    unsigned long tainted;
#if defined(__i386__) || defined(__x86_64__)
    unsigned long xen_phys_start;
    unsigned long dom0_pfn_to_mfn_frame_list_list;
#endif
#if defined(__ia64__)
    unsigned long dom0_mm_pgd_mfn;
#endif
} crash_xen_info_t;

#endif /* __ELFCOREC_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
