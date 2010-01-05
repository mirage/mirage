/******************************************************************************
 * kernel.c
 * 
 * Assorted crap goes here, including the initial C entry point, jumped at
 * from head.S.
 * 
 * Copyright (c) 2002-2003, K A Fraser & R Neugebauer
 * Copyright (c) 2005, Grzegorz Milos, Intel Research Cambridge
 * Copyright (c) 2006, Robert Kaiser, FH Wiesbaden
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
#include <mini-os/hypervisor.h>
#include <mini-os/mm.h>
#include <mini-os/events.h>
#include <mini-os/time.h>
#include <mini-os/types.h>
#include <mini-os/lib.h>
#include <mini-os/sched.h>
#include <mini-os/xenbus.h>
#include <mini-os/gnttab.h>
#include <mini-os/netfront.h>
#include <mini-os/blkfront.h>
#include <mini-os/xmalloc.h>
#include <fcntl.h>
#include <xen/features.h>
#include <xen/version.h>

int app_main(start_info_t *);

static struct netfront_dev *net_dev;

uint8_t xen_features[XENFEAT_NR_SUBMAPS * 32];

void setup_xen_features(void)
{
    xen_feature_info_t fi;
    int i, j;

    for (i = 0; i < XENFEAT_NR_SUBMAPS; i++) 
    {
        fi.submap_idx = i;
        if (HYPERVISOR_xen_version(XENVER_get_features, &fi) < 0)
            break;
        
        for (j=0; j<32; j++)
            xen_features[i*32+j] = !!(fi.submap & 1<<j);
    }
}

void test_xenbus(void);

static void xenbus_tester(void *p)
{
    printk("Xenbus tests disabled, because of a Xend bug.\n");
    /* test_xenbus(); */
}

static void periodic_thread(void *p)
{
    struct timeval tv;
    printk("Periodic thread started.\n");
    for(;;)
    {
        gettimeofday(&tv, NULL);
        printk("T(s=%ld us=%ld)\n", tv.tv_sec, tv.tv_usec);
        msleep(1000);
    }
}

static void netfront_thread(void *p)
{
    net_dev = init_netfront(NULL, NULL, NULL, NULL);
}

static struct blkfront_dev *blk_dev;
static struct blkfront_info blk_info;
static uint64_t blk_size_read;
static uint64_t blk_size_write;

struct blk_req {
    struct blkfront_aiocb aiocb;
    int rand_value;
    struct blk_req *next;
};

static struct blk_req *blk_alloc_req(uint64_t sector)
{
    struct blk_req *req = xmalloc(struct blk_req);
    req->aiocb.aio_dev = blk_dev;
    req->aiocb.aio_buf = _xmalloc(blk_info.sector_size, blk_info.sector_size);
    req->aiocb.aio_nbytes = blk_info.sector_size;
    req->aiocb.aio_offset = sector * blk_info.sector_size;
    req->aiocb.data = req;
    req->next = NULL;
    return req;
}

static void blk_read_completed(struct blkfront_aiocb *aiocb, int ret)
{
    struct blk_req *req = aiocb->data;
    if (ret)
        printk("got error code %d when reading at offset %ld\n", ret, aiocb->aio_offset);
    else
        blk_size_read += blk_info.sector_size;
    free(aiocb->aio_buf);
    free(req);
}

static void blk_read_sector(uint64_t sector)
{
    struct blk_req *req;

    req = blk_alloc_req(sector);
    req->aiocb.aio_cb = blk_read_completed;

    blkfront_aio_read(&req->aiocb);
}

/*
 * INITIAL C ENTRY POINT.
 */
void start_kernel(start_info_t *si)
{
    static char hello[] = "Bootstrapping...\n";

    (void)HYPERVISOR_console_io(CONSOLEIO_write, strlen(hello), hello);

    arch_init(si);

    trap_init();

    /* print out some useful information  */
    printk("Mirage OS!\n");
    printk("  start_info: %p(VA)\n", si);
    printk("    nr_pages: 0x%lx\n", si->nr_pages);
    printk("  shared_inf: 0x%08lx(MA)\n", si->shared_info);
    printk("     pt_base: %p(VA)\n", (void *)si->pt_base); 
    printk("nr_pt_frames: 0x%lx\n", si->nr_pt_frames);
    printk("    mfn_list: %p(VA)\n", (void *)si->mfn_list); 
    printk("   mod_start: 0x%lx(VA)\n", si->mod_start);
    printk("     mod_len: %lu\n", si->mod_len); 
    printk("       flags: 0x%x\n", (unsigned int)si->flags);
    printk("    cmd_line: %s\n",  
           si->cmd_line ? (const char *)si->cmd_line : "NULL");

    /* Set up events. */
    init_events();
    
    /* ENABLE EVENT DELIVERY. This is disabled at start of day. */
    __sti();

    arch_print_info();

    setup_xen_features();

    /* Init memory management. */
    init_mm();

    /* Init time and timers. */
    init_time();

    /* Init the console driver. */
    init_console();

    /* Init grant tables */
    init_gnttab();
    
    /* Init scheduler. */
    init_sched();
 
    /* Init XenBus */
    init_xenbus();

    /* Call (possibly overridden) app_main() */
    app_main(&start_info);

    /* Everything initialised, start idle thread */
    run_idle_thread();
}

void stop_kernel(void)
{
    if (net_dev)
        shutdown_netfront(net_dev);

    if (blk_dev)
        shutdown_blkfront(blk_dev);

    local_irq_disable();

    /* Reset grant tables */
    fini_gnttab();

    /* Reset the console driver. */
    fini_console(NULL);
    /* TODO: record new ring mfn & event in start_info */

    /* Reset XenBus */
    fini_xenbus();

    /* Reset timers */
    fini_time();

    /* Reset memory management. */
    fini_mm();

    /* Reset events. */
    fini_events();

    /* Reset traps */
    trap_fini();

    /* Reset arch details */
    arch_fini();
}

/*
 * do_exit: This is called whenever an IRET fails in entry.S.
 * This will generally be because an application has got itself into
 * a really bad state (probably a bad CS or SS). It must be killed.
 * Of course, minimal OS doesn't have applications :-)
 */

void do_exit(void)
{
    printk("Do_exit called!\n");
    stack_walk();
    for( ;; )
    {
        struct sched_shutdown sched_shutdown = { .reason = SHUTDOWN_crash };
        HYPERVISOR_sched_op(SCHEDOP_shutdown, &sched_shutdown);
    }
}
