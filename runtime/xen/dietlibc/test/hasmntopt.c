#include <stdio.h>
#include <stdlib.h>
#include <mntent.h>

void die(const char* message) {
  puts(message);
  exit(1);
}

int main() {
  struct mntent me;
  char *c;
  me.mnt_opts="foo,bar=baz,duh";
  if (!(c=hasmntopt(&me,"foo"))) die("hasmntopt did not find foo");
  if (!(c=hasmntopt(&me,"duh"))) die("hasmntopt did not find duh");
  printf("%s\n",hasmntopt(&me,"bar"));
  return 0;
}
