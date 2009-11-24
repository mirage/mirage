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
#include <mini-os/fbfront.h>
#include <mini-os/pcifront.h>
#include <mini-os/fs.h>
#include <mini-os/xmalloc.h>
#include <fcntl.h>
#include <xen/features.h>
#include <xen/version.h>

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

#ifdef BLKTEST_WRITE
static struct blk_req *blk_to_read;
#endif

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

#ifdef BLKTEST_WRITE
static void blk_write_read_completed(struct blkfront_aiocb *aiocb, int ret)
{
    struct blk_req *req = aiocb->data;
    int rand_value;
    int i;
    int *buf;

    if (ret) {
        printk("got error code %d when reading back at offset %ld\n", ret, aiocb->aio_offset);
        free(aiocb->aio_buf);
        free(req);
        return;
    }
    blk_size_read += blk_info.sector_size;
    buf = (int*) aiocb->aio_buf;
    rand_value = req->rand_value;
    for (i = 0; i < blk_info.sector_size / sizeof(int); i++) {
        if (buf[i] != rand_value) {
            printk("bogus data at offset %ld\n", aiocb->aio_offset + i);
            break;
        }
        rand_value *= RAND_MIX;
    }
    free(aiocb->aio_buf);
    free(req);
}

static void blk_write_completed(struct blkfront_aiocb *aiocb, int ret)
{
    struct blk_req *req = aiocb->data;
    if (ret) {
        printk("got error code %d when writing at offset %ld\n", ret, aiocb->aio_offset);
        free(aiocb->aio_buf);
        free(req);
        return;
    }
    blk_size_write += blk_info.sector_size;
    /* Push write check */
    req->next = blk_to_read;
    blk_to_read = req;
}

static void blk_write_sector(uint64_t sector)
{
    struct blk_req *req;
    int rand_value;
    int i;
    int *buf;

    req = blk_alloc_req(sector);
    req->aiocb.aio_cb = blk_write_completed;
    req->rand_value = rand_value = rand();

    buf = (int*) req->aiocb.aio_buf;
    for (i = 0; i < blk_info.sector_size / sizeof(int); i++) {
        buf[i] = rand_value;
        rand_value *= RAND_MIX;
    }

    blkfront_aio_write(&req->aiocb);
}
#endif

static void blkfront_thread(void *p)
{
    time_t lasttime = 0;

    blk_dev = init_blkfront(NULL, &blk_info);
    if (!blk_dev)
        return;

    if (blk_info.info & VDISK_CDROM)
        printk("Block device is a CDROM\n");
    if (blk_info.info & VDISK_REMOVABLE)
        printk("Block device is removable\n");
    if (blk_info.info & VDISK_READONLY)
        printk("Block device is read-only\n");

#ifdef BLKTEST_WRITE
    if (blk_info.mode == O_RDWR) {
        blk_write_sector(0);
        blk_write_sector(blk_info.sectors-1);
    } else
#endif
    {
        blk_read_sector(0);
        blk_read_sector(blk_info.sectors-1);
    }

    while (1) {
        uint64_t sector = rand() % blk_info.sectors;
        struct timeval tv;
#ifdef BLKTEST_WRITE
        if (blk_info.mode == O_RDWR)
            blk_write_sector(sector);
        else
#endif
            blk_read_sector(sector);
        blkfront_aio_poll(blk_dev);
        gettimeofday(&tv, NULL);
        if (tv.tv_sec > lasttime + 10) {
            printk("%llu read, %llu write\n", blk_size_read, blk_size_write);
            lasttime = tv.tv_sec;
        }

#ifdef BLKTEST_WRITE
        while (blk_to_read) {
            struct blk_req *req = blk_to_read;
            blk_to_read = blk_to_read->next;
            req->aiocb.aio_cb = blk_write_read_completed;
            blkfront_aio_read(&req->aiocb);
        }
#endif
    }
}

#define WIDTH 800
#define HEIGHT 600
#define DEPTH 32

static uint32_t *fb;
static int refresh_period = 50;
static struct fbfront_dev *fb_dev;
static struct semaphore fbfront_sem = __SEMAPHORE_INITIALIZER(fbfront_sem, 0);

