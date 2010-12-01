#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void die(const char* message) {
  puts(message);
  exit(1);
}

int main() {
  char buf[100]="fnord";
  char buf2[100]="fnort";
  if (strcmp(buf,buf)) die("strcmp said a != a");
  if (strcmp(buf,buf2)>=0) die("strcmp said fnord > fnort");
  if (strcmp(buf2,buf)<=0) die("strcmp said fnort < fnord");
  if (strcmp(buf+1,buf2+1)>=0) die("unaligned strcmp is broken 1");
  if (strcmp(buf+2,buf2+2)>=0) die("unaligned strcmp is broken 2");
  if (strcmp(buf+3,buf2+3)>=0) die("unaligned strcmp is broken 3");
  if (strcmp("mäh","meh")<0) die("strcmp uses signed arithmetic");
  if (strcmp("foo","foobar")>=0) die("prefix handling broken in strcmp 1");
  if (strcmp("foobar","foo")<=0) die("prefix handling broken in strcmp 2");
  return 0;
}
