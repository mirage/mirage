#include <unistd.h>

extern void* __diet_brk(void *end_data_segment);

void* __curbrk=0;

int __libc_brk(void *end_data_segment);

int __libc_brk(void *end_data_segment) {
  return ((__curbrk=__diet_brk(end_data_segment))==(void*)-1?-1:0);
}

int brk(void *end_data_segment) __attribute__((weak,alias("__libc_brk")));
