#include <sys/ptrace.h>
#include <sys/wait.h>
#include <time.h>

#include "xc_private.h"
#include "xg_private.h"
#include "xc_ptrace.h"

#ifdef DEBUG
static char *ptrace_names[] = {
    "PTRACE_TRACEME",
    "PTRACE_PEEKTEXT",
    "PTRACE_PEEKDATA",
    "PTRACE_PEEKUSER",
    "PTRACE_POKETEXT",
    "PTRACE_POKEDATA",
    "PTRACE_POKEUSER",
    "PTRACE_CONT",
    "PTRACE_KILL",
    "PTRACE_SINGLESTEP",
    "PTRACE_INVALID",
    "PTRACE_INVALID",
    "PTRACE_GETREGS",
    "PTRACE_SETREGS",
    "PTRACE_GETFPREGS",
    "PTRACE_SETFPREGS",
    "PTRACE_ATTACH",
    "PTRACE_DETACH",
    "PTRACE_GETFPXREGS",
    "PTRACE_SETFPXREGS",
    "PTRACE_INVALID",
    "PTRACE_INVALID",
    "PTRACE_INVALID",
    "PTRACE_INVALID",
    "PTRACE_SYSCALL",
};
#endif

static int current_domid = -1;
static int current_isfile;
static int current_is_hvm;

static uint64_t                         online_cpumap;
static uint64_t                         regs_valid;
static unsigned int                     nr_vcpu_ids;
static vcpu_guest_context_any_t        *ctxt;

#define FOREACH_CPU(cpumap, i)  for ( cpumap = online_cpumap; (i = xc_ffs64(cpumap)); cpumap &= ~(1 << (index - 1)) )

static int
fetch_regs(int xc_handle, int cpu, int *online)
{
    xc_vcpuinfo_t info;
    int retval = 0;

    if (online)
        *online = 0;
    if ( !(regs_valid & (1 << cpu)) )
    {
        retval = xc_vcpu_getcontext(xc_handle, current_domid,
                cpu, &ctxt[cpu]);
        if ( retval )
            goto done;
        regs_valid |= (1 << cpu);

    }
    if ( online == NULL )
        goto done;

    retval = xc_vcpu_getinfo(xc_handle, current_domid, cpu, &info);
    *online = info.online;

 done:
    return retval;
}

static struct thr_ev_handlers {
    thr_ev_handler_t td_create;
    thr_ev_handler_t td_death;
} handlers;

void
xc_register_event_handler(thr_ev_handler_t h,
                          td_event_e e)
{
    switch (e) {
    case TD_CREATE:
        handlers.td_create = h;
        break;
    case TD_DEATH:
        handlers.td_death = h;
        break;
    default:
        abort(); /* XXX */
    }
}

static inline int
paging_enabled(vcpu_guest_context_any_t *v)
{
    unsigned long cr0 = v->c.ctrlreg[0];
    return (cr0 & X86_CR0_PE) && (cr0 & X86_CR0_PG);
}

vcpu_guest_context_any_t *xc_ptrace_get_vcpu_ctxt(unsigned int nr_cpus)
{
    if (nr_cpus > nr_vcpu_ids) {
        vcpu_guest_context_any_t *new;

        new = realloc(ctxt, nr_cpus * sizeof(*ctxt));
        if (!new)
            return NULL;
        ctxt = new;
        nr_vcpu_ids = nr_cpus;
    }

    return ctxt;
}

/*
 * Fetch registers for all online cpus and set the cpumap
 * to indicate which cpus are online
 *
 */

static int
get_online_cpumap(int xc_handle, struct xen_domctl_getdomaininfo *d,
                  uint64_t *cpumap)
{
    int i, online;

    if (!xc_ptrace_get_vcpu_ctxt(d->max_vcpu_id + 1))
        return -ENOMEM;

    *cpumap = 0;
    for (i = 0; i <= d->max_vcpu_id; i++) {
        fetch_regs(xc_handle, i, &online);
        if (online)
            *cpumap |= (1 << i);
    }
    
    return (*cpumap == 0) ? -1 : 0;
}

/*
 * Notify GDB of any vcpus that have come online or gone offline
 * update online_cpumap
 *
 */

static void
online_vcpus_changed(uint64_t cpumap)
{
    uint64_t changed_cpumap = cpumap ^ online_cpumap;
    int index;

    while ( (index = xc_ffs64(changed_cpumap)) ) {
        if ( cpumap & (1 << (index - 1)) )
        {
            if (handlers.td_create) handlers.td_create(index - 1);
        } else {
            IPRINTF("thread death: %d\n", index - 1);
            if (handlers.td_death) handlers.td_death(index - 1);
        }
        changed_cpumap &= ~(1 << (index - 1));
    }
    online_cpumap = cpumap;

}


