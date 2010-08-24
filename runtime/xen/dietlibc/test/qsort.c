#define _BSD_SOURCE
#define _GNU_SOURCE
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <inttypes.h>

int compar(const void* a,const void* b) {
  const unsigned char* A=*(void **)a;
  const unsigned char* B=*(void **)b;
  int l;
  while (l=(*A-*B)) {
    if (!*A) return 0;
    ++A; ++B;
  }
  return l;
}

char** A;
unsigned long a,n;

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

int main() {
  char buf[2048];
  unsigned long x,y;
  while (fgets(buf,sizeof(buf),stdin)) {
    buf[sizeof(buf)-1]=0;
    if (n==a) {
      a+=512;
      A=realloc(A,a*sizeof(*A));
      if (!A) {
	printf("realloc to %lu elements failed!\n",a);
	return 1;
      }
    }
    if (!(A[n]=strdup(buf))) {
      printf("strdup failed!\n");
      return 1;
    }
    ++n;
  }
  printf("sorting %lu elements...\n",n);
  {
    char** B=malloc(n*sizeof(*A));
    if (!B) {
      printf("could not alloc %lu bytes!\n",n*sizeof(*A));
      return 1;
    }
    memcpy(B,A,n*sizeof(*A));
    qsort(A,n,sizeof(*A),compar);
    memcpy(A,B,n*sizeof(*A));
  }
  RDTSC(x);
  qsort(A,n,sizeof(*A),compar);
  RDTSC(y);
  printf("qsort took %lu cycles.\n",y-x);
  {
    unsigned int i;
    for (i=0; i+1<n; ++i) {
      if (compar(&A[i],&A[i+1])>0) {
	printf(" -> not sorted!\n");
	return 1;
      }
    }
  }
  return 0;
}
