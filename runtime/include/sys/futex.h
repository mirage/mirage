#ifndef _SYS_FUTEX_H
#define _SYS_FUTEX_H

#include <sys/time.h>

enum {
  FUTEX_WAIT=0,
  FUTEX_WAKE=1,
  FUTEX_FD=2,
  FUTEX_REQUEUE=3,
  FUTEX_CMP_REQUEUE=4,
};

long futex(int* uaddr,int op,int val,const struct timespec* timeout,int* uaddr2,int val3);

#endif
