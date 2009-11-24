/******************************************************************************
 * xenctrl.h
 *
 * A library for low-level access to the Xen control interfaces.
 *
 * Copyright (c) 2003-2004, K A Fraser.
 *
 * xc_gnttab functions:
 * Copyright (c) 2007-2008, D G Murray <Derek.Murray@cl.cam.ac.uk>
 */

#ifndef XENCTRL_H
#define XENCTRL_H

/* Tell the Xen public headers we are a user-space tools build. */
#ifndef __XEN_TOOLS__
#define __XEN_TOOLS__ 1
#endif

#include <stddef.h>
#include <stdint.h>
#include <xen/xen.h>
#include <xen/domctl.h>
#include <xen/physdev.h>
#include <xen/sysctl.h>
#include <xen/version.h>
#include <xen/event_channel.h>
#include <xen/sched.h>
#include <xen/memory.h>
#include <xen/grant_table.h>
#include <xen/hvm/params.h>
#include <xen/xsm/acm.h>
#include <xen/xsm/acm_ops.h>
#include <xen/xsm/flask_op.h>

#if defined(__i386__) || defined(__x86_64__)
#include <xen/foreign/x86_32.h>
#include <xen/foreign/x86_64.h>
#endif

#ifdef __ia64__
#define XC_PAGE_SHIFT           14
#else
#define XC_PAGE_SHIFT           12
#endif
#define XC_PAGE_SIZE            (1UL << XC_PAGE_SHIFT)
#define XC_PAGE_MASK            (~(XC_PAGE_SIZE-1))

/*
 *  DEFINITIONS FOR CPU BARRIERS
 */

#if defined(__i386__)
#define xen_mb()  asm volatile ( "lock; addl $0,0(%%esp)" : : : "memory" )
#define xen_rmb() asm volatile ( "lock; addl $0,0(%%esp)" : : : "memory" )
#define xen_wmb() asm volatile ( "" : : : "memory")
#elif defined(__x86_64__)
#define xen_mb()  asm volatile ( "mfence" : : : "memory")
#define xen_rmb() asm volatile ( "lfence" : : : "memory")
#define xen_wmb() asm volatile ( "" : : : "memory")
#elif defined(__ia64__)
#define xen_mb()   asm volatile ("mf" ::: "memory")
#define xen_rmb()  asm volatile ("mf" ::: "memory")
#define xen_wmb()  asm volatile ("mf" ::: "memory")
#else
#error "Define barriers"
#endif

/*
 *  INITIALIZATION FUNCTIONS
 */

/**
 * This function opens a handle to the hypervisor interface.  This function can
 * be called multiple times within a single process.  Multiple processes can
 * have an open hypervisor interface at the same time.
 *
 * Each call to this function should have a corresponding call to
 * xc_interface_close().
 *
 * This function can fail if the caller does not have superuser permission or
 * if a Xen-enabled kernel is not currently running.
 *
 * @return a handle to the hypervisor interface or -1 on failure
 */
int xc_interface_open(void);

/**
 * This function closes an open hypervisor interface.
 *
 * This function can fail if the handle does not represent an open interface or
 * if there were problems closing the interface.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @return 0 on success, -1 otherwise.
 */
int xc_interface_close(int xc_handle);

/*
 * KERNEL INTERFACES
 */

/*
 * Resolve a kernel device name (e.g., "evtchn", "blktap0") into a kernel
 * device number. Returns -1 on error (and sets errno).
 */
int xc_find_device_number(const char *name);

/*
 * DOMAIN DEBUGGING FUNCTIONS
 */

typedef struct xc_core_header {
    unsigned int xch_magic;
    unsigned int xch_nr_vcpus;
    unsigned int xch_nr_pages;
    unsigned int xch_ctxt_offset;
    unsigned int xch_index_offset;
    unsigned int xch_pages_offset;
} xc_core_header_t;

#define XC_CORE_MAGIC     0xF00FEBED
#define XC_CORE_MAGIC_HVM 0xF00FEBEE

#ifdef __linux__

#include <sys/ptrace.h>
#include <thread_db.h>

typedef void (*thr_ev_handler_t)(long);

void xc_register_event_handler(
    thr_ev_handler_t h,
    td_event_e e);

long xc_ptrace(
    int xc_handle,
    enum __ptrace_request request,
    uint32_t  domid,
    long addr,
    long data);

int xc_waitdomain(
    int xc_handle,
    int domain,
    int *status,
    int options);

#endif /* __linux__ */

/*
 * DOMAIN MANAGEMENT FUNCTIONS
 */

typedef struct xc_dominfo {
    uint32_t      domid;
    uint32_t      ssidref;
    unsigned int  dying:1, crashed:1, shutdown:1,
                  paused:1, blocked:1, running:1,
                  hvm:1, debugged:1;
    unsigned int  shutdown_reason; /* only meaningful if shutdown==1 */
    unsigned long nr_pages; /* current number, not maximum */
    unsigned long shared_info_frame;
    uint64_t      cpu_time;
    unsigned long max_memkb;
    unsigned int  nr_online_vcpus;
    unsigned int  max_vcpu_id;
    xen_domain_handle_t handle;
} xc_dominfo_t;

typedef xen_domctl_getdomaininfo_t xc_domaininfo_t;

