/****************************************************************
 * acm_endian.h 
 * 
 * Copyright (C) 2005 IBM Corporation
 *
 * Author:
 * Stefan Berger <stefanb@watson.ibm.com>
 * 
 * Contributions:
 * Reiner Sailer <sailer@watson.ibm.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 2 of the
 * License.
 *
 * sHype header file defining endian-dependent functions for the
 * big-endian policy interface
 *
 */

#ifndef _ACM_ENDIAN_H
#define _ACM_ENDIAN_H

#include <asm/byteorder.h>

static inline void arrcpy16(u16 *dest, const u16 *src, size_t n)
{
    unsigned int i;
    for ( i = 0; i < n; i++ )
        dest[i] = cpu_to_be16(src[i]);
}

static inline void arrcpy32(u32 *dest, const u32 *src, size_t n)
{
    unsigned int i;
    for ( i = 0; i < n; i++ )
        dest[i] = cpu_to_be32(src[i]);
}

static inline void arrcpy(
    void *dest, const void *src, unsigned int elsize, size_t n)
{
    switch ( elsize )
    {
    case sizeof(u16):
        arrcpy16((u16 *)dest, (u16 *)src, n);
        break;

    case sizeof(u32):
        arrcpy32((u32 *)dest, (u32 *)src, n);
        break;

    default:
        memcpy(dest, src, elsize*n);
    }
}

#endif

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
