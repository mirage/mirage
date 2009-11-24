#include <stdio.h>

main()
{
  float a,b,c;

  a = 0.11;
  b = 3.12;
  c = a+b;

  printf ("Print float, result with 'f' = %f\n", c);
  printf ("Print float, result with 'e' = %e\n", c);
  printf ("Print float, result with 'E' = %E\n", c);
  printf ("Print float, result with 'g' = %g\n", c);
  printf ("Print float, result with 'G' = %G\n", c);

  pass ("float");
  fflush (stdout);
}