typedef union 
{
#if defined(__i386__) || defined(__x86_64__)
    vcpu_guest_context_x86_64_t x64;
    vcpu_guest_context_x86_32_t x32;   
#endif
    vcpu_guest_context_t c;
} vcpu_guest_context_any_t;

typedef union
{
#if defined(__i386__) || defined(__x86_64__)
    shared_info_x86_64_t x64;
    shared_info_x86_32_t x32;
#endif
    shared_info_t s;
} shared_info_any_t;

typedef union
{
#if defined(__i386__) || defined(__x86_64__)
    start_info_x86_64_t x64;
    start_info_x86_32_t x32;
#endif
    start_info_t s;
} start_info_any_t;


int xc_domain_create(int xc_handle,
                     uint32_t ssidref,
                     xen_domain_handle_t handle,
                     uint32_t flags,
                     uint32_t *pdomid);


/* Functions to produce a dump of a given domain
 *  xc_domain_dumpcore - produces a dump to a specified file
 *  xc_domain_dumpcore_via_callback - produces a dump, using a specified
 *                                    callback function
 */
int xc_domain_dumpcore(int xc_handle,
                       uint32_t domid,
                       const char *corename);

/* Define the callback function type for xc_domain_dumpcore_via_callback.
 *
 * This function is called by the coredump code for every "write",
 * and passes an opaque object for the use of the function and
 * created by the caller of xc_domain_dumpcore_via_callback.
 */
typedef int (dumpcore_rtn_t)(void *arg, char *buffer, unsigned int length);

int xc_domain_dumpcore_via_callback(int xc_handle,
                                    uint32_t domid,
                                    void *arg,
                                    dumpcore_rtn_t dump_rtn);

/*
 * This function sets the maximum number of vcpus that a domain may create.
 *
 * @parm xc_handle a handle to an open hypervisor interface.
 * @parm domid the domain id in which vcpus are to be created.
 * @parm max the maximum number of vcpus that the domain may create.
 * @return 0 on success, -1 on failure.
 */
int xc_domain_max_vcpus(int xc_handle,
                        uint32_t domid,
                        unsigned int max);

/**
 * This function pauses a domain. A paused domain still exists in memory
 * however it does not receive any timeslices from the hypervisor.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to pause
 * @return 0 on success, -1 on failure.
 */
int xc_domain_pause(int xc_handle,
                    uint32_t domid);
/**
 * This function unpauses a domain.  The domain should have been previously
 * paused.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to unpause
 * return 0 on success, -1 on failure
 */
int xc_domain_unpause(int xc_handle,
                      uint32_t domid);

/**
 * This function will destroy a domain.  Destroying a domain removes the domain
 * completely from memory.  This function should be called after sending the
 * domain a SHUTDOWN control message to free up the domain resources.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to destroy
 * @return 0 on success, -1 on failure
 */
int xc_domain_destroy(int xc_handle,
                      uint32_t domid);


/**
 * This function resumes a suspended domain. The domain should have
 * been previously suspended.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to resume
 * @parm fast use cooperative resume (guest must support this)
 * return 0 on success, -1 on failure
 */
int xc_domain_resume(int xc_handle,
		     uint32_t domid,
		     int fast);

/**
 * This function will shutdown a domain. This is intended for use in
 * fully-virtualized domains where this operation is analogous to the
 * sched_op operations in a paravirtualized domain. The caller is
 * expected to give the reason for the shutdown.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to destroy
 * @parm reason is the reason (SHUTDOWN_xxx) for the shutdown
 * @return 0 on success, -1 on failure
 */
int xc_domain_shutdown(int xc_handle,
                       uint32_t domid,
                       int reason);

int xc_vcpu_setaffinity(int xc_handle,
                        uint32_t domid,
                        int vcpu,
                        uint64_t cpumap);
int xc_vcpu_getaffinity(int xc_handle,
                        uint32_t domid,
                        int vcpu,
                        uint64_t *cpumap);

/**
 * This function will return information about one or more domains. It is
 * designed to iterate over the list of domains. If a single domain is
 * requested, this function will return the next domain in the list - if
 * one exists. It is, therefore, important in this case to make sure the
 * domain requested was the one returned.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm first_domid the first domain to enumerate information from.  Domains
 *                   are currently enumerate in order of creation.
 * @parm max_doms the number of elements in info
 * @parm info an array of max_doms size that will contain the information for
 *            the enumerated domains.
 * @return the number of domains enumerated or -1 on error
 */
int xc_domain_getinfo(int xc_handle,
                      uint32_t first_domid,
                      unsigned int max_doms,
                      xc_dominfo_t *info);


/**
 * This function will set the execution context for the specified vcpu.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain to set the vcpu context for
 * @parm vcpu the vcpu number for the context
 * @parm ctxt pointer to the the cpu context with the values to set
 * @return the number of domains enumerated or -1 on error
 */
int xc_vcpu_setcontext(int xc_handle,
                       uint32_t domid,
                       uint32_t vcpu,
                       vcpu_guest_context_any_t *ctxt);
/**
 * This function will return information about one or more domains, using a
 * single hypercall.  The domain information will be stored into the supplied
 * array of xc_domaininfo_t structures.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm first_domain the first domain to enumerate information from.
 *                    Domains are currently enumerate in order of creation.
 * @parm max_domains the number of elements in info
 * @parm info an array of max_doms size that will contain the information for
 *            the enumerated domains.
 * @return the number of domains enumerated or -1 on error
 */
