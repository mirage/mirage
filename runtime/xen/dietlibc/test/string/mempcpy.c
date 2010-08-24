#define _GNU_SOURCE
#include <string.h>
#include <assert.h>
#include <sys/param.h>

int main() {
  char test[100]="blubber";

  assert(mempcpy(test,"foo",3)==test+3 && !strcmp(test,"foobber"));
  assert(mempcpy(test,"foo",4)==test+4 && !strcmp(test,"foo"));

  assert(stpcpy(test,"foo")==test+3 && !strcmp(test,"foo"));

  stpncpy(test,"bar",2);
  assert(stpncpy(test,"bar",2)==test+2 && !strcmp(test,"bao"));
  assert(stpncpy(test,"xyz",6)==test+3 && !memcmp(test,"xyz\0\0\0",6));

  return 0;
}
