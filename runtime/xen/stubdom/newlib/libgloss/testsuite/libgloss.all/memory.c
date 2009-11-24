/* WinBond bug report

   malloc() returns 0x0.

   test the memory calls. These test sbrk(), which is part of glue.c
   for most architectures.
 */

#include <stdio.h>
#define BUFSIZE 80

main()
{
  char *buf;
  char *tmp;
  char *result;

  /* see if we can get some memory */
  buf = (char *)malloc(BUFSIZE);
  if (buf != 0x0) {
    pass ("malloc");
  } else {
    fail ("malloc");
  }

  /* see if we can realloc it */
  tmp = buf;
  result = (char *)realloc (buf, BUFSIZE+100);
   if ((buf != 0x0) && (result != 0x0)) {
    pass ("realloc");
  } else {
    fail ("realloc");
  }
    
  /* see if we can free it up. FIXME: how to test free ?*/
  free (buf);
  fflush (stdout);
}
