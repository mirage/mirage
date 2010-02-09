#include <stdio.h>
#include <stdlib.h>
#include <fnmatch.h>

void die(const char* message) {
  puts(message);
  exit(1);
}

int main() {
  if (fnmatch("*.c","foo.c",0)) die("fnmatch did not match *.c to foo.c");
  if (fnmatch("*.c",".c",0)) die("fnmatch did not match *.c to .c");
  if (!fnmatch("*.a","foo.c",0)) die("fnmatch matched *.a to foo.c");
  if (fnmatch("*.c",".foo.c",0)) die("fnmatch did not match *.c to .foo.c");
  if (!fnmatch("*.c",".foo.c",FNM_PERIOD)) die("FNM_PERIOD does not work 1");
  if (fnmatch("*.c","foo.c",FNM_PERIOD)) die("FNM_PERIOD does not work 2");
  if (!fnmatch("a\\*.c","a*.c",FNM_NOESCAPE)) die("FNM_NOESCAPE does not work");
  if (!fnmatch("a\\*.c","ax.c",0)) die("Escaping does not work");
  if (fnmatch("a[xy].c","ax.c",0)) die("Character classes don't work");
  if (fnmatch("a[^y].c","ax.c",0)) puts("Inverse character classes don't work (that's OK with POSIX)");
  if (!fnmatch("a[a/z]*.c","a/x.c",FNM_PATHNAME)) die("FNM_PATHNAME does not work 1");
  if (fnmatch("a/*.c","a/x.c",FNM_PATHNAME)) die("FNM_PATHNAME does not work 2");
  if (!fnmatch("a*.c","a/x.c",FNM_PATHNAME)) die("FNM_PATHNAME does not work 3");
  if (fnmatch("*/foo","/foo",FNM_PATHNAME)) die("FNM_PATHNAME does not work 3");
#ifdef FNM_CASEFOLD
  if (fnmatch("*.c","foo.C",FNM_CASEFOLD)) die("FNM_CASEFOLD does not work");
#endif
  if (fnmatch("-O[01]","-O1",0)) die("fnmatch did not match -O[01] to -O1");
  return 0;
}