static void *
map_domain_va(
    int xc_handle,
    int cpu,
    void *guest_va,
    int perm)
{
    unsigned long va = (unsigned long)guest_va;
    unsigned long mfn;
    void *map;

    /* cross page boundary */
    if ( (va & ~PAGE_MASK) + sizeof(long) > PAGE_SIZE )
        return NULL;

    mfn = xc_translate_foreign_address(xc_handle, current_domid, cpu, va);
    if ( mfn == 0 )
        return NULL;

    map = xc_map_foreign_range(xc_handle, current_domid, PAGE_SIZE, 
                               perm, mfn);
    if (map == NULL)
        return NULL;

    return map + (va & ~PAGE_MASK);
}

static void
unmap_domain_va(void *guest_va)
{
    munmap((void *)((unsigned long)guest_va & PAGE_MASK), PAGE_SIZE);
}

int control_c_pressed_flag = 0;

static int
__xc_waitdomain(
    int xc_handle,
    int domain,
    int *status,
    int options)
{
    DECLARE_DOMCTL;
    int retval;
    struct timespec ts;
    uint64_t cpumap;

    ts.tv_sec = 0;
    ts.tv_nsec = 10*1000*1000;

    domctl.cmd = XEN_DOMCTL_getdomaininfo;
    domctl.domain = domain;

 retry:
    retval = do_domctl(xc_handle, &domctl);
    if ( retval || (domctl.domain != domain) )
    {
        IPRINTF("getdomaininfo failed\n");
        goto done;
    }
    *status = domctl.u.getdomaininfo.flags;

    if ( options & WNOHANG )
        goto done;

    if (control_c_pressed_flag) {
        xc_domain_pause(xc_handle, domain);
        control_c_pressed_flag = 0;
        goto done;
    }

    if ( !(domctl.u.getdomaininfo.flags & XEN_DOMINF_paused) )
    {
        nanosleep(&ts,NULL);
        goto retry;
    }
 done:
    if (get_online_cpumap(xc_handle, &domctl.u.getdomaininfo, &cpumap))
        IPRINTF("get_online_cpumap failed\n");
    if (online_cpumap != cpumap)
        online_vcpus_changed(cpumap);
    return retval;

}