int xc_domain_getinfolist(int xc_handle,
                          uint32_t first_domain,
                          unsigned int max_domains,
                          xc_domaininfo_t *info);

/**
 * This function returns information about the context of a hvm domain
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain to get information from
 * @parm ctxt_buf a pointer to a structure to store the execution context of
 *            the hvm domain
 * @parm size the size of ctxt_buf in bytes
 * @return 0 on success, -1 on failure
 */
int xc_domain_hvm_getcontext(int xc_handle,
                             uint32_t domid,
                             uint8_t *ctxt_buf,
                             uint32_t size);


/**
 * This function returns one element of the context of a hvm domain
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain to get information from
 * @parm typecode which type of elemnt required 
 * @parm instance which instance of the type
 * @parm ctxt_buf a pointer to a structure to store the execution context of
 *            the hvm domain
 * @parm size the size of ctxt_buf (must be >= HVM_SAVE_LENGTH(typecode))
 * @return 0 on success, -1 on failure
 */
int xc_domain_hvm_getcontext_partial(int xc_handle,
                                     uint32_t domid,
                                     uint16_t typecode,
                                     uint16_t instance,
                                     void *ctxt_buf,
                                     uint32_t size);

/**
 * This function will set the context for hvm domain
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain to set the hvm domain context for
 * @parm hvm_ctxt pointer to the the hvm context with the values to set
 * @parm size the size of hvm_ctxt in bytes
 * @return 0 on success, -1 on failure
 */
int xc_domain_hvm_setcontext(int xc_handle,
                             uint32_t domid,
                             uint8_t *hvm_ctxt,
                             uint32_t size);

/**
 * This function returns information about the execution context of a
 * particular vcpu of a domain.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain to get information from
 * @parm vcpu the vcpu number
 * @parm ctxt a pointer to a structure to store the execution context of the
 *            domain
 * @return 0 on success, -1 on failure
 */
int xc_vcpu_getcontext(int xc_handle,
                       uint32_t domid,
                       uint32_t vcpu,
                       vcpu_guest_context_any_t *ctxt);

typedef xen_domctl_getvcpuinfo_t xc_vcpuinfo_t;
int xc_vcpu_getinfo(int xc_handle,
                    uint32_t domid,
                    uint32_t vcpu,
                    xc_vcpuinfo_t *info);

long long xc_domain_get_cpu_usage(int xc_handle,
                                  domid_t domid,
                                  int vcpu);

int xc_domain_sethandle(int xc_handle, uint32_t domid,
                        xen_domain_handle_t handle);

typedef xen_domctl_shadow_op_stats_t xc_shadow_op_stats_t;
int xc_shadow_control(int xc_handle,
                      uint32_t domid,
                      unsigned int sop,
                      unsigned long *dirty_bitmap,
                      unsigned long pages,
                      unsigned long *mb,
                      uint32_t mode,
                      xc_shadow_op_stats_t *stats);

int xc_sedf_domain_set(int xc_handle,
                       uint32_t domid,
                       uint64_t period, uint64_t slice,
                       uint64_t latency, uint16_t extratime,
                       uint16_t weight);

int xc_sedf_domain_get(int xc_handle,
                       uint32_t domid,
                       uint64_t* period, uint64_t *slice,
                       uint64_t *latency, uint16_t *extratime,
                       uint16_t *weight);

int xc_sched_credit_domain_set(int xc_handle,
                               uint32_t domid,
                               struct xen_domctl_sched_credit *sdom);

int xc_sched_credit_domain_get(int xc_handle,
                               uint32_t domid,
                               struct xen_domctl_sched_credit *sdom);

/**
 * This function sends a trigger to a domain.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to send trigger
 * @parm trigger the trigger type
 * @parm vcpu the vcpu number to send trigger 
 * return 0 on success, -1 on failure
 */
int xc_domain_send_trigger(int xc_handle,
                           uint32_t domid,
                           uint32_t trigger,
                           uint32_t vcpu);

/**
 * This function enables or disable debugging of a domain.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain id to send trigger
 * @parm enable true to enable debugging
 * return 0 on success, -1 on failure
 */
int xc_domain_setdebugging(int xc_handle,
                           uint32_t domid,
                           unsigned int enable);

/*
 * EVENT CHANNEL FUNCTIONS
 */

/* A port identifier is guaranteed to fit in 31 bits. */
typedef int evtchn_port_or_error_t;

/**
 * This function allocates an unbound port.  Ports are named endpoints used for
 * interdomain communication.  This function is most useful in opening a
 * well-known port within a domain to receive events on.
 * 
 * NOTE: If you are allocating a *local* unbound port, you probably want to
 * use xc_evtchn_bind_unbound_port(). This function is intended for allocating
 * ports *only* during domain creation.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm dom the ID of the local domain (the 'allocatee')
 * @parm remote_dom the ID of the domain who will later bind
 * @return allocated port (in @dom) on success, -1 on failure
 */
evtchn_port_or_error_t
xc_evtchn_alloc_unbound(int xc_handle,
                        uint32_t dom,
                        uint32_t remote_dom);

int xc_evtchn_reset(int xc_handle,
                    uint32_t dom);

