#ifndef __GNTTAB_H__
#define __GNTTAB_H__

#include <xen/grant_table.h>

void gnttab_grant_access(grant_ref_t ref, domid_t domid, unsigned long frame,
				int readonly);
#if 0
grant_ref_t gnttab_grant_transfer(domid_t domid, unsigned long pfn);
unsigned long gnttab_end_transfer(grant_ref_t gref);
int gnttab_end_access(grant_ref_t ref);
const char *gnttabop_error(int16_t status);
void fini_gnttab(void);
#endif

#endif /* !__GNTTAB_H__ */
