#ifndef __E820_HEADER
#define __E820_HEADER

/*
 * PC BIOS standard E820 types and structure.
 */
#define E820_RAM          1
#define E820_RESERVED     2
#define E820_ACPI         3
#define E820_NVS          4
#define E820_UNUSABLE     5

struct e820entry {
    uint64_t addr;
    uint64_t size;
    uint32_t type;
} __attribute__((packed));

#define E820MAX	128

struct e820map {
    int nr_map;
    struct e820entry map[E820MAX];
};

extern int e820_all_mapped(u64 start, u64 end, unsigned type);
extern int reserve_e820_ram(struct e820map *e820, uint64_t s, uint64_t e);
extern int e820_change_range_type(
    struct e820map *e820, uint64_t s, uint64_t e,
    uint32_t orig_type, uint32_t new_type);
extern unsigned long init_e820(const char *, struct e820entry *, int *);
extern struct e820map e820;

/* These symbols live in the boot trampoline. */
extern struct e820entry e820map[];
extern int e820nr;
extern unsigned int lowmem_kb, highmem_kb;

#define e820_raw bootsym(e820map)
#define e820_raw_nr bootsym(e820nr)

#endif /*__E820_HEADER*/
