#ifndef _ASM_IA64_MACHVEC_HPZX1_h
#define _ASM_IA64_MACHVEC_HPZX1_h

extern ia64_mv_setup_t			dig_setup;
extern ia64_mv_dma_alloc_coherent	sba_alloc_coherent;
extern ia64_mv_dma_free_coherent	sba_free_coherent;
extern ia64_mv_dma_map_single		sba_map_single;
extern ia64_mv_dma_unmap_single		sba_unmap_single;
extern ia64_mv_dma_map_sg		sba_map_sg;
extern ia64_mv_dma_unmap_sg		sba_unmap_sg;
extern ia64_mv_dma_supported		sba_dma_supported;
extern ia64_mv_dma_mapping_error	sba_dma_mapping_error;

/*
 * This stuff has dual use!
 *
 * For a generic kernel, the macros are used to initialize the
 * platform's machvec structure.  When compiling a non-generic kernel,
 * the macros are used directly.
 */
#define platform_name				"hpzx1"
#ifdef XEN
extern ia64_mv_setup_t hpsim_setup;
extern ia64_mv_irq_init_t hpsim_irq_init;
#define platform_setup				hpsim_setup
#define platform_irq_init			hpsim_irq_init

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
#define platform_setup				dig_setup
#define platform_dma_init			machvec_noop
#define platform_dma_alloc_coherent		sba_alloc_coherent
#define platform_dma_free_coherent		sba_free_coherent
#define platform_dma_map_single			sba_map_single
#define platform_dma_unmap_single		sba_unmap_single
#define platform_dma_map_sg			sba_map_sg
#define platform_dma_unmap_sg			sba_unmap_sg
#define platform_dma_sync_single_for_cpu	machvec_dma_sync_single
#define platform_dma_sync_sg_for_cpu		machvec_dma_sync_sg
#define platform_dma_sync_single_for_device	machvec_dma_sync_single
#define platform_dma_sync_sg_for_device		machvec_dma_sync_sg
#define platform_dma_supported			sba_dma_supported
#define platform_dma_mapping_error		sba_dma_mapping_error
#endif

#endif /* _ASM_IA64_MACHVEC_HPZX1_h */
