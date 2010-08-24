#define _GNU_SOURCE
#include <signal.h>
#include <stdio.h>
#include <string.h>

int main() {
  puts(strsignal(SIGPIPE));
  return 0;
}
