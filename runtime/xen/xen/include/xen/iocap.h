/******************************************************************************
 * iocap.h
 * 
 * Per-domain I/O capabilities.
 */

#ifndef __XEN_IOCAP_H__
#define __XEN_IOCAP_H__

#include <xen/rangeset.h>
#include <asm/iocap.h>

#define iomem_permit_access(d, s, e)                    \
    rangeset_add_range((d)->iomem_caps, s, e)
#define iomem_deny_access(d, s, e)                      \
    rangeset_remove_range((d)->iomem_caps, s, e)
#define iomem_access_permitted(d, s, e)                 \
    rangeset_contains_range((d)->iomem_caps, s, e)

#define irq_permit_access(d, i)                         \
    rangeset_add_singleton((d)->irq_caps, i)
#define irq_deny_access(d, i)                           \
    rangeset_remove_singleton((d)->irq_caps, i)
#define irqs_permit_access(d, s, e)                     \
    rangeset_add_range((d)->irq_caps, s, e)
#define irqs_deny_access(d, s, e)                       \
    rangeset_remove_range((d)->irq_caps, s, e)
#define irq_access_permitted(d, i)                      \
    rangeset_contains_singleton((d)->irq_caps, i)

#endif /* __XEN_IOCAP_H__ */
