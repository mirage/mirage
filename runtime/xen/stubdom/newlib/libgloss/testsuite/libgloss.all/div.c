/* WinBond bug report

   Please don't use "gcc -O3 -S hello.c" command, because it
   will optimize "i/5" to be "2" in compile time.

 */

#include <stdio.h>
#define TESTSEED 10

main ()
{
  int    a1,b1,c1;
  long   a2,b2,c2;
  double a3,b3,c3;
  float  a4,b4,c4;
  char   buf[20];

  /* integer tests */
  for (a1 = 1; a1 < 16; a1++) {
    b1 = TESTSEED/a1;
    c1 = TESTSEED%a1;
    printf ("%d/%d = %d, ^ = %d\n", TESTSEED, a1, b1, c1);
    if ((c1 + (a1 * b1)) == TESTSEED) {
      sprintf (buf, "div %d by %d", TESTSEED, a1);
      pass (buf);      
    } else {
      sprintf (buf, "div %d by %d", TESTSEED, a1);
      fail (buf);
    }
    fflush (stdout);
  }
}


