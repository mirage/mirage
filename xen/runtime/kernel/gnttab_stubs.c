/*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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
#include <caml/memory.h>
#include <caml/bigarray.h>
#include <caml/alloc.h>
#include <caml/fail.h>

/* For printk() */
#include <log.h>

static grant_entry_t *gnttab_table;

/* Return the size of the grant table */
CAMLprim value
caml_gnttab_nr_entries(value unit)
{
    return Val_int(NR_GRANT_ENTRIES);
}

/* Return the number of reserved grant entries at the start */
CAMLprim value
caml_gnttab_reserved(value unit)
{
    return Val_int(NR_RESERVED_ENTRIES);
}

static void
gnttab_grant_access(grant_ref_t ref, void *page, int domid, int ro)
{
    gnttab_table[ref].frame = virt_to_mfn(page);
    gnttab_table[ref].domid = domid;
    wmb();
    gnttab_table[ref].flags = GTF_permit_access | (ro * GTF_readonly);
}

static void
gnttab_grant_transfer(grant_ref_t ref, void *page, int domid)
{
    gnttab_table[ref].frame = virt_to_mfn(page);
    gnttab_table[ref].domid = domid;
    wmb();
    gnttab_table[ref].flags = GTF_accept_transfer;
}

/* From the reference implementation
   http://git.kernel.org/?p=linux/kernel/git/torvalds/linux.git;a=blob;f=drivers/xen/grant-table.c;hb=HEAD */
static unsigned long
gnttab_end_transfer(grant_ref_t ref)
{
    unsigned long frame;
	uint16_t flags;
    uint16_t *pflags = &gnttab_table[ref].flags;

    /*
     * If a transfer is not even yet started, try to reclaim the grant
     * reference and return failure (== 0).
     */
    while (!((flags = *pflags) & GTF_transfer_committed)) {
      if (synch_cmpxchg(pflags, flags, 0) == flags)
        return 0;
    }

    /* If a transfer is in progress then wait until it is completed. */
    while (!(flags & GTF_transfer_completed)) {
      flags = *pflags;
    }
 
    rmb();  /* Read the frame number /after/ reading completion status. */
    frame = gnttab_table[ref].frame;
    BUG_ON(frame == 0);
	
    return frame;
}

/* An Io_page is an OCaml bigarray value with CAML_BA_MANAGED. If this has a
 * proxy set, then that points to the *base* of the data, and the array->data
 * is a pointer into a sub-view of that.
 * The grant functions always grant the base page rather than the current
 * view, since grants have to be page-aligned */

static void *
base_page_of(value v_iopage)
{
    struct caml_ba_array *a = (struct caml_ba_array *)Caml_ba_array_val(v_iopage);
    void *page = (a->proxy == NULL) ? a->data : a->proxy->data;
    ASSERT(((unsigned long)page) % PAGE_SIZE == 0);
    return page;
}

CAMLprim value
caml_gnttab_map(value v_ref, value v_iopage, value v_domid, value v_readonly)
{
    void *page = base_page_of(v_iopage);

    struct gnttab_map_grant_ref op;
    op.ref = Int_val(v_ref);
    op.dom = Int_val(v_domid);
    op.host_addr = (unsigned long) page;
    op.flags = GNTMAP_host_map;
    if (Bool_val(v_readonly)) op.flags |= GNTMAP_readonly;

    HYPERVISOR_grant_table_op(GNTTABOP_map_grant_ref, &op, 1);
    if (op.status != GNTST_okay) {
      printk("GNTTABOP_map_grant_ref ref = %d domid = %d failed with status = %d\n", op.ref, op.dom, op.status);
      caml_failwith("caml_gnttab_map");
    }

    printk("GNTTABOP_map_grant_ref mapped to %x\n", op.host_addr);
    return Val_int(op.handle);
}

CAMLprim value
caml_gnttab_unmap(value v_handle)
{
  struct gnttab_unmap_grant_ref op;
  /* There's no need to resupply these values. 0 means "ignore" */
  op.host_addr = 0;
  op.dev_bus_addr = 0;
  op.handle = Int_val(v_handle);

  HYPERVISOR_grant_table_op(GNTTABOP_unmap_grant_ref, &op, 1);

  if (op.status != GNTST_okay) {
    printk("GNTTABOP_unmap_grant_ref handle = %x failed", op.handle);
    caml_failwith("Failed to unmap grant.");
  }

  return Val_unit;
}

CAMLprim value
caml_gnttab_grant_access(value v_ref, value v_iopage, value v_domid, value v_readonly)
{
    grant_ref_t ref = Int_val(v_ref);
    void *page = base_page_of(v_iopage);
    gnttab_grant_access(ref, page, Int_val(v_domid), Bool_val(v_readonly));
    return Val_unit;
}

CAMLprim value
caml_gnttab_end_access(value v_ref)
{
    grant_ref_t ref = Int_val(v_ref);
    uint16_t flags, nflags;

    BUG_ON(ref >= NR_GRANT_ENTRIES || ref < NR_RESERVED_ENTRIES);

    nflags = gnttab_table[ref].flags;
    do {
        if ((flags = nflags) & (GTF_reading|GTF_writing)) {
            printk("WARNING: g.e. %d still in use! (%x)\n", ref, flags);
            return Val_unit;
        }
    } while ((nflags = synch_cmpxchg(&gnttab_table[ref].flags, flags, 0)) !=
            flags);

    return Val_unit;
}


/* Initialise grant tables and map machine frames to a VA */
CAMLprim value
caml_gnttab_init(value unit)
{
    struct gnttab_setup_table setup;
    unsigned long frames[NR_GRANT_FRAMES];

    setup.dom = DOMID_SELF;
    setup.nr_frames = NR_GRANT_FRAMES;
    set_xen_guest_handle(setup.frame_list, frames);

    HYPERVISOR_grant_table_op(GNTTABOP_setup_table, &setup, 1);
    gnttab_table = map_frames(frames, NR_GRANT_FRAMES);
    printk("gnttab_table mapped at %p\n", gnttab_table);

    return Val_unit;
}

/* Disable grant tables */
CAMLprim value
caml_gnttab_fini(value unit)
{
    struct gnttab_setup_table setup;

    setup.dom = DOMID_SELF;
    setup.nr_frames = 0;

    HYPERVISOR_grant_table_op(GNTTABOP_setup_table, &setup, 1);

    unmap_frames((unsigned long)gnttab_table, NR_GRANT_FRAMES);

    return Val_unit;
}

