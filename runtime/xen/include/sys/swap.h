#ifndef _SYS_SWAP_H
#define _SYS_SWAP_H

#include <sys/cdefs.h>

#define SWAP_FLAG_PREFER       0x8000  /* set if swap priority specified */
#define SWAP_FLAG_PRIO_MASK    0x7fff
#define SWAP_FLAG_PRIO_SHIFT   0

#define MAX_SWAPFILES 32

__BEGIN_DECLS

extern int swapon (const char *path, int flags) __THROW;
extern int swapoff (const char *path) __THROW;

__END_DECLS

#endif /* _SYS_SWAP_H */
