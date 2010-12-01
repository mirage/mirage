#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void die(const char* message) {
  puts(message);
  exit(1);
}

int main() {
  char buf[100]="fnord";
  strncat(buf,"foo",0);
  if (strcmp(buf,"fnord")) die("strncat did not work for length 0");
  strncat(buf,"foo",2);
  if (strcmp(buf,"fnordfo")) die("strncat did not copy n bytes");
  return 0;
}
