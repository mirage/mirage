/******************************************************************************
 *
 * Name: aclinux.h - OS specific defines, etc.
 *
 *****************************************************************************/

/*
 * Copyright (C) 2000 - 2007, R. Byron Moore
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions, and the following disclaimer,
 *    without modification.
 * 2. Redistributions in binary form must reproduce at minimum a disclaimer
 *    substantially similar to the "NO WARRANTY" disclaimer below
 *    ("Disclaimer") and any redistribution must be conditioned upon
 *    including a substantially similar Disclaimer requirement for further
 *    binary redistribution.
 * 3. Neither the names of the above-listed copyright holders nor the names
 *    of any contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * Alternatively, this software may be distributed under the terms of the
 * GNU General Public License ("GPL") version 2 as published by the Free
 * Software Foundation.
 *
 * NO WARRANTY
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDERS OR CONTRIBUTORS BE LIABLE FOR SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGES.
 */

#ifndef __ACLINUX_H__
#define __ACLINUX_H__

#define ACPI_USE_SYSTEM_CLIBRARY
#define ACPI_USE_DO_WHILE_0

#include <xen/config.h>
#include <xen/cache.h>
#include <xen/string.h>
#include <xen/kernel.h>
#include <xen/ctype.h>
#include <xen/spinlock.h>
#include <asm/system.h>
#include <asm/atomic.h>
#include <asm/div64.h>
#include <asm/acpi.h>
#include <asm/current.h>

/* Host-dependent types and defines */

#define ACPI_MACHINE_WIDTH          BITS_PER_LONG
#define acpi_cache_t                        void /*struct kmem_cache*/
#define acpi_spinlock                   spinlock_t *
#define ACPI_EXPORT_SYMBOL(symbol)  EXPORT_SYMBOL(symbol);
#define strtoul                     simple_strtoul

/* Full namespace pathname length limit - arbitrary */
#define ACPI_PATHNAME_MAX              256

#include "acgcc.h"

#define acpi_cpu_flags unsigned long

#define acpi_thread_id struct vcpu *

#define ACPI_ALLOCATE(a)	xmalloc_bytes(a)
#define ACPI_ALLOCATE_ZEROED(a)	({              \
    void *p = xmalloc_bytes(a);                 \
    if ( p ) memset(p, 0, a);                   \
    p; })
#define ACPI_FREE(a)		xfree(a)

#endif				/* __ACLINUX_H__ */
