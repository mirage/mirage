#ifndef __XC_E820_H__
#define __XC_E820_H__

#include <xen/hvm/e820.h>

/*
 * PC BIOS standard E820 types and structure.
 */
#define E820_RAM          1
#define E820_RESERVED     2
#define E820_ACPI         3
#define E820_NVS          4

struct e820entry {
    uint64_t addr;
    uint64_t size;
    uint32_t type;
} __attribute__((packed));

#endif /* __XC_E820_H__ */
