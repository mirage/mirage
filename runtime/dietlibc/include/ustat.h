#ifndef _USTAT_H
#define _USTAT_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

struct ustat {
#if defined(__mips__) || (defined(__sparc__) && !defined(__arch64__))
  long f_tfree; /* should be daddr_t f_tfree */
#else
  int f_tfree; /* should be daddr_t f_tfree */
#endif
  unsigned long f_tinode;  /* should be ino_t f_tinode */
  char f_fname[6];
  char f_fpack[6];
};

int ustat(dev_t dev, struct ustat* ubuf) __THROW __attribute_dontuse__;

__END_DECLS

#endif

