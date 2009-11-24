/*
 *  vga.h
 *
 *  This file is subject to the terms and conditions of the GNU General Public
 *  License.  See the file COPYING in the main directory of this archive
 *  for more details.
 */

#ifndef _XEN_VGA_H
#define _XEN_VGA_H

#include <xen/config.h>

#ifdef CONFIG_VGA
extern struct xen_vga_console_info vga_console_info;
void vga_init(void);
void vga_endboot(void);
extern void (*vga_puts)(const char *);
#else
#define vga_init()    ((void)0)
#define vga_endboot() ((void)0)
#define vga_puts(s)   ((void)0)
#endif

#endif /* _XEN_VGA_H */