long
xc_ptrace(
    int xc_handle,
    enum __ptrace_request request,
    uint32_t domid_tid,
    long eaddr,
    long edata)
{
    DECLARE_DOMCTL;
    struct gdb_regs pt;
    long            retval = 0;
    unsigned long  *guest_va;
    uint64_t        cpumap;
    int             cpu, index;
    void           *addr = (char *)eaddr;
    void           *data = (char *)edata;

    cpu = (request != PTRACE_ATTACH) ? domid_tid : 0;

    switch ( request )
    {
    case PTRACE_PEEKTEXT:
    case PTRACE_PEEKDATA:
        if (current_isfile)
            guest_va = (unsigned long *)map_domain_va_core(
                current_domid, cpu, addr);
        else
            guest_va = (unsigned long *)map_domain_va(
                xc_handle, cpu, addr, PROT_READ);
        if ( guest_va == NULL )
            goto out_error;
        retval = *guest_va;
        if (!current_isfile)
            unmap_domain_va(guest_va);
        break;

    case PTRACE_POKETEXT:
    case PTRACE_POKEDATA:
        /* XXX assume that all CPUs have the same address space */
        if (current_isfile)
            guest_va = (unsigned long *)map_domain_va_core(
                current_domid, cpu, addr);
        else
            guest_va = (unsigned long *)map_domain_va(
                xc_handle, cpu, addr, PROT_READ|PROT_WRITE);
        if ( guest_va == NULL )
            goto out_error;
        *guest_va = edata;
        if (!current_isfile)
            unmap_domain_va(guest_va);
        break;

    case PTRACE_GETREGS:
        if (!current_isfile && fetch_regs(xc_handle, cpu, NULL))
            goto out_error;
        SET_PT_REGS(pt, ctxt[cpu].c.user_regs);
        memcpy(data, &pt, sizeof(struct gdb_regs));
        break;

    case PTRACE_GETFPREGS:
        if (!current_isfile && fetch_regs(xc_handle, cpu, NULL)) 
                goto out_error;
        memcpy(data, &ctxt[cpu].c.fpu_ctxt, sizeof (elf_fpregset_t));
        break;

    case PTRACE_GETFPXREGS:
        if (!current_isfile && fetch_regs(xc_handle, cpu, NULL))
                goto out_error;
        memcpy(data, &ctxt[cpu].c.fpu_ctxt, sizeof(ctxt[cpu].c.fpu_ctxt));
        break;

    case PTRACE_SETREGS:
        if (current_isfile)
                goto out_unsupported; /* XXX not yet supported */
        SET_XC_REGS(((struct gdb_regs *)data), ctxt[cpu].c.user_regs);
        if ((retval = xc_vcpu_setcontext(xc_handle, current_domid, cpu,
                                &ctxt[cpu])))
            goto out_error_domctl;
        break;

    case PTRACE_SINGLESTEP:
        if (current_isfile)
              goto out_unsupported; /* XXX not yet supported */
        /*  XXX we can still have problems if the user switches threads
         *  during single-stepping - but that just seems retarded
         */
        /* Try to enalbe Monitor Trap Flag for HVM, and fall back to TF
         * if no MTF support
         */
        if ( !current_is_hvm ||
             xc_domain_debug_control(xc_handle,
                                     current_domid,
                                     XEN_DOMCTL_DEBUG_OP_SINGLE_STEP_ON,
                                     cpu) )
        {
            ctxt[cpu].c.user_regs.eflags |= PSL_T;
            if ((retval = xc_vcpu_setcontext(xc_handle, current_domid, cpu,
                                    &ctxt[cpu])))
                goto out_error_domctl;
        }
        /* FALLTHROUGH */

    case PTRACE_CONT:
    case PTRACE_DETACH:
        if (current_isfile)
            goto out_unsupported; /* XXX not yet supported */
        if ( request != PTRACE_SINGLESTEP )
        {
            FOREACH_CPU(cpumap, index) {
                cpu = index - 1;
                if ( !current_is_hvm ||
                      xc_domain_debug_control(xc_handle,
                                              current_domid,
                                              XEN_DOMCTL_DEBUG_OP_SINGLE_STEP_OFF,
                                              cpu) )
                {
                    if (fetch_regs(xc_handle, cpu, NULL))
                        goto out_error;
                    /* Clear trace flag */
                    if ( ctxt[cpu].c.user_regs.eflags & PSL_T )
                    {
                        ctxt[cpu].c.user_regs.eflags &= ~PSL_T;
                        if ((retval = xc_vcpu_setcontext(xc_handle, current_domid,
                                        cpu, &ctxt[cpu])))
                            goto out_error_domctl;
                    }
                }
            }
        }
        if ( request == PTRACE_DETACH )
        {
            if ((retval = xc_domain_setdebugging(xc_handle, current_domid, 0)))
                goto out_error_domctl;
        }
        regs_valid = 0;
        if ((retval = xc_domain_unpause(xc_handle, current_domid > 0 ?
                                current_domid : -current_domid)))
            goto out_error_domctl;
        break;

    case PTRACE_ATTACH:
        current_domid = domid_tid;
        current_isfile = (int)edata;
        if (current_isfile)
            break;
        domctl.cmd = XEN_DOMCTL_getdomaininfo;
        domctl.domain = current_domid;
        retval = do_domctl(xc_handle, &domctl);
        if ( retval || (domctl.domain != current_domid) )
            goto out_error_domctl;
        if ( domctl.u.getdomaininfo.flags & XEN_DOMINF_paused )
            IPRINTF("domain currently paused\n");
        else if ((retval = xc_domain_pause(xc_handle, current_domid)))
            goto out_error_domctl;
        current_is_hvm = !!(domctl.u.getdomaininfo.flags&XEN_DOMINF_hvm_guest);
        if ((retval = xc_domain_setdebugging(xc_handle, current_domid, 1)))
            goto out_error_domctl;

        if (get_online_cpumap(xc_handle, &domctl.u.getdomaininfo, &cpumap))
            IPRINTF("get_online_cpumap failed\n");
        if (online_cpumap != cpumap)
            online_vcpus_changed(cpumap);
        break;

    case PTRACE_TRACEME:
        IPRINTF("PTRACE_TRACEME is an invalid request under Xen\n");
        goto out_error;

    default:
        goto out_unsupported; /* XXX not yet supported */
    }

    return retval;

 out_error_domctl:
    perror("domctl failed");
 out_error:
    errno = EINVAL;
    return retval;

 out_unsupported:
#ifdef DEBUG
    IPRINTF("unsupported xc_ptrace request %s\n", ptrace_names[request]);
#endif
    errno = ENOSYS;
    return -1;

}

int
xc_waitdomain(
    int xc_handle,
    int domain,
    int *status,
    int options)
{
    if (current_isfile)
        return xc_waitdomain_core(xc_handle, domain, status, options);
    return __xc_waitdomain(xc_handle, domain, status, options);
}

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
