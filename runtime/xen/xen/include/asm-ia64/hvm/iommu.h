#ifndef __ASM_IA64_HVM_IOMMU_H__
#define __ASM_IA64_HVM_IOMMU_H__

#include <asm/hvm/irq.h>
#include <public/event_channel.h>
#include <public/arch-ia64/hvm/save.h>
#include <asm/hw_irq.h>
#include <asm/iosapic.h>

struct iommu_ops;
extern const struct iommu_ops intel_iommu_ops;
extern int intel_vtd_setup(void);

#define iommu_get_ops() (&intel_iommu_ops)
#define iommu_hardware_setup()  (intel_vtd_setup())

static inline int domain_irq_to_vector(struct domain *d, int irq)
{
    return irq;
}

static inline void ack_APIC_irq(void)
{
    /* TODO */
}

static inline void pci_cleanup_msi(struct pci_dev *pdev)
{
    /* TODO */
}


extern int assign_irq_vector (int irq);

#endif /* __ASM_IA64_HVM_IOMMU_H__ */
