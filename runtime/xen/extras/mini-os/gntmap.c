/*
 * Manages grant mappings from other domains.
 *
 * Diego Ongaro <diego.ongaro@citrix.com>, July 2008
 *
 * Files of type FTYPE_GNTMAP contain a gntmap, which is an array of
 * (host address, grant handle) pairs. Grant handles come from a hypervisor map
 * operation and are needed for the corresponding unmap.
 *
 * This is a rather naive implementation in terms of performance. If we start
 * using it frequently, there's definitely some low-hanging fruit here.
 *
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
 * DEALINGS IN THE SOFTWARE.
 */

#include <mini-os/os.h>
#include <mini-os/lib.h>
#include <mini-os/xmalloc.h>
#include <errno.h>
#include <xen/grant_table.h>
#include <inttypes.h>
#include <mini-os/gntmap.h>

#define DEFAULT_MAX_GRANTS 128

struct gntmap_entry {
    unsigned long host_addr;
    grant_handle_t handle;
};

static inline int
gntmap_entry_used(struct gntmap_entry *entry)
{
    return entry->host_addr != 0;
}

static struct gntmap_entry*
gntmap_find_free_entry(struct gntmap *map)
{
    int i;

    for (i = 0; i < map->nentries; i++) {
        if (!gntmap_entry_used(&map->entries[i]))
            return &map->entries[i];
    }

#ifdef GNTMAP_DEBUG
    printk("gntmap_find_free_entry(map=%p): all %d entries full\n",
           map, map->nentries);
#endif
    return NULL;
}

static struct gntmap_entry*
gntmap_find_entry(struct gntmap *map, unsigned long addr)
{
    int i;

    for (i = 0; i < map->nentries; i++) {
        if (map->entries[i].host_addr == addr)
            return &map->entries[i];
    }
    return NULL;
}

int
gntmap_set_max_grants(struct gntmap *map, int count)
{
#ifdef GNTMAP_DEBUG
    printk("gntmap_set_max_grants(map=%p, count=%d)\n", map, count);
#endif

    if (map->nentries != 0)
        return -EBUSY;

    map->entries = xmalloc_array(struct gntmap_entry, count);
    if (map->entries == NULL)
        return -ENOMEM;

    memset(map->entries, 0, sizeof(struct gntmap_entry) * count);
    map->nentries = count;
    return 0;
}

static int
_gntmap_map_grant_ref(struct gntmap_entry *entry, 
                      unsigned long host_addr,
                      uint32_t domid,
                      uint32_t ref,
                      int writable)
{
    struct gnttab_map_grant_ref op;
    int rc;

    op.ref = (grant_ref_t) ref;
    op.dom = (domid_t) domid;
    op.host_addr = (uint64_t) host_addr;
    op.flags = GNTMAP_host_map;
    if (!writable)
        op.flags |= GNTMAP_readonly;

    rc = HYPERVISOR_grant_table_op(GNTTABOP_map_grant_ref, &op, 1);
    if (rc != 0 || op.status != GNTST_okay) {
        printk("GNTTABOP_map_grant_ref failed: "
               "returned %d, status %" PRId16 "\n",
               rc, op.status);
        return rc != 0 ? rc : op.status;
    }

    entry->host_addr = host_addr;
    entry->handle = op.handle;
    return 0;
}

static int
_gntmap_unmap_grant_ref(struct gntmap_entry *entry)
{
    struct gnttab_unmap_grant_ref op;
    int rc;

    op.host_addr    = (uint64_t) entry->host_addr;
    op.dev_bus_addr = 0;
    op.handle       = entry->handle;

    rc = HYPERVISOR_grant_table_op(GNTTABOP_unmap_grant_ref, &op, 1);
    if (rc != 0 || op.status != GNTST_okay) {
        printk("GNTTABOP_unmap_grant_ref failed: "
               "returned %d, status %" PRId16 "\n",
               rc, op.status);
        return rc != 0 ? rc : op.status;
    }

    entry->host_addr = 0;
    return 0;
}

int
gntmap_munmap(struct gntmap *map, unsigned long start_address, int count)
{
    int i, rc;
    struct gntmap_entry *ent;

#ifdef GNTMAP_DEBUG
    printk("gntmap_munmap(map=%p, start_address=%lx, count=%d)\n",
           map, start_address, count);
#endif

    for (i = 0; i < count; i++) {
        ent = gntmap_find_entry(map, start_address + PAGE_SIZE * i);
        if (ent == NULL) {
            printk("gntmap: tried to munmap unknown page\n");
            return -EINVAL;
        }

        rc = _gntmap_unmap_grant_ref(ent);
        if (rc != 0)
            return rc;
    }

    return 0;
}

void*
gntmap_map_grant_refs(struct gntmap *map, 
                      uint32_t count,
                      uint32_t *domids,
                      int domids_stride,
                      uint32_t *refs,
                      int writable)
{
    unsigned long addr;
    struct gntmap_entry *ent;
    int i;

#ifdef GNTMAP_DEBUG
    printk("gntmap_map_grant_refs(map=%p, count=%" PRIu32 ", "
           "domids=%p [%" PRIu32 "...], domids_stride=%d, "
           "refs=%p [%" PRIu32 "...], writable=%d)\n",
           map, count,
           domids, domids == NULL ? 0 : domids[0], domids_stride,
           refs, refs == NULL ? 0 : refs[0], writable);
#endif

    (void) gntmap_set_max_grants(map, DEFAULT_MAX_GRANTS);

    addr = allocate_ondemand((unsigned long) count, 1);
    if (addr == 0)
        return NULL;

    for (i = 0; i < count; i++) {
        ent = gntmap_find_free_entry(map);
        if (ent == NULL ||
            _gntmap_map_grant_ref(ent,
                                  addr + PAGE_SIZE * i,
                                  domids[i * domids_stride],
                                  refs[i],
                                  writable) != 0) {

            (void) gntmap_munmap(map, addr, i);
            return NULL;
        }
    }

    return (void*) addr;
}

void
gntmap_init(struct gntmap *map)
{
#ifdef GNTMAP_DEBUG
    printk("gntmap_init(map=%p)\n", map);
#endif
    map->nentries = 0;
    map->entries = NULL;
}

void
gntmap_fini(struct gntmap *map)
{
    struct gntmap_entry *ent;
    int i;

#ifdef GNTMAP_DEBUG
    printk("gntmap_fini(map=%p)\n", map);
#endif

    for (i = 0; i < map->nentries; i++) {
        ent = &map->entries[i];
        if (gntmap_entry_used(ent))
            (void) _gntmap_unmap_grant_ref(ent);
    }

    xfree(map->entries);
    map->entries = NULL;
    map->nentries = 0;
}
