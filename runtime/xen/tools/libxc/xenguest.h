/******************************************************************************
 * xenguest.h
 *
 * A library for guest domain management in Xen.
 *
 * Copyright (c) 2003-2004, K A Fraser.
 */

#ifndef XENGUEST_H
#define XENGUEST_H

#define XCFLAGS_LIVE      1
#define XCFLAGS_DEBUG     2
#define XCFLAGS_HVM       4
#define XCFLAGS_STDVGA    8

/* callbacks provided by xc_domain_save */
struct save_callbacks {
    int (*suspend)(void* data);
    /* callback to rendezvous with external checkpoint functions */
    int (*postcopy)(void* data);
    /* returns:
     * 0: terminate checkpointing gracefully
     * 1: take another checkpoint */
    int (*checkpoint)(void* data);

    /* to be provided as the first argument to each callback function */
    void* data;
};

/**
 * This function will save a running domain.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm fd the file descriptor to save a domain to
 * @parm dom the id of the domain
 * @return 0 on success, -1 on failure
 */
int xc_domain_save(int xc_handle, int io_fd, uint32_t dom, uint32_t max_iters,
                   uint32_t max_factor, uint32_t flags /* XCFLAGS_xxx */,
                   struct save_callbacks* callbacks,
                   int hvm, void (*switch_qemu_logdirty)(int, unsigned)); /* HVM only */


/**
 * This function will restore a saved domain.
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm fd the file descriptor to restore a domain from
 * @parm dom the id of the domain
 * @parm store_evtchn the store event channel for this domain to use
 * @parm store_mfn returned with the mfn of the store page
 * @parm hvm non-zero if this is a HVM restore
 * @parm pae non-zero if this HVM domain has PAE support enabled
 * @parm superpages non-zero to allocate guest memory with superpages
 * @return 0 on success, -1 on failure
 */
int xc_domain_restore(int xc_handle, int io_fd, uint32_t dom,
                      unsigned int store_evtchn, unsigned long *store_mfn,
                      unsigned int console_evtchn, unsigned long *console_mfn,
                      unsigned int hvm, unsigned int pae, int superpages);

/**
 * This function will create a domain for a paravirtualized Linux
 * using file names pointing to kernel and ramdisk
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the id of the domain
 * @parm mem_mb memory size in megabytes
 * @parm image_name name of the kernel image file
 * @parm ramdisk_name name of the ramdisk image file
 * @parm cmdline command line string
 * @parm flags domain creation flags
 * @parm store_evtchn the store event channel for this domain to use
 * @parm store_mfn returned with the mfn of the store page
 * @parm console_evtchn the console event channel for this domain to use
 * @parm conole_mfn returned with the mfn of the console page
 * @return 0 on success, -1 on failure
 */
int xc_linux_build(int xc_handle,
                   uint32_t domid,
                   unsigned int mem_mb,
                   const char *image_name,
                   const char *ramdisk_name,
                   const char *cmdline,
                   const char *features,
                   unsigned long flags,
                   unsigned int store_evtchn,
                   unsigned long *store_mfn,
                   unsigned int console_evtchn,
                   unsigned long *console_mfn);

/** The same interface, but the dom structure is managed by the caller */
struct xc_dom_image;
int xc_dom_linux_build(int xc_handle,
		       struct xc_dom_image *dom,
		       uint32_t domid,
		       unsigned int mem_mb,
		       const char *image_name,
		       const char *ramdisk_name,
		       unsigned long flags,
		       unsigned int store_evtchn,
		       unsigned long *store_mfn,
		       unsigned int console_evtchn,
		       unsigned long *console_mfn);

/**
 * This function will create a domain for a paravirtualized Linux
 * using buffers for kernel and initrd
 *
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm domid the id of the domain
 * @parm mem_mb memory size in megabytes
 * @parm image_buffer buffer containing kernel image
 * @parm image_size size of the kernel image buffer
 * @parm initrd_buffer name of the ramdisk image file
 * @parm initrd_size size of the ramdisk buffer
 * @parm cmdline command line string
 * @parm flags domain creation flags
 * @parm store_evtchn the store event channel for this domain to use
 * @parm store_mfn returned with the mfn of the store page
 * @parm console_evtchn the console event channel for this domain to use
 * @parm conole_mfn returned with the mfn of the console page
 * @return 0 on success, -1 on failure
 */
int xc_linux_build_mem(int xc_handle,
                       uint32_t domid,
                       unsigned int mem_mb,
                       const char *image_buffer,
                       unsigned long image_size,
                       const char *initrd_buffer,
                       unsigned long initrd_size,
                       const char *cmdline,
                       const char *features,
                       unsigned long flags,
                       unsigned int store_evtchn,
                       unsigned long *store_mfn,
                       unsigned int console_evtchn,
                       unsigned long *console_mfn);

int xc_hvm_build(int xc_handle,
                 uint32_t domid,
                 int memsize,
                 const char *image_name);

int xc_hvm_build_target_mem(int xc_handle,
                            uint32_t domid,
                            int memsize,
                            int target,
                            const char *image_name);

int xc_hvm_build_mem(int xc_handle,
                     uint32_t domid,
                     int memsize,
                     const char *image_buffer,
                     unsigned long image_size);

int xc_suspend_evtchn_release(int xce, int suspend_evtchn);

int xc_suspend_evtchn_init(int xc, int xce, int domid, int port);

int xc_await_suspend(int xce, int suspend_evtchn);

int xc_mark_page_online(int xc, unsigned long start,
                        unsigned long end, uint32_t *status);

int xc_mark_page_offline(int xc, unsigned long start,
                          unsigned long end, uint32_t *status);

int xc_query_page_offline_status(int xc, unsigned long start,
                                 unsigned long end, uint32_t *status);

int xc_exchange_page(int xc_handle, int domid, xen_pfn_t mfn);


/**
 * This function map m2p table
 * @parm xc_handle a handle to an open hypervisor interface
 * @parm max_mfn the max pfn
 * @parm prot the flags to map, such as read/write etc
 * @parm mfn0 return the first mfn, can be NULL
 * @return mapped m2p table on success, NULL on failure
 */
xen_pfn_t *xc_map_m2p(int xc_handle,
                      unsigned long max_mfn,
                      int prot,
                      unsigned long *mfn0);
#endif /* XENGUEST_H */