typedef struct evtchn_status xc_evtchn_status_t;
int xc_evtchn_status(int xc_handle, xc_evtchn_status_t *status);

/*
 * Return a handle to the event channel driver, or -1 on failure, in which case
 * errno will be set appropriately.
 */
int xc_evtchn_open(void);

/*
 * Close a handle previously allocated with xc_evtchn_open().
 */
int xc_evtchn_close(int xce_handle);

/*
 * Return an fd that can be select()ed on for further calls to
 * xc_evtchn_pending().
 */
int xc_evtchn_fd(int xce_handle);

/*
 * Notify the given event channel. Returns -1 on failure, in which case
 * errno will be set appropriately.
 */
int xc_evtchn_notify(int xce_handle, evtchn_port_t port);

/*
 * Returns a new event port awaiting interdomain connection from the given
 * domain ID, or -1 on failure, in which case errno will be set appropriately.
 */
evtchn_port_or_error_t
xc_evtchn_bind_unbound_port(int xce_handle, int domid);

/*
 * Returns a new event port bound to the remote port for the given domain ID,
 * or -1 on failure, in which case errno will be set appropriately.
 */
evtchn_port_or_error_t
xc_evtchn_bind_interdomain(int xce_handle, int domid,
                           evtchn_port_t remote_port);

/*
 * Bind an event channel to the given VIRQ. Returns the event channel bound to
 * the VIRQ, or -1 on failure, in which case errno will be set appropriately.
 */
evtchn_port_or_error_t
xc_evtchn_bind_virq(int xce_handle, unsigned int virq);

/*
 * Unbind the given event channel. Returns -1 on failure, in which case errno
 * will be set appropriately.
 */
int xc_evtchn_unbind(int xce_handle, evtchn_port_t port);

/*
 * Return the next event channel to become pending, or -1 on failure, in which
 * case errno will be set appropriately.  
 */
evtchn_port_or_error_t
xc_evtchn_pending(int xce_handle);

/*
 * Unmask the given event channel. Returns -1 on failure, in which case errno
 * will be set appropriately.
 */
int xc_evtchn_unmask(int xce_handle, evtchn_port_t port);

int xc_physdev_pci_access_modify(int xc_handle,
                                 uint32_t domid,
                                 int bus,
                                 int dev,
                                 int func,
                                 int enable);

int xc_readconsolering(int xc_handle,
                       char **pbuffer,
                       unsigned int *pnr_chars,
                       int clear, int incremental, uint32_t *pindex);

int xc_send_debug_keys(int xc_handle, char *keys);

typedef xen_sysctl_physinfo_t xc_physinfo_t;
typedef uint32_t xc_cpu_to_node_t;
int xc_physinfo(int xc_handle,
                xc_physinfo_t *info);

int xc_sched_id(int xc_handle,
                int *sched_id);

typedef xen_sysctl_cpuinfo_t xc_cpuinfo_t;
int xc_getcpuinfo(int xc_handle, int max_cpus,
                  xc_cpuinfo_t *info, int *nr_cpus); 

int xc_domain_setmaxmem(int xc_handle,
                        uint32_t domid,
                        unsigned int max_memkb);

int xc_domain_set_memmap_limit(int xc_handle,
                               uint32_t domid,
                               unsigned long map_limitkb);

int xc_domain_set_time_offset(int xc_handle,
                              uint32_t domid,
                              int32_t time_offset_seconds);

int xc_domain_set_tsc_native(int xc_handle, uint32_t domid, int is_native);

int xc_domain_disable_migrate(int xc_handle, uint32_t domid);

int xc_domain_memory_increase_reservation(int xc_handle,
                                          uint32_t domid,
                                          unsigned long nr_extents,
                                          unsigned int extent_order,
                                          unsigned int mem_flags,
                                          xen_pfn_t *extent_start);

int xc_domain_memory_decrease_reservation(int xc_handle,
                                          uint32_t domid,
                                          unsigned long nr_extents,
                                          unsigned int extent_order,
                                          xen_pfn_t *extent_start);

int xc_domain_memory_populate_physmap(int xc_handle,
                                      uint32_t domid,
                                      unsigned long nr_extents,
                                      unsigned int extent_order,
                                      unsigned int mem_flags,
                                      xen_pfn_t *extent_start);

int xc_domain_memory_set_pod_target(int xc_handle,
                                    uint32_t domid,
                                    uint64_t target_pages,
                                    uint64_t *tot_pages,
                                    uint64_t *pod_cache_pages,
                                    uint64_t *pod_entries);

int xc_domain_memory_get_pod_target(int xc_handle,
                                    uint32_t domid,
                                    uint64_t *tot_pages,
                                    uint64_t *pod_cache_pages,
                                    uint64_t *pod_entries);

int xc_domain_ioport_permission(int xc_handle,
                                uint32_t domid,
                                uint32_t first_port,
                                uint32_t nr_ports,
                                uint32_t allow_access);

int xc_domain_irq_permission(int xc_handle,
                             uint32_t domid,
                             uint8_t pirq,
                             uint8_t allow_access);

int xc_domain_iomem_permission(int xc_handle,
                               uint32_t domid,
                               unsigned long first_mfn,
                               unsigned long nr_mfns,
                               uint8_t allow_access);

int xc_domain_pin_memory_cacheattr(int xc_handle,
                                   uint32_t domid,
                                   uint64_t start,
                                   uint64_t end,
                                   uint32_t type);

