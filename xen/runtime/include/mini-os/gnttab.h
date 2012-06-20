#ifndef __GNTTAB_H__
#define __GNTTAB_H__

#include <xen/grant_table.h>

#define NR_RESERVED_ENTRIES 8
#define NR_GRANT_FRAMES 4
#define NR_GRANT_ENTRIES (NR_GRANT_FRAMES * PAGE_SIZE / sizeof(grant_entry_t))

#endif /* !__GNTTAB_H__ */
