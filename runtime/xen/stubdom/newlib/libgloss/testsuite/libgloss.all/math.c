/* Oki bug report [OKI004](gcc005)

          The following computation is no work.
        -1 / 1 => 1 (correct -1)
        -1 % 2 => 1 (correct -1)
 */

#include <stdio.h>

main ()
{
        long l1, l2, l6;
        auto long l3;
        long oza1, oza2, oza;

        l1 = 1;
        l2 = 2;
        l3 = -1;
        l6 = 6;

        /*** test 1 ***/
        oza = ((l3 / ((l1)--)) | (l6 <= (l3 % l2)));
	printf ("test 1 has a result of %d.\n", oza);
	if (oza != -1)
	  fail ("divide test [OKI004]");
	else
	  pass ("divide test [OKI004]");

        l1 = 1;
        /*** test 2 ***/
        oza1 = (l3 / ((l1)--));
        oza2 = (l6 <= (l3 % l2));
        oza = oza1 | oza2;
	
	printf ("test 2 has a result of %d.\n", oza);
	if (oza != -1)
	  fail ("modulos test [OKI004]");
	else
	  pass ("modulos test [OKI004]");
	fflush (stdout);

	test_1();
}

/*
      32760 / (1) = 32760
      32760 / (-1) = 32760    -------> ERROR, same as you said.
      32760 / (2) = 16380
      32760 / (-2) = -2147467268 ----> ERROR
      32760 / (3) = 10920
      32760 / (-3) = -1431644845 ----> ERROR
      32760 / (4) = 8190
      32760 / (-4) = -8190
 */
test_1()
{
  int value, i, j;

  i = 32760;
  j = 1;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  j = -1;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  
  j = 2;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  j = -2;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  
  j = 3;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  j = -3;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  
  j = 4;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
  j = -4;
  value = i / (j);
  printf ("%d / (%d) =  %d\n", i, j, value);
}

