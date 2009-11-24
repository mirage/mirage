/*
 * this file contains misc bug reports from WinBond.
 */
#include <stdio.h>
#include <math.h>

#if unix
#define pass(x)	printf("PASS: %s\n", x);
#define fail(x)	printf("FAIL: %s\n", x);
#endif

/*
    The compare operation is error. Because the constant value 1.0 is
    not correct. It seems compare with 0 in this statement.

HP-UX native:
   dist is 0.301
   PASS: float compare
   *cp = be9a1cac, *cp1 = be9a1cac
   PASS: float multiple 1
   PASS: float multiple 2
   32760 / (-2) = -16380
   PASS: float divide 1
   32760 / (-1) = -32760
   PASS: float divide 1
    These test only pass if the output matches:
    Correct output is
    1.0 = 1.000000E+00, 0.3010 = 3.000000E-01, -1.0 = -1.000000E+0
    1.0 = 1.000000E+00, 0.3010 = 3.010000E-01, -1.0 = -1.000000E+00
    These test only pass if the outut matches:
    Correct output is
    ans = 1.000000E+00, ans1 = 3.010000E-01, ans2 = -1.000000E+00
    ans = 1.000000E+00, ans1 = 3.010000E-01, ans2 = -1.000000E+00


Test run on Oki:

    dist is 0
    PASS: float compare
    *cp = be9a1cac, *cp1 = be9a1cac
    PASS: float multiple 1
    PASS: float multiple 2
    32760 / (-2) = -2147467268
    PASS: float divide 1
    32760 / (-1) = 32760
    PASS: float divide 1
    These test only pass if the output matches:
    Correct output is
    1.0 = 1.000000E+00, 0.3010 = 3.000000E-01, -1.0 = -1.000000E+0
    1.0 = 1.586860E-318, 0.3010 = -1.009091E-303, -1.0 = 5.290504E-315
    These test only pass if the outut matches:
    Correct output is
    ans = 1.000000E+00, ans1 = 3.010000E-01, ans2 = -1.000000E+00
    ans = 4.940656E-324, ans1 = -5.299809E-315, ans2 = 5.290504E-315

 */

main()
{
  float dist = 0.3010;

  printf ("dist is %G\n", dist);
  if ( dist < 1.0 ) {
    pass ("float compare");
  } else {
    fail ("float compare");
  }

  test_1();
  test_2();
  test_3();
  test_4();

  fflush (stdout);
}

/*
 *    *cp = be9a1cac, *cp1 = 00000000
 */
test_1()
{
  float i, ans, ans1;
  unsigned int *cp=&ans, *cp1=&ans1;
  
  i = 0.3010;
  ans = (-1.0) * 0.3010 * 1.0;        /* OK */
  ans1 = (-1.0) * i * 1.0;            /* Disaster */
  printf ("*cp = %08x, *cp1 = %08x\n", *cp, *cp1);

  if (*cp != 0xbe9a1cac) {
    fail ("float multiple 1");
  } else {
    pass ("float multiple 1");
  }

  if (*cp1 != 0xbe9a1cac) {
    fail ("float multiple 2");
  } else {
    pass ("float multiple 2");
  }
}

/*
    Positive integer divide Negative integer may get interesting result.
    For examples:
    EX1: 32760 / (-2) = -2147467268
 */
test_2()
{
  int value, i, j;
  
  i = 32760;
  j = -2;
  value = i / (j);
  printf ("%d / (%d) = %d\n", i, j, value);
  
  if (value != -16380) {
    fail ("float divide 1");
  } else {
    pass ("float divide 1");
  }
}

/*
     EX2: 32760 / (-1) = 32760
 */
test_3()
{
  int value, i, j;
  
  i = 32760;
  j = -1;
  value = i / (j);
  printf ("%d / (%d) = %d\n", i, j, value);

  if (value != -32760) {
    fail ("float divide 1");
  } else {
    pass ("float divide 1");
  }
}

/*
    The data output format %e, %E, %g, %G in printf() can not work.
    Please test the following example:

    1.0 = 1.000000E+00, 0.3010 = 3.009999E-01, -1.0 = -1.000000E+00
    ans = 4.940656E-324, ans1 = -5.299809E-315, ans2 = 5.290504E-315
 */
test_4()
{
  float ans, ans1, ans2;
  
  ans = 1.0;
  ans1 = 0.3010;
  ans2 = -1.0;

  printf ("These test only pass if the output matches:\nCorrect output is\n1.0 = 1.000000E+00, 0.3010 = 3.000000E-01, -1.0 = -1.000000E+0\n");
  printf ("1.0 = %E, 0.3010 = %E, -1.0 = %E\n", 1.0, 0.3010, -1.0);
  printf ("These test only pass if the outut matches:\nCorrect output is\nans = 1.000000E+00, ans1 = 3.010000E-01, ans2 = -1.000000E+00\n");
  printf ("ans = %E, ans1 = %E, ans2 = %E\n", ans, ans1, ans2);
}