static void fbfront_drawvert(int x, int y1, int y2, uint32_t color)
{
    int y;
    if (x < 0)
        return;
    if (x >= WIDTH)
        return;
    if (y1 < 0)
        y1 = 0;
    if (y2 >= HEIGHT)
        y2 = HEIGHT-1;
    for (y = y1; y <= y2; y++)
        fb[x + y*WIDTH] ^= color;
}

static void fbfront_drawhoriz(int x1, int x2, int y, uint32_t color)
{
    int x;
    if (y < 0)
        return;
    if (y >= HEIGHT)
        return;
    if (x1 < 0)
        x1 = 0;
    if (x2 >= WIDTH)
        x2 = WIDTH-1;
    for (x = x1; x <= x2; x++)
        fb[x + y*WIDTH] ^= color;
}

static void fbfront_thread(void *p)
{
    size_t line_length = WIDTH * (DEPTH / 8);
    size_t memsize = HEIGHT * line_length;
    unsigned long *mfns;
    int i, n = (memsize + PAGE_SIZE-1) / PAGE_SIZE;

    memsize = n * PAGE_SIZE;
    fb = _xmalloc(memsize, PAGE_SIZE);
    memset(fb, 0, memsize);
    mfns = xmalloc_array(unsigned long, n);
    for (i = 0; i < n; i++)
        mfns[i] = virtual_to_mfn((char *) fb + i * PAGE_SIZE);
    fb_dev = init_fbfront(NULL, mfns, WIDTH, HEIGHT, DEPTH, line_length, n);
    xfree(mfns);
    if (!fb_dev) {
        xfree(fb);
        return;
    }
    up(&fbfront_sem);
}

static void clip_cursor(int *x, int *y)
{
    if (*x < 0)
        *x = 0;
    if (*x >= WIDTH)
        *x = WIDTH - 1;
    if (*y < 0)
        *y = 0;
    if (*y >= HEIGHT)
        *y = HEIGHT - 1;
}

static void refresh_cursor(int new_x, int new_y)
{
    static int old_x = -1, old_y = -1;

    if (!refresh_period)
        return;

    if (old_x != -1 && old_y != -1) {
        fbfront_drawvert(old_x, old_y + 1, old_y + 8, 0xffffffff);
        fbfront_drawhoriz(old_x + 1, old_x + 8, old_y, 0xffffffff);
        fbfront_update(fb_dev, old_x, old_y, 9, 9);
    }
    old_x = new_x;
    old_y = new_y;
    fbfront_drawvert(new_x, new_y + 1, new_y + 8, 0xffffffff);
    fbfront_drawhoriz(new_x + 1, new_x + 8, new_y, 0xffffffff);
    fbfront_update(fb_dev, new_x, new_y, 9, 9);
}

