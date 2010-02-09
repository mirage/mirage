#include <unistd.h>

extern int __libc_brk(void *end_data_segment);

extern void* __curbrk;

void* __libc_sbrk(ptrdiff_t increment);
void* __libc_sbrk(ptrdiff_t increment) {
  void* oldbrk;
  if (__curbrk==0)
    if (__libc_brk(0) < 0)
      return (void*)-1;
  if (increment==0)
    return __curbrk;
  oldbrk=__curbrk;
  if (__libc_brk((char*)oldbrk+increment)<0)
    return (void*)-1;
  return oldbrk;
}

void* sbrk (ptrdiff_t increment) __attribute__((weak,alias("__libc_sbrk")));
