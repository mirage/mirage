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
#include <mini-os/x86/os.h>
#include <mini-os/lib.h>
#include <mini-os/xenbus.h>
#include <xen/io/console.h>


void console_print(char *data, int length)
{
    (void)HYPERVISOR_console_io(CONSOLEIO_write, length, data);
}

void print(const char *fmt, va_list args)
{
    static char   buf[1024];
    
    (void)vsnprintf(buf, sizeof(buf), fmt, args);

    (void)HYPERVISOR_console_io(CONSOLEIO_write, strlen(buf), buf);
}

void printk(const char *fmt, ...)
{
    va_list       args;
    va_start(args, fmt);
    print(fmt, args);
    va_end(args);        
}

void xprintk(const char *fmt, ...)
{
    va_list       args;
    va_start(args, fmt);
    print(fmt, args);
    va_end(args);        
}
