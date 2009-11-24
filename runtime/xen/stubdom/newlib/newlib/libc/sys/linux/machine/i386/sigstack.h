#ifndef _SIGSTACK_H

#define _SIGSTACK_H

#include <stddef.h>

typedef struct sigaltstack
  {
    void *ss_sp;
    int ss_flags;
    size_t ss_size;
  } stack_t;

#endif /* _SIGSTACK_H */
