#ifndef __GNTTAB_H__
#define __GNTTAB_H__


#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>

#include <xen/grant_table.h>

#define NR_RESERVED_ENTRIES 8
#define NR_GRANT_FRAMES 4
#define NR_GRANT_ENTRIES (NR_GRANT_FRAMES * PAGE_SIZE / sizeof(grant_entry_t))

typedef struct gnttab_wrap {
    grant_ref_t ref;
    void *page;
} gnttab_wrap;

#define Gnttab_wrap_val(x) (*((gnttab_wrap **)(Data_custom_val(x))))

#endif /* !__GNTTAB_H__ */
