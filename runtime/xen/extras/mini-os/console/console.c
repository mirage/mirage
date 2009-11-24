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
 
#include <mini-os/types.h>
#include <mini-os/wait.h>
#include <mini-os/mm.h>
#include <mini-os/hypervisor.h>
#include <mini-os/events.h>
#include <mini-os/os.h>
#include <mini-os/lib.h>
#include <mini-os/xenbus.h>
#include <xen/io/console.h>


/* Copies all print output to the Xen emergency console apart
   of standard dom0 handled console */
#define USE_XEN_CONSOLE


/* If console not initialised the printk will be sent to xen serial line 
   NOTE: you need to enable verbose in xen/Rules.mk for it to work. */
static int console_initialised = 0;


#ifndef HAVE_LIBC
void xencons_rx(char *buf, unsigned len, struct pt_regs *regs)
{
    if(len > 0)
    {
        /* Just repeat what's written */
        buf[len] = '\0';
        printk("%s", buf);
        
        if(buf[len-1] == '\r')
            printk("\nNo console input handler.\n");
    }
}

void xencons_tx(void)
{
    /* Do nothing, handled by _rx */
}
#endif


void console_print(struct consfront_dev *dev, char *data, int length)
{
    char *curr_char, saved_char;
    char copied_str[length+1];
    char *copied_ptr;
    int part_len;
    int (*ring_send_fn)(struct consfront_dev *dev, const char *data, unsigned length);

    if(!console_initialised)
        ring_send_fn = xencons_ring_send_no_notify;
    else
        ring_send_fn = xencons_ring_send;

    copied_ptr = copied_str;
    memcpy(copied_ptr, data, length);
    for(curr_char = copied_ptr; curr_char < copied_ptr+length-1; curr_char++)
    {
        if(*curr_char == '\n')
        {
            *curr_char = '\r';
            saved_char = *(curr_char+1);
            *(curr_char+1) = '\n';
            part_len = curr_char - copied_ptr + 2;
            ring_send_fn(dev, copied_ptr, part_len);
            *(curr_char+1) = saved_char;
            copied_ptr = curr_char+1;
            length -= part_len - 1;
        }
    }

    if (copied_ptr[length-1] == '\n') {
        copied_ptr[length-1] = '\r';
        copied_ptr[length] = '\n';
        length++;
    }
    
    ring_send_fn(dev, copied_ptr, length);
}

void print(int direct, const char *fmt, va_list args)
{
    static char   buf[1024];
    
    (void)vsnprintf(buf, sizeof(buf), fmt, args);
 
    if(direct)
    {
        (void)HYPERVISOR_console_io(CONSOLEIO_write, strlen(buf), buf);
        return;
    } else {
#ifndef USE_XEN_CONSOLE
    if(!console_initialised)
#endif    
            (void)HYPERVISOR_console_io(CONSOLEIO_write, strlen(buf), buf);
        
        console_print(NULL, buf, strlen(buf));
    }
}

void printk(const char *fmt, ...)
{
    va_list       args;
    va_start(args, fmt);
    print(0, fmt, args);
    va_end(args);        
}

void xprintk(const char *fmt, ...)
{
    va_list       args;
    va_start(args, fmt);
    print(1, fmt, args);
    va_end(args);        
}
void init_console(void)
{   
    printk("Initialising console ... ");
    xencons_ring_init();    
    console_initialised = 1;
    /* This is also required to notify the daemon */
    printk("done.\n");
}

void fini_console(struct consfront_dev *dev)
{
    if (dev) free_consfront(dev);
}
