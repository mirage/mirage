/*
 * Copyright (C) 2007 Advanced Micro Devices, Inc.
 * Author: Leo Duran <leo.duran@amd.com>
 * Author: Wei Wang <wei.wang2@amd.com> - adapted to xen
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
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 */

#ifndef _ASM_X86_64_AMD_IOMMU_ACPI_H
#define _ASM_X86_64_AMD_IOMMU_ACPI_H

#include <xen/acpi.h>

/* I/O Virtualization Reporting Structure */
#define AMD_IOMMU_ACPI_IVRS_SIG            "IVRS"
#define AMD_IOMMU_ACPI_IVHD_TYPE       0x10
#define AMD_IOMMU_ACPI_IVMD_ALL_TYPE       0x20
#define AMD_IOMMU_ACPI_IVMD_ONE_TYPE       0x21
#define AMD_IOMMU_ACPI_IVMD_RANGE_TYPE     0x22
#define AMD_IOMMU_ACPI_IVMD_IOMMU_TYPE     0x23

/* 4-byte Device Entries */
#define AMD_IOMMU_ACPI_IVHD_DEV_U32_PAD        0
#define AMD_IOMMU_ACPI_IVHD_DEV_SELECT     2
#define AMD_IOMMU_ACPI_IVHD_DEV_RANGE_START    3
#define AMD_IOMMU_ACPI_IVHD_DEV_RANGE_END  4

/* 8-byte Device Entries */
#define AMD_IOMMU_ACPI_IVHD_DEV_U64_PAD        64
#define AMD_IOMMU_ACPI_IVHD_DEV_ALIAS_SELECT   66
#define AMD_IOMMU_ACPI_IVHD_DEV_ALIAS_RANGE    67
#define AMD_IOMMU_ACPI_IVHD_DEV_EXT_SELECT 70
#define AMD_IOMMU_ACPI_IVHD_DEV_EXT_RANGE  71
#define AMD_IOMMU_ACPI_IVHD_DEV_SPECIAL    72

/* IVHD IOMMU Flags */
#define AMD_IOMMU_ACPI_COHERENT_MASK       0x20
#define AMD_IOMMU_ACPI_COHERENT_SHIFT      5
#define AMD_IOMMU_ACPI_IOTLB_SUP_MASK      0x10
#define AMD_IOMMU_ACPI_IOTLB_SUP_SHIFT     4
#define AMD_IOMMU_ACPI_ISOC_MASK       0x08
#define AMD_IOMMU_ACPI_ISOC_SHIFT      3
#define AMD_IOMMU_ACPI_RES_PASS_PW_MASK        0x04
#define AMD_IOMMU_ACPI_RES_PASS_PW_SHIFT   2
#define AMD_IOMMU_ACPI_PASS_PW_MASK        0x02
#define AMD_IOMMU_ACPI_PASS_PW_SHIFT       1
#define AMD_IOMMU_ACPI_HT_TUN_ENB_MASK     0x01
#define AMD_IOMMU_ACPI_HT_TUN_ENB_SHIFT        0

/* IVHD Device Flags */
#define AMD_IOMMU_ACPI_LINT1_PASS_MASK     0x80
#define AMD_IOMMU_ACPI_LINT1_PASS_SHIFT        7
#define AMD_IOMMU_ACPI_LINT0_PASS_MASK     0x40
#define AMD_IOMMU_ACPI_LINT0_PASS_SHIFT        6
#define AMD_IOMMU_ACPI_SYS_MGT_MASK        0x30
#define AMD_IOMMU_ACPI_SYS_MGT_SHIFT       4
#define AMD_IOMMU_ACPI_NMI_PASS_MASK       0x04
#define AMD_IOMMU_ACPI_NMI_PASS_SHIFT      2
#define AMD_IOMMU_ACPI_EINT_PASS_MASK      0x02
#define AMD_IOMMU_ACPI_EINT_PASS_SHIFT     1
#define AMD_IOMMU_ACPI_INIT_PASS_MASK      0x01
#define AMD_IOMMU_ACPI_INIT_PASS_SHIFT     0

/* IVHD Device Extended Flags */
#define AMD_IOMMU_ACPI_ATS_DISABLED_MASK   0x80000000
#define AMD_IOMMU_ACPI_ATS_DISABLED_SHIFT  31

/* IVMD Device Flags */
#define AMD_IOMMU_ACPI_EXCLUSION_RANGE_MASK    0x08
#define AMD_IOMMU_ACPI_EXCLUSION_RANGE_SHIFT   3
#define AMD_IOMMU_ACPI_IW_PERMISSION_MASK  0x04
#define AMD_IOMMU_ACPI_IW_PERMISSION_SHIFT 2
#define AMD_IOMMU_ACPI_IR_PERMISSION_MASK  0x02
#define AMD_IOMMU_ACPI_IR_PERMISSION_SHIFT 1
#define AMD_IOMMU_ACPI_UNITY_MAPPING_MASK  0x01
#define AMD_IOMMU_ACPI_UNITY_MAPPING_SHIFT 0

#define ACPI_OEM_ID_SIZE                6
#define ACPI_OEM_TABLE_ID_SIZE          8

#pragma pack(1)
struct acpi_ivrs_table_header {
   struct acpi_table_header acpi_header;
   u32 io_info;
   u8  reserved[8];
};

struct acpi_ivrs_block_header {
   u8  type;
   u8  flags;
   u16 length;
   u16 dev_id;
};

struct acpi_ivhd_block_header {
   struct acpi_ivrs_block_header header;
   u16 cap_offset;
   u64 mmio_base;
   u16 pci_segment;
   u16 iommu_info;
   u8 reserved[4];
};

struct acpi_ivhd_device_header {
   u8  type;
   u16 dev_id;
   u8  flags;
};

struct acpi_ivhd_device_trailer {
   u8  type;
   u16 dev_id;
   u8  reserved;
};

struct acpi_ivhd_device_range {
   struct acpi_ivhd_device_header header;
   struct acpi_ivhd_device_trailer trailer;
};

struct acpi_ivhd_device_alias {
   struct acpi_ivhd_device_header header;
   u8  reserved1;
   u16 dev_id;
   u8  reserved2;
};

struct acpi_ivhd_device_alias_range {
   struct acpi_ivhd_device_alias alias;
   struct acpi_ivhd_device_trailer trailer;
};

struct acpi_ivhd_device_extended {
   struct acpi_ivhd_device_header header;
   u32 ext_flags;
};

struct acpi_ivhd_device_extended_range {
   struct acpi_ivhd_device_extended extended;
   struct acpi_ivhd_device_trailer trailer;
};

struct acpi_ivhd_device_special {
   struct acpi_ivhd_device_header header;
   u8  handle;
   u16 dev_id;
   u8  variety;
};

union acpi_ivhd_device {
   struct acpi_ivhd_device_header header;
   struct acpi_ivhd_device_range range;
   struct acpi_ivhd_device_alias alias;
   struct acpi_ivhd_device_alias_range alias_range;
   struct acpi_ivhd_device_extended extended;
   struct acpi_ivhd_device_extended_range extended_range;
   struct acpi_ivhd_device_special special;
};

struct acpi_ivmd_block_header {
   struct acpi_ivrs_block_header header;
   union {
       u16 last_dev_id;
       u16 cap_offset;
       u16 reserved1;
   };
   u64 reserved2;
   u64 start_addr;
   u64 mem_length;
};
#pragma pack()

#endif /* _ASM_X86_64_AMD_IOMMU_ACPI_H */
