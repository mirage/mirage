#define _BSD_SOURCE
#include <unistd.h>
#include <stdio.h>

int main() {
  char* c;
  while ((c=getusershell()))
    puts(c);
  return 0;
}
