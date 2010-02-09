#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <sys/wait.h>

#if defined (__i386__)
#define RDTSC(dst) asm volatile ("rdtsc" : "=A" (dst))
#elif defined (__x86_64__)
#define RDTSC(dst) do {                                                        \
  uint32_t l, h;                                                               \
  asm volatile ("rdtsc" : "=a" (l), "=d" (h)); \
  dst = (((uint64_t)h) << 32) | l;                             \
} while (0)
#else
#error "Unimplemented rdtsc"
#endif

extern char **environ;

int main(int argc,char* argv[]) {
  uint64_t a,b;
  RDTSC(a);
  if (!fork()) { execve(argv[1],argv+1,environ); exit(1); }
  wait(0);
  RDTSC(b);
  printf("%llu cycles\n",b-a);

  return 0;
}