unsigned long xc_make_page_below_4G(int xc_handle, uint32_t domid,
                                    unsigned long mfn);

typedef xen_sysctl_perfc_desc_t xc_perfc_desc_t;
typedef xen_sysctl_perfc_val_t xc_perfc_val_t;
/* IMPORTANT: The caller is responsible for mlock()'ing the @desc and @val
   arrays. */
int xc_perfc_control(int xc_handle,
                     uint32_t op,
                     xc_perfc_desc_t *desc,
                     xc_perfc_val_t *val,
                     int *nbr_desc,
                     int *nbr_val);

typedef xen_sysctl_lockprof_data_t xc_lockprof_data_t;
/* IMPORTANT: The caller is responsible for mlock()'ing the @data array. */
int xc_lockprof_control(int xc_handle,
                        uint32_t opcode,
                        uint32_t *n_elems,
                        uint64_t *time,
                        xc_lockprof_data_t *data);

/**
 * Memory maps a range within one domain to a local address range.  Mappings
 * should be unmapped with munmap and should follow the same rules as mmap
 * regarding page alignment.  Returns NULL on failure.
 *
 * In Linux, the ring queue for the control channel is accessible by mapping
 * the shared_info_frame (from xc_domain_getinfo()) + 2048.  The structure
 * stored there is of type control_if_t.
 *
 * @parm xc_handle a handle on an open hypervisor interface
 * @parm dom the domain to map memory from
 * @parm size the amount of memory to map (in multiples of page size)
 * @parm prot same flag as in mmap().
 * @parm mfn the frame address to map.
 */
void *xc_map_foreign_range(int xc_handle, uint32_t dom,
                            int size, int prot,
                            unsigned long mfn );

void *xc_map_foreign_pages(int xc_handle, uint32_t dom, int prot,
                           const xen_pfn_t *arr, int num );

/**
 * Like xc_map_foreign_pages(), except it can succeeed partially.
 * When a page cannot be mapped, its PFN in @arr is or'ed with
 * 0xF0000000 to indicate the error.
 */
void *xc_map_foreign_batch(int xc_handle, uint32_t dom, int prot,
                           xen_pfn_t *arr, int num );

/**
 * Translates a virtual address in the context of a given domain and
 * vcpu returning the GFN containing the address (that is, an MFN for 
 * PV guests, a PFN for HVM guests).  Returns 0 for failure.
 *
 * @parm xc_handle a handle on an open hypervisor interface
 * @parm dom the domain to perform the translation in
 * @parm vcpu the vcpu to perform the translation on
 * @parm virt the virtual address to translate
 */
unsigned long xc_translate_foreign_address(int xc_handle, uint32_t dom,
                                           int vcpu, unsigned long long virt);


/**
 * DEPRECATED.  Avoid using this, as it does not correctly account for PFNs
 * without a backing MFN.
 */
int xc_get_pfn_list(int xc_handle, uint32_t domid, uint64_t *pfn_buf,
                    unsigned long max_pfns);

unsigned long xc_ia64_fpsr_default(void);

int xc_copy_to_domain_page(int xc_handle, uint32_t domid,
                           unsigned long dst_pfn, const char *src_page);

int xc_clear_domain_page(int xc_handle, uint32_t domid,
                         unsigned long dst_pfn);

long xc_get_max_pages(int xc_handle, uint32_t domid);

int xc_mmuext_op(int xc_handle, struct mmuext_op *op, unsigned int nr_ops,
                 domid_t dom);

int xc_memory_op(int xc_handle, int cmd, void *arg);

int xc_get_pfn_type_batch(int xc_handle, uint32_t dom,
                          int num, uint32_t *arr);


/* Get current total pages allocated to a domain. */
long xc_get_tot_pages(int xc_handle, uint32_t domid);

/**
 * This function retrieves the the number of bytes available
 * in the heap in a specific range of address-widths and nodes.
 * 
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the domain to query
 * @parm min_width the smallest address width to query (0 if don't care)
 * @parm max_width the largest address width to query (0 if don't care)
 * @parm node the node to query (-1 for all)
 * @parm *bytes caller variable to put total bytes counted
 * @return 0 on success, <0 on failure.
 */
int xc_availheap(int xc_handle, int min_width, int max_width, int node,
                 uint64_t *bytes);

/*
 * Trace Buffer Operations
 */

/**
 * xc_tbuf_enable - enable tracing buffers
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm cnt size of tracing buffers to create (in pages)
 * @parm mfn location to store mfn of the trace buffers to
 * @parm size location to store the size (in bytes) of a trace buffer to
 *
 * Gets the machine address of the trace pointer area and the size of the
 * per CPU buffers.
 */
int xc_tbuf_enable(int xc_handle, unsigned long pages,
                   unsigned long *mfn, unsigned long *size);

/*
 * Disable tracing buffers.
 */
int xc_tbuf_disable(int xc_handle);

/**
 * This function sets the size of the trace buffers. Setting the size
 * is currently a one-shot operation that may be performed either at boot
 * time or via this interface, not both. The buffer size must be set before
 * enabling tracing.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm size the size in pages per cpu for the trace buffers
 * @return 0 on success, -1 on failure.
 */
int xc_tbuf_set_size(int xc_handle, unsigned long size);

