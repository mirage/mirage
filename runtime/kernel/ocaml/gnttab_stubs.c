/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2006 Steven Smith <sos22@cam.ac.uk>
 * Copyright (c) 2006 Grzegorz Milos <gm281@cam.ac.uk>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <mini-os/x86/os.h>
#include <mini-os/mm.h>
#include <mini-os/gnttab.h>

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>

#define NR_RESERVED_ENTRIES 8
#define NR_GRANT_FRAMES 4
#define NR_GRANT_ENTRIES (NR_GRANT_FRAMES * PAGE_SIZE / sizeof(grant_entry_t))

static grant_entry_t *gnttab_table;
static grant_ref_t gnttab_list[NR_GRANT_ENTRIES];

/* Return the size of the grant table */
CAMLprim value
caml_gnttab_nr_entries(value unit)
{
    CAMLparam1(unit);
    CAMLreturn(Val_int(NR_GRANT_ENTRIES));
}

/* Return the number of reserved grant entries at the start */
CAMLprim value
caml_gnttab_reserved(value unit)
{
    CAMLparam1(unit);
    CAMLreturn(Val_int(NR_RESERVED_ENTRIES));
}

void
gnttab_grant_access(grant_ref_t ref, domid_t domid, unsigned long frame, int readonly)
{
    printk("gnttab_grant_access: ref=%d domid=%d frame=%lu ro=%d\n", ref, domid, frame, readonly);
    gnttab_table[ref].frame = frame;
    gnttab_table[ref].domid = domid;
    wmb();
    readonly *= GTF_readonly;
    gnttab_table[ref].flags = GTF_permit_access | readonly;
    printk("   flags=%d\n", gnttab_table[ref].flags);
}

/* Initialise grant tables and map machine frames to a VA */
CAMLprim value
caml_gnttab_init(value unit)
{
    CAMLparam1(unit);
    struct gnttab_setup_table setup;
    unsigned long frames[NR_GRANT_FRAMES];

    setup.dom = DOMID_SELF;
    setup.nr_frames = NR_GRANT_FRAMES;
    set_xen_guest_handle(setup.frame_list, frames);

    HYPERVISOR_grant_table_op(GNTTABOP_setup_table, &setup, 1);
    gnttab_table = map_frames(frames, NR_GRANT_FRAMES);
    printk("gnttab_table mapped at %p\n", gnttab_table);

    CAMLreturn(Val_unit); 
}

/* Disable grant tables */
CAMLprim value
caml_gnttab_fini(value unit)
{
    CAMLparam1(unit);
    struct gnttab_setup_table setup;

    setup.dom = DOMID_SELF;
    setup.nr_frames = 0;

    HYPERVISOR_grant_table_op(GNTTABOP_setup_table, &setup, 1);
    CAMLreturn(Val_unit);
}

