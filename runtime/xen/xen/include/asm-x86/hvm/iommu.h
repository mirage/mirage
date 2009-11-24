#ifndef __ASM_X86_HVM_IOMMU_H__
#define __ASM_X86_HVM_IOMMU_H__

struct iommu_ops;
extern const struct iommu_ops intel_iommu_ops;
extern const struct iommu_ops amd_iommu_ops;
extern int intel_vtd_setup(void);
extern int amd_iov_detect(void);

static inline const struct iommu_ops *iommu_get_ops(void)
{   
    switch ( boot_cpu_data.x86_vendor )
    {
    case X86_VENDOR_INTEL:
        return &intel_iommu_ops;
    case X86_VENDOR_AMD:
        return &amd_iommu_ops;
    default:
        BUG();
    }

    return NULL;
}

static inline int iommu_hardware_setup(void)
{
    switch ( boot_cpu_data.x86_vendor )
    {
    case X86_VENDOR_INTEL:
        return intel_vtd_setup();
    case X86_VENDOR_AMD:
        return amd_iov_detect();
    default:
        BUG();
    }

    return 0;
}

#endif /* __ASM_X86_HVM_IOMMU_H__ */