/**
 * This function retrieves the current size of the trace buffers.
 * Note that the size returned is in terms of bytes, not pages.

 * @parm xc_handle a handle to an open hypervisor interface
 * @parm size will contain the size in bytes for the trace buffers
 * @return 0 on success, -1 on failure.
 */
int xc_tbuf_get_size(int xc_handle, unsigned long *size);

int xc_tbuf_set_cpu_mask(int xc_handle, uint32_t mask);

int xc_tbuf_set_evt_mask(int xc_handle, uint32_t mask);

int xc_domctl(int xc_handle, struct xen_domctl *domctl);
int xc_sysctl(int xc_handle, struct xen_sysctl *sysctl);

int xc_version(int xc_handle, int cmd, void *arg);

int xc_acm_op(int xc_handle, int cmd, void *arg, unsigned long arg_size);

int xc_flask_op(int xc_handle, flask_op_t *op);

/*
 * Subscribe to state changes in a domain via evtchn.
 * Returns -1 on failure, in which case errno will be set appropriately.
 */
int xc_domain_subscribe_for_suspend(
    int xc_handle, domid_t domid, evtchn_port_t port);

/**************************
 * GRANT TABLE OPERATIONS *
 **************************/

/*
 * Return a handle to the grant table driver, or -1 on failure, in which case
 * errno will be set appropriately.
 */
int xc_gnttab_open(void);

/*
 * Close a handle previously allocated with xc_gnttab_open().
 */
int xc_gnttab_close(int xcg_handle);

/*
 * Memory maps a grant reference from one domain to a local address range.
 * Mappings should be unmapped with xc_gnttab_munmap.  Returns NULL on failure.
 *
 * @parm xcg_handle a handle on an open grant table interface
 * @parm domid the domain to map memory from
 * @parm ref the grant reference ID to map
 * @parm prot same flag as in mmap()
 */
void *xc_gnttab_map_grant_ref(int xcg_handle,
                              uint32_t domid,
                              uint32_t ref,
                              int prot);

/**
 * Memory maps one or more grant references from one or more domains to a
 * contiguous local address range. Mappings should be unmapped with
 * xc_gnttab_munmap.  Returns NULL on failure.
 *
 * @parm xcg_handle a handle on an open grant table interface
 * @parm count the number of grant references to be mapped
 * @parm domids an array of @count domain IDs by which the corresponding @refs
 *              were granted
 * @parm refs an array of @count grant references to be mapped
 * @parm prot same flag as in mmap()
 */
void *xc_gnttab_map_grant_refs(int xcg_handle,
                               uint32_t count,
                               uint32_t *domids,
                               uint32_t *refs,
                               int prot);

/**
 * Memory maps one or more grant references from one domain to a
 * contiguous local address range. Mappings should be unmapped with
 * xc_gnttab_munmap.  Returns NULL on failure.
 *
 * @parm xcg_handle a handle on an open grant table interface
 * @parm count the number of grant references to be mapped
 * @parm domid the domain to map memory from
 * @parm refs an array of @count grant references to be mapped
 * @parm prot same flag as in mmap()
 */
void *xc_gnttab_map_domain_grant_refs(int xcg_handle,
                                      uint32_t count,
                                      uint32_t domid,
                                      uint32_t *refs,
                                      int prot);

/*
 * Unmaps the @count pages starting at @start_address, which were mapped by a
 * call to xc_gnttab_map_grant_ref or xc_gnttab_map_grant_refs. Returns zero
 * on success, otherwise sets errno and returns non-zero.
 */
int xc_gnttab_munmap(int xcg_handle,
                     void *start_address,
                     uint32_t count);

/*
 * Sets the maximum number of grants that may be mapped by the given instance
 * to @count.
 *
 * N.B. This function must be called after opening the handle, and before any
 *      other functions are invoked on it.
 *
 * N.B. When variable-length grants are mapped, fragmentation may be observed,
 *      and it may not be possible to satisfy requests up to the maximum number
 *      of grants.
 */
int xc_gnttab_set_max_grants(int xcg_handle,
			     uint32_t count);

int xc_gnttab_op(int xc_handle, int cmd,
                 void * op, int op_size, int count);

int xc_gnttab_get_version(int xc_handle, int domid);
grant_entry_v1_t *xc_gnttab_map_table_v1(int xc_handle, int domid, int *gnt_num);
grant_entry_v2_t *xc_gnttab_map_table_v2(int xc_handle, int domid, int *gnt_num);

int xc_physdev_map_pirq(int xc_handle,
                        int domid,
                        int index,
                        int *pirq);

int xc_physdev_map_pirq_msi(int xc_handle,
                            int domid,
                            int index,
                            int *pirq,
                            int devfn,
                            int bus,
                            int entry_nr,
                            uint64_t table_base);

int xc_physdev_unmap_pirq(int xc_handle,
                          int domid,
                          int pirq);

int xc_hvm_set_pci_intx_level(
    int xc_handle, domid_t dom,
    uint8_t domain, uint8_t bus, uint8_t device, uint8_t intx,
    unsigned int level);
int xc_hvm_set_isa_irq_level(
    int xc_handle, domid_t dom,
    uint8_t isa_irq,
    unsigned int level);

int xc_hvm_set_pci_link_route(
    int xc_handle, domid_t dom, uint8_t link, uint8_t isa_irq);


