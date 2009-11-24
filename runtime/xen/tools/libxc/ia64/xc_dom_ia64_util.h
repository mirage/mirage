#ifndef XC_IA64_DOM_IA64_UTIL_H
#define XC_IA64_DOM_IA64_UTIL_H

struct xc_dom_image;
uint32_t xen_ia64_version(struct xc_dom_image *dom); 
void* xen_ia64_dom_fw_map(struct xc_dom_image *dom, unsigned long mpaddr);
void xen_ia64_dom_fw_unmap(struct xc_dom_image *dom, void *addr); 
int xen_ia64_fpswa_revision(struct xc_dom_image *dom, unsigned int *revision);
int xen_ia64_is_vcpu_allocated(struct xc_dom_image *dom, uint32_t vcpu); 
int xen_ia64_is_running_on_sim(struct xc_dom_image *dom);
int xen_ia64_is_dom0(struct xc_dom_image *dom);

int
xen_ia64_dom_fw_setup(struct xc_dom_image *d, uint64_t brkimm,
                      unsigned long bp_mpa, unsigned long maxmem);
#define efi_systable_init_dom0(tables)	assert(0)
#define complete_dom0_memmap(d, tables) ({assert(0);0;})

/* Defined in xc_dom_ia64.c  */
extern int start_info_ia64(struct xc_dom_image *dom);
extern int shared_info_ia64(struct xc_dom_image *dom, void *ptr);

#define FW_MEM_BASE 0xff000000UL
#define FW_MEM_SIZE 0x01000000UL

#ifdef __XEN_TOOLS__
/* Necessary for including the acpi header chain when not in kernel context */
typedef struct { } spinlock_t;
#endif
#endif /* XC_IA64_DOM_IA64_UTIL_H */
