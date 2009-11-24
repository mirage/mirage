/* Oki bug report [OKI001](gcc008_1)

        The following program is not executed.
        error messages are as follow.

	illegal trap: 0x12 pc=d000d954
	d000d954 08000240  NOP
 */

#include <stdio.h>
extern double dcall ();

main ()
{
  double d1, d2, d3;
  int i;

  d1 = dcall (1.);
  printf ("d1 = %e\n", d1);

  pass ("double [OKI001]");
  fflush(stdout);
}

double
dcall (d)
     double d;
{
  int Zero = 0;
  return d + Zero;
}