/*
 * Track dirty bit changes in the VRAM area
 *
 * All of this is done atomically:
 * - get the dirty bitmap since the last call
 * - set up dirty tracking area for period up to the next call
 * - clear the dirty tracking area.
 *
 * Returns -ENODATA and does not fill bitmap if the area has changed since the
 * last call.
 */
int xc_hvm_track_dirty_vram(
    int xc_handle, domid_t dom,
    uint64_t first_pfn, uint64_t nr,
    unsigned long *bitmap);

/*
 * Notify that some pages got modified by the Device Model
 */
int xc_hvm_modified_memory(
    int xc_handle, domid_t dom, uint64_t first_pfn, uint64_t nr);

/*
 * Set a range of memory to a specific type.
 * Allowed types are HVMMEM_ram_rw, HVMMEM_ram_ro, HVMMEM_mmio_dm
 */
int xc_hvm_set_mem_type(
    int xc_handle, domid_t dom, hvmmem_type_t memtype, uint64_t first_pfn, uint64_t nr);


typedef enum {
  XC_ERROR_NONE = 0,
  XC_INTERNAL_ERROR = 1,
  XC_INVALID_KERNEL = 2,
  XC_INVALID_PARAM = 3,
  XC_OUT_OF_MEMORY = 4,
} xc_error_code;

#define XC_MAX_ERROR_MSG_LEN 1024
typedef struct {
  int code;
  char message[XC_MAX_ERROR_MSG_LEN];
} xc_error;

/*
 * Return a pointer to the last error. This pointer and the
 * data pointed to are only valid until the next call to
 * libxc.
 */
const xc_error *xc_get_last_error(void);

/*
 * Clear the last error
 */
void xc_clear_last_error(void);

typedef void (*xc_error_handler)(const xc_error *err);

/*
 * The default error handler which prints to stderr
 */
void xc_default_error_handler(const xc_error *err);

/*
 * Convert an error code into a text description
 */
const char *xc_error_code_to_desc(int code);

/*
 * Registers a callback to handle errors
 */
xc_error_handler xc_set_error_handler(xc_error_handler handler);

int xc_set_hvm_param(int handle, domid_t dom, int param, unsigned long value);
int xc_get_hvm_param(int handle, domid_t dom, int param, unsigned long *value);

/* IA64 specific, nvram save */
int xc_ia64_save_to_nvram(int xc_handle, uint32_t dom);

/* IA64 specific, nvram init */
int xc_ia64_nvram_init(int xc_handle, char *dom_name, uint32_t dom);

/* IA64 specific, set guest OS type optimizations */
int xc_ia64_set_os_type(int xc_handle, char *guest_os_type, uint32_t dom);

/* HVM guest pass-through */
int xc_assign_device(int xc_handle,
                     uint32_t domid,
                     uint32_t machine_bdf);

int xc_get_device_group(int xc_handle,
                     uint32_t domid,
                     uint32_t machine_bdf,
                     uint32_t max_sdevs,
                     uint32_t *num_sdevs,
                     uint32_t *sdev_array);

int xc_test_assign_device(int xc_handle,
                          uint32_t domid,
                          uint32_t machine_bdf);

int xc_deassign_device(int xc_handle,
                     uint32_t domid,
                     uint32_t machine_bdf);

int xc_domain_memory_mapping(int xc_handle,
                             uint32_t domid,
                             unsigned long first_gfn,
                             unsigned long first_mfn,
                             unsigned long nr_mfns,
                             uint32_t add_mapping);

int xc_domain_ioport_mapping(int xc_handle,
                             uint32_t domid,
                             uint32_t first_gport,
                             uint32_t first_mport,
                             uint32_t nr_ports,
                             uint32_t add_mapping);

int xc_domain_update_msi_irq(
    int xc_handle,
    uint32_t domid,
    uint32_t gvec,
    uint32_t pirq,
    uint32_t gflags,
    uint64_t gtable);

int xc_domain_unbind_msi_irq(int xc_handle,
                             uint32_t domid,
                             uint32_t gvec,
                             uint32_t pirq,
                             uint32_t gflags);

int xc_domain_bind_pt_irq(int xc_handle,
                          uint32_t domid,
                          uint8_t machine_irq,
                          uint8_t irq_type,
                          uint8_t bus,
                          uint8_t device,
                          uint8_t intx,
                          uint8_t isa_irq);

int xc_domain_unbind_pt_irq(int xc_handle,
                          uint32_t domid,
                          uint8_t machine_irq,
                          uint8_t irq_type,
                          uint8_t bus,
                          uint8_t device,
                          uint8_t intx,
                          uint8_t isa_irq);

int xc_domain_bind_pt_pci_irq(int xc_handle,
                              uint32_t domid,
                              uint8_t machine_irq,
                              uint8_t bus,
                              uint8_t device,
                              uint8_t intx);

int xc_domain_bind_pt_isa_irq(int xc_handle,
                              uint32_t domid,
                              uint8_t machine_irq);

int xc_domain_set_machine_address_size(int handle,
				       uint32_t domid,
				       unsigned int width);
int xc_domain_get_machine_address_size(int handle,
				       uint32_t domid);

int xc_domain_suppress_spurious_page_faults(int handle,
					  uint32_t domid);

/* Set the target domain */
int xc_domain_set_target(int xc_handle,
                         uint32_t domid,
                         uint32_t target);

