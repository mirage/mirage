/******************************************************************************
 * memmap.h
 *
 * Copyright (c) 2008 Tristan Gingold <tgingold AT free fr>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#ifndef __XEN_PUBLIC_HVM_MEMMAP_IA64_H__
#define __XEN_PUBLIC_HVM_MEMMAP_IA64_H__

#define MEM_G  (1UL << 30)
#define MEM_M  (1UL << 20)
#define MEM_K  (1UL << 10)

/* Guest physical address of IO ports space.  */
#define MMIO_START  (3 * MEM_G)
#define MMIO_SIZE   (512 * MEM_M)

#define VGA_IO_START  0xA0000UL
#define VGA_IO_SIZE   0x20000

#define LEGACY_IO_START  (MMIO_START + MMIO_SIZE)
#define LEGACY_IO_SIZE   (64 * MEM_M)

#define IO_PAGE_START  (LEGACY_IO_START + LEGACY_IO_SIZE)
#define IO_PAGE_SIZE   XEN_PAGE_SIZE

#define STORE_PAGE_START  (IO_PAGE_START + IO_PAGE_SIZE)
#define STORE_PAGE_SIZE   XEN_PAGE_SIZE

#define BUFFER_IO_PAGE_START  (STORE_PAGE_START + STORE_PAGE_SIZE)
#define BUFFER_IO_PAGE_SIZE   XEN_PAGE_SIZE

#define BUFFER_PIO_PAGE_START  (BUFFER_IO_PAGE_START + BUFFER_IO_PAGE_SIZE)
#define BUFFER_PIO_PAGE_SIZE   XEN_PAGE_SIZE

#define IO_SAPIC_START  0xfec00000UL
#define IO_SAPIC_SIZE   0x100000

#define PIB_START  0xfee00000UL
#define PIB_SIZE   0x200000

#define GFW_START  (4 * MEM_G - 16 * MEM_M)
#define GFW_SIZE   (16 * MEM_M)

/* domVTI */
#define GPFN_FRAME_BUFFER  0x1 /* VGA framebuffer */
#define GPFN_LOW_MMIO      0x2 /* Low MMIO range */
#define GPFN_PIB           0x3 /* PIB base */
#define GPFN_IOSAPIC       0x4 /* IOSAPIC base */
#define GPFN_LEGACY_IO     0x5 /* Legacy I/O base */
#define GPFN_HIGH_MMIO     0x6 /* High MMIO range */

/* Nvram belongs to GFW memory space  */
#define NVRAM_SIZE   (MEM_K * 64)
#define NVRAM_START  (GFW_START + 10 * MEM_M)

#define NVRAM_VALID_SIG  0x4650494e45584948 /* "HIXENIPF" */
struct nvram_save_addr {
    unsigned long addr;
    unsigned long signature;
};

#endif /* __XEN_PUBLIC_HVM_MEMMAP_IA64_H__ */

/*
 * Local variables:
 * mode: C
 * c-set-style: "BSD"
 * c-basic-offset: 4
 * tab-width: 4
 * indent-tabs-mode: nil
 * End:
 */
