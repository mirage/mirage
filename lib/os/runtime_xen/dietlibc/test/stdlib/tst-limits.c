/* It is important that this comes first to not hide effects introduced
   by other headers.  */
#include <limits.h>

#include <inttypes.h>
#include <stdio.h>

static long long int
bitval (int bits)
{
  long long int val = 0;
  while (bits-- > 0)
    val |= 1ll << bits;
  return val;
}


int
main (void)
{
  int result = 0;

#define TEST(name, format, expected) \
  if (expected != name ) \
  fprintf (stderr, "%-12s expected = %-20" format "  actual = %" format "\n",	      \
	  #name ":", expected, name);					      \
  result |= name != expected

  /* The limits from ISO C99.  */

  /* We cannot support anything but 8-bit chars.  */
  TEST (CHAR_BIT, "d", 8);
  TEST (SCHAR_MIN, "d", -128);
  TEST (SCHAR_MAX, "d", 127);
  TEST (UCHAR_MAX, "d", 255);

  TEST (SHRT_MIN, "d", -(1 << (sizeof (short int) * CHAR_BIT - 1)));
  TEST (SHRT_MAX, "d", (1 << (sizeof (short int) * CHAR_BIT - 1)) - 1);
  TEST (USHRT_MAX, "d", (1 << sizeof (short int) * CHAR_BIT) - 1);

  TEST (INT_MIN, "d", (int) -bitval (sizeof (int) * CHAR_BIT - 1) - 1);
  TEST (INT_MAX, "d", (int) bitval (sizeof (int) * CHAR_BIT - 1));
  TEST (UINT_MAX, "u",
	(unsigned int) bitval (sizeof (unsigned int) * CHAR_BIT));

  TEST (LONG_MIN, "ld",
	(long int) -bitval (sizeof (long int) * CHAR_BIT - 1) - 1);
  TEST (LONG_MAX, "ld", (long int) bitval (sizeof (long int) * CHAR_BIT - 1));
  TEST (ULONG_MAX, "lu",
	(unsigned long int) bitval (sizeof (unsigned long int) * CHAR_BIT));
#ifdef __dietlibc__ /* tst-limits.c:54: `LLONG_MIN' undeclared (first use in this function).   Great.*/
  TEST (LLONG_MIN, "lld", -bitval (sizeof (long long int) * CHAR_BIT - 1) - 1);
  TEST (LLONG_MAX, "lld", bitval (sizeof (long long int) * CHAR_BIT - 1));
  TEST (ULLONG_MAX, "llu",
	(unsigned long long int) bitval (sizeof (unsigned long long int)
					 * CHAR_BIT));
#endif					 

  /* Values from POSIX and Unix.  */
#ifdef PAGESIZE
  TEST (PAGESIZE, "d", getpagesize ());
#elif PAGE_SIZE
  TEST (PAGE_SIZE, "d", getpagesize ());
#endif


/*  not defined in dietlibc
    TEST (WORD_BIT, "zd", sizeof (int) * CHAR_BIT);
/   TEST (LONG_BIT, "zd", sizeof (long int) * CHAR_BIT); */

  if (!result) fprintf(stdout, "OK\n");
  return result;
}