/* Control the domain for debug */
int xc_domain_debug_control(int xc_handle,
                            uint32_t domid,
                            uint32_t sop,
                            uint32_t vcpu);

#if defined(__i386__) || defined(__x86_64__)
int xc_cpuid_check(int xc,
                   const unsigned int *input,
                   const char **config,
                   char **config_transformed);
int xc_cpuid_set(int xc,
                 domid_t domid,
                 const unsigned int *input,
                 const char **config,
                 char **config_transformed);
int xc_cpuid_apply_policy(int xc,
                          domid_t domid);
void xc_cpuid_to_str(const unsigned int *regs,
                     char **strs);
#endif

struct xc_px_val {
    uint64_t freq;        /* Px core frequency */
    uint64_t residency;   /* Px residency time */
    uint64_t count;       /* Px transition count */
};

struct xc_px_stat {
    uint8_t total;        /* total Px states */
    uint8_t usable;       /* usable Px states */
    uint8_t last;         /* last Px state */
    uint8_t cur;          /* current Px state */
    uint64_t *trans_pt;   /* Px transition table */
    struct xc_px_val *pt;
};

int xc_pm_get_max_px(int xc_handle, int cpuid, int *max_px);
int xc_pm_get_pxstat(int xc_handle, int cpuid, struct xc_px_stat *pxpt);
int xc_pm_reset_pxstat(int xc_handle, int cpuid);

struct xc_cx_stat {
    uint32_t nr;    /* entry nr in triggers & residencies, including C0 */
    uint32_t last;         /* last Cx state */
    uint64_t idle_time;    /* idle time from boot */
    uint64_t *triggers;    /* Cx trigger counts */
    uint64_t *residencies; /* Cx residencies */
};
typedef struct xc_cx_stat xc_cx_stat_t;

int xc_pm_get_max_cx(int xc_handle, int cpuid, int *max_cx);
int xc_pm_get_cxstat(int xc_handle, int cpuid, struct xc_cx_stat *cxpt);
int xc_pm_reset_cxstat(int xc_handle, int cpuid);

int xc_cpu_online(int xc_handle, int cpu);
int xc_cpu_offline(int xc_handle, int cpu);

/* 
 * cpufreq para name of this structure named 
 * same as sysfs file name of native linux
 */
typedef xen_userspace_t xc_userspace_t;
typedef xen_ondemand_t xc_ondemand_t;

struct xc_get_cpufreq_para {
    /* IN/OUT variable */
    uint32_t cpu_num;
    uint32_t freq_num;
    uint32_t gov_num;

    /* for all governors */
    /* OUT variable */
    uint32_t *affected_cpus;
    uint32_t *scaling_available_frequencies;
    char     *scaling_available_governors;
    char scaling_driver[CPUFREQ_NAME_LEN];

    uint32_t cpuinfo_cur_freq;
    uint32_t cpuinfo_max_freq;
    uint32_t cpuinfo_min_freq;
    uint32_t scaling_cur_freq;

    char scaling_governor[CPUFREQ_NAME_LEN];
    uint32_t scaling_max_freq;
    uint32_t scaling_min_freq;

    /* for specific governor */
    union {
        xc_userspace_t userspace;
        xc_ondemand_t ondemand;
    } u;
};

int xc_get_cpufreq_para(int xc_handle, int cpuid,
                        struct xc_get_cpufreq_para *user_para);
int xc_set_cpufreq_gov(int xc_handle, int cpuid, char *govname);
int xc_set_cpufreq_para(int xc_handle, int cpuid,
                        int ctrl_type, int ctrl_value);
int xc_get_cpufreq_avgfreq(int xc_handle, int cpuid, int *avg_freq);

struct xc_get_cputopo {
     /* IN: maximum addressable entry in
      * the caller-provided cpu_to_core/socket.
      */
    uint32_t max_cpus;
    uint32_t *cpu_to_core;
    uint32_t *cpu_to_socket;

    /* OUT: number of cpus returned
     * If OUT is greater than IN then the cpu_to_core/socket is truncated!
     */
    uint32_t nr_cpus;
};

int xc_get_cputopo(int xc_handle, struct xc_get_cputopo *info);

int xc_set_sched_opt_smt(int xc_handle, uint32_t value);
int xc_set_vcpu_migration_delay(int xc_handle, uint32_t value);
int xc_get_vcpu_migration_delay(int xc_handle, uint32_t *value);

int xc_get_cpuidle_max_cstate(int xc_handle, uint32_t *value);
int xc_set_cpuidle_max_cstate(int xc_handle, uint32_t value);

/**
 * tmem operations
 */
int xc_tmem_control(int xc, int32_t pool_id, uint32_t subop, uint32_t cli_id,
                    uint32_t arg1, uint32_t arg2, uint64_t arg3, void *buf);
int xc_tmem_auth(int xc_handle, int cli_id, char *uuid_str, int arg1);
int xc_tmem_save(int xc_handle, int dom, int live, int fd, int field_marker);
int xc_tmem_save_extra(int xc_handle, int dom, int fd, int field_marker);
void xc_tmem_save_done(int xc_handle, int dom);
int xc_tmem_restore(int xc_handle, int dom, int fd);
int xc_tmem_restore_extra(int xc_handle, int dom, int fd);

#endif /* XENCTRL_H */
