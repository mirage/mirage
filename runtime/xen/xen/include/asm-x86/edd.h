/******************************************************************************
 * edd.h
 * 
 * Copyright (C) 2002, 2003, 2004 Dell Inc.
 * by Matt Domsch <Matt_Domsch@dell.com>
 *
 * structures and definitions for the int 13h, ax={41,48}h
 * BIOS Enhanced Disk Drive Services
 * This is based on the T13 group document D1572 Revision 0 (August 14 2002)
 * available at http://www.t13.org/docs2002/d1572r0.pdf.  It is
 * very similar to D1484 Revision 3 http://www.t13.org/docs2002/d1484r3.pdf
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License v2.0 as published by
 * the Free Software Foundation
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef __XEN_EDD_H__
#define __XEN_EDD_H__

struct edd_info {
    /* Int13, Fn48: Check Extensions Present. */
    u8 device;                   /* %dl: device */
    u8 version;                  /* %ah: major version */
    u16 interface_support;       /* %cx: interface support bitmap */
    /* Int13, Fn08: Legacy Get Device Parameters. */
    u16 legacy_max_cylinder;     /* %cl[7:6]:%ch: maximum cylinder number */
    u8 legacy_max_head;          /* %dh: maximum head number */
    u8 legacy_sectors_per_track; /* %cl[5:0]: maximum sector number */
    /* Int13, Fn41: Get Device Parameters (as filled into %ds:%esi). */
    struct {
        u16 length;
        u8 data[72];
    } edd_device_params;
} __attribute__ ((packed));

struct mbr_signature {
    u8 device;
    u8 pad[3];
    u32 signature;
} __attribute__ ((packed));

/* These all reside in the boot trampoline. Access via bootsym(). */
extern struct mbr_signature boot_mbr_signature[];
extern u8 boot_mbr_signature_nr;
extern struct edd_info boot_edd_info[];
extern u8 boot_edd_info_nr;

#endif /* __XEN_EDD_H__ */
