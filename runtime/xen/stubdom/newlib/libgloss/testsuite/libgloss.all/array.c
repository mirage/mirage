/* WinBond bug report

   this is a compile test. At one time static arrays over 500 elements
   didn't work. We'll test both global and local array. If it compiles at
   all, it it passes.
 */

#include <stdio.h>
static short aa[64][64];
static int bb[500];

main() 
{
  static short cc[64][64];
  static int dd[500];
  pass ("large arrays");
  fflush(stdout);
}
