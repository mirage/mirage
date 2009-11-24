/******************************************************************************
 * iocap.h
 * 
 * Architecture-specific per-domain I/O capabilities.
 */

#ifndef __X86_IOCAP_H__
#define __X86_IOCAP_H__

#define ioports_permit_access(d, s, e)                  \
    rangeset_add_range((d)->arch.ioport_caps, s, e)
#define ioports_deny_access(d, s, e)                    \
    rangeset_remove_range((d)->arch.ioport_caps, s, e)
#define ioports_access_permitted(d, s, e)               \
    rangeset_contains_range((d)->arch.ioport_caps, s, e)

#define cache_flush_permitted(d)                        \
    (!rangeset_is_empty((d)->iomem_caps) ||             \
     !rangeset_is_empty((d)->arch.ioport_caps))

#define multipage_allocation_permitted(d, order)        \
    (((order) <= 9) || /* allow 2MB superpages */       \
     !rangeset_is_empty((d)->iomem_caps) ||             \
     !rangeset_is_empty((d)->arch.ioport_caps))

#endif /* __X86_IOCAP_H__ */
