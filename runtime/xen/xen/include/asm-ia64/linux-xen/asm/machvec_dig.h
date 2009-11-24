#ifndef _ASM_IA64_MACHVEC_DIG_h
#define _ASM_IA64_MACHVEC_DIG_h

extern ia64_mv_setup_t dig_setup;

/*
 * This stuff has dual use!
 *
 * For a generic kernel, the macros are used to initialize the
 * platform's machvec structure.  When compiling a non-generic kernel,
 * the macros are used directly.
 */
#define platform_name		"dig"
#ifdef XEN
/*
 * All the World is a PC .... yay! yay! yay!
 */
extern ia64_mv_setup_t hpsim_setup;
#define platform_setup				hpsim_setup

#define platform_dma_init			machvec_noop
#define platform_dma_alloc_coherent		machvec_noop_dma_alloc_coherent
#define platform_dma_free_coherent		machvec_noop_dma_free_coherent
#define platform_dma_map_single			machvec_noop_dma_map_single
#define platform_dma_unmap_single		machvec_noop_dma_unmap_single
#define platform_dma_map_sg			machvec_noop_dma_map_sg
#define platform_dma_unmap_sg			machvec_noop_dma_unmap_sg
#define platform_dma_sync_single_for_cpu	\
	machvec_noop_dma_sync_single_for_cpu
#define platform_dma_sync_sg_for_cpu		\
	machvec_noop_dma_sync_sg_for_cpu
#define platform_dma_sync_single_for_device	\
	machvec_noop_dma_sync_single_for_device
#define platform_dma_sync_sg_for_device		\
	machvec_noop_dma_sync_sg_for_device
#define platform_dma_mapping_error		machvec_noop_dma_mapping_error
#define platform_dma_supported			machvec_noop_dma_supported

#define platform_pci_get_legacy_mem		machvec_noop_pci_get_legacy_mem
#define platform_pci_legacy_read		machvec_noop_pci_legacy_read
#define platform_pci_legacy_write		machvec_noop_pci_legacy_write
#else
#define platform_setup		dig_setup
#endif

#endif /* _ASM_IA64_MACHVEC_DIG_h */
