#include <string.h>
#include <libgen.h>

/*
       path           dirname        basename
       "/usr/lib"     "/usr"         "lib"
       "/usr/"        "/"            "usr"
       "usr"          "."            "usr"
       "/"            "/"            "/"
       "."            "."            "."
       ".."           "."            ".."
*/

char *basename(char *path) {
  char *c;
again:
  if (!(c=strrchr(path,'/'))) return path;
  if (c[1]==0) {
    if (c == path)
      return c;
    else {
      *c=0;
      goto again;
    }
  }
  return c+1;
}
