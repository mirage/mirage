/* 
 ****************************************************************************
 * (C) 2006 - Grzegorz Milos - Cambridge University
 ****************************************************************************
 *
 *        File: console.h
 *      Author: Grzegorz Milos
 *     Changes: 
 *              
 *        Date: Mar 2006
 * 
 * Environment: Xen Minimal OS
 * Description: Console interface.
 *
 * Handles console I/O. Defines printk.
 *
 ****************************************************************************
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
#ifndef _LIB_CONSOLE_H_
#define _LIB_CONSOLE_H_

#include <mini-os/os.h>
#include <mini-os/traps.h>
#include <mini-os/types.h>
#include <xen/grant_table.h>
#include <xenbus.h>
#include <xen/io/console.h>
#include <stdarg.h>

struct consfront_dev {
    domid_t dom;

    struct xencons_interface *ring;
    grant_ref_t ring_ref;
    evtchn_port_t evtchn;

    char *nodename;
    char *backend;

    xenbus_event_queue events;

#ifdef HAVE_LIBC
    int fd;
#endif
};



void print(int direct, const char *fmt, va_list args);
void printk(const char *fmt, ...);
void xprintk(const char *fmt, ...);

#define tprintk(_fmt, _args...) printk("[%s] " _fmt, current->name, ##_args) 

void xencons_rx(char *buf, unsigned len, struct pt_regs *regs);
void xencons_tx(void);

void init_console(void);
void console_print(struct consfront_dev *dev, char *data, int length);
void fini_console(struct consfront_dev *dev);

/* Low level functions defined in xencons_ring.c */
extern struct wait_queue_head console_queue;
struct consfront_dev *xencons_ring_init(void);
struct consfront_dev *init_consfront(char *_nodename);
int xencons_ring_send(struct consfront_dev *dev, const char *data, unsigned len);
int xencons_ring_send_no_notify(struct consfront_dev *dev, const char *data, unsigned len);
int xencons_ring_avail(struct consfront_dev *dev);
int xencons_ring_recv(struct consfront_dev *dev, char *data, unsigned len);
void free_consfront(struct consfront_dev *dev);

#endif /* _LIB_CONSOLE_H_ */
