#ifndef __MINIOS_PUBLIC_PRIVCMD_H__
#define __MINIOS_PUBLIC_PRIVCMD_H__

#include <sys/types.h>

typedef struct privcmd_hypercall
{
	uint64_t op;
	uint64_t arg[5];
} privcmd_hypercall_t;

typedef struct privcmd_mmap_entry {
	uint64_t mfn;
} privcmd_mmap_entry_t; 

#endif /* __MINIOS_PUBLIC_PRIVCMD_H__ */
