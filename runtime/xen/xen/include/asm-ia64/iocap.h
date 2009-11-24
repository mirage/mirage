/******************************************************************************
 * iocap.h
 * 
 * Architecture-specific per-domain I/O capabilities.
 */

#ifndef __IA64_IOCAP_H__
#define __IA64_IOCAP_H__

extern int ioports_permit_access(struct domain *d, unsigned int gs,
				 unsigned int s, unsigned int e);
extern int ioports_deny_access(struct domain *d,
			       unsigned int s, unsigned int e);

#define ioports_access_permitted(d, s, e)               \
    rangeset_contains_range((d)->arch.ioport_caps, s, e)

#define multipage_allocation_permitted(d, order)        \
    (((order) == 0) ||                                  \
     !rangeset_is_empty((d)->iomem_caps) ||             \
     !rangeset_is_empty((d)->arch.ioport_caps))

#endif /* __IA64_IOCAP_H__ */
