#include <libgen.h>
#include <string.h>
/*
        path           dirname        basename
        "/usr/lib"     "/usr"         "lib"
        "/usr/"        "/"            "usr"
        "usr"          "."            "usr"
        "/"            "/"            "/"
        "."            "."            "."
        ".."           "."            ".."
        NULL           "."            "."
        ""             "."            "."
*/

static char *dot=".";
#define SLASH '/'
#define EOL (char)0
char *dirname(char *path)
{
  char *c;
  if ( path  == NULL ) return dot;
  for(;;) {
    if ( !(c=strrchr(path,SLASH)) ) return dot; /* no slashes */
    if ( c[1]==EOL && c!=path ) {   /* remove trailing slashes */
      while ( *c==SLASH && c!=path ) *c--=EOL;
      continue;
    }
    if ( c!=path )
      while ( *c==SLASH && c>=path) *c--=EOL; /* slashes in the middle */
    else
      path[1]=EOL;                  /* slash is first symbol */
    return path;
  }
}