static struct kbdfront_dev *kbd_dev;
static void kbdfront_thread(void *p)
{
    DEFINE_WAIT(w);
    int x = WIDTH / 2, y = HEIGHT / 2, z = 0;

    kbd_dev = init_kbdfront(NULL, 1);
    if (!kbd_dev)
        return;

    down(&fbfront_sem);
    refresh_cursor(x, y);
    while (1) {
        union xenkbd_in_event kbdevent;
        union xenfb_in_event fbevent;
        int sleep = 1;

        add_waiter(w, kbdfront_queue);
        add_waiter(w, fbfront_queue);

        while (kbdfront_receive(kbd_dev, &kbdevent, 1) != 0) {
            sleep = 0;
            switch(kbdevent.type) {
            case XENKBD_TYPE_MOTION:
                printk("motion x:%d y:%d z:%d\n",
                        kbdevent.motion.rel_x,
                        kbdevent.motion.rel_y,
                        kbdevent.motion.rel_z);
                x += kbdevent.motion.rel_x;
                y += kbdevent.motion.rel_y;
                z += kbdevent.motion.rel_z;
                clip_cursor(&x, &y);
                refresh_cursor(x, y);
                break;
            case XENKBD_TYPE_POS:
                printk("pos x:%d y:%d dz:%d\n",
                        kbdevent.pos.abs_x,
                        kbdevent.pos.abs_y,
                        kbdevent.pos.rel_z);
                x = kbdevent.pos.abs_x;
                y = kbdevent.pos.abs_y;
                z = kbdevent.pos.rel_z;
                clip_cursor(&x, &y);
                refresh_cursor(x, y);
                break;
            case XENKBD_TYPE_KEY:
                printk("key %d %s\n",
                        kbdevent.key.keycode,
                        kbdevent.key.pressed ? "pressed" : "released");
                if (kbdevent.key.keycode == BTN_LEFT) {
                    printk("mouse %s at (%d,%d,%d)\n",
                            kbdevent.key.pressed ? "clic" : "release", x, y, z);
                    if (kbdevent.key.pressed) {
                        uint32_t color = rand();
                        fbfront_drawvert(x - 16, y - 16, y + 15, color);
                        fbfront_drawhoriz(x - 16, x + 15, y + 16, color);
                        fbfront_drawvert(x + 16, y - 15, y + 16, color);
                        fbfront_drawhoriz(x - 15, x + 16, y - 16, color);
                        fbfront_update(fb_dev, x - 16, y - 16, 33, 33);
                    }
                } else if (kbdevent.key.keycode == KEY_Q) {
                    struct sched_shutdown sched_shutdown = { .reason = SHUTDOWN_poweroff };
                    HYPERVISOR_sched_op(SCHEDOP_shutdown, &sched_shutdown);
                    do_exit();
                }
                break;
            }
        }
        while (fbfront_receive(fb_dev, &fbevent, 1) != 0) {
            sleep = 0;
            switch(fbevent.type) {
            case XENFB_TYPE_REFRESH_PERIOD:
                refresh_period = fbevent.refresh_period.period;
                printk("refresh period %d\n", refresh_period);
                refresh_cursor(x, y);
                break;
            }
        }
        if (sleep)
            schedule();
    }
}

static struct pcifront_dev *pci_dev;

static void print_pcidev(unsigned int domain, unsigned int bus, unsigned int slot, unsigned int fun)
{
    unsigned int vendor, device, rev, class;

    pcifront_conf_read(pci_dev, domain, bus, slot, fun, 0x00, 2, &vendor);
    pcifront_conf_read(pci_dev, domain, bus, slot, fun, 0x02, 2, &device);
    pcifront_conf_read(pci_dev, domain, bus, slot, fun, 0x08, 1, &rev);
    pcifront_conf_read(pci_dev, domain, bus, slot, fun, 0x0a, 2, &class);

    printk("%04x:%02x:%02x.%02x %04x: %04x:%04x (rev %02x)\n", domain, bus, slot, fun, class, vendor, device, rev);
}

static void pcifront_thread(void *p)
{
    pci_dev = init_pcifront(NULL);
    if (!pci_dev)
        return;
    printk("PCI devices:\n");
    pcifront_scan(pci_dev, print_pcidev);
}

static void fs_thread(void *p)
{
    init_fs_frontend();
}

/* This should be overridden by the application we are linked against. */
__attribute__((weak)) int app_main(start_info_t *si)
{
    printk("Dummy main: start_info=%p\n", si);
    create_thread("xenbus_tester", xenbus_tester, si);
    create_thread("periodic_thread", periodic_thread, si);
    create_thread("netfront", netfront_thread, si);
    create_thread("blkfront", blkfront_thread, si);
    create_thread("fbfront", fbfront_thread, si);
    create_thread("kbdfront", kbdfront_thread, si);
    create_thread("pcifront", pcifront_thread, si);
    create_thread("fs-frontend", fs_thread, si);
    return 0;
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
    printk("Xen Minimal OS!\n");
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

    if (fb_dev)
        shutdown_fbfront(fb_dev);

    if (kbd_dev)
        shutdown_kbdfront(kbd_dev);

    if (pci_dev)
        shutdown_pcifront(pci_dev);

    /* TODO: fs import */

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
