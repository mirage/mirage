#include <assert.h>

#ifdef __dietlibc__
#include <write12.h>
#else
#warning "You are not using dietlibc, using printf instead of __write1"
#include <stdio.h>
#define __write1(x) printf("%s", x)
#endif

#define HELLO "Hello, world!\n"
int main() {
  assert (__write1(HELLO)  == sizeof HELLO -1 );
  
  return 0;
}
