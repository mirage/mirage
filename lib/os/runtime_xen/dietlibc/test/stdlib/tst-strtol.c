/* My bet is this was written by Chris Torek.
   I reformatted and ansidecl-ized it, and tweaked it a little.  */

#include <ctype.h>
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

struct ltest
  {
    const char *str;		/* Convert this.  */
    unsigned long int expect;	/* To get this.  */
    int base;			/* Use this base.  */
    char left;			/* With this left over.  */
    int err;			/* And this in errno.  */
  };
static const struct ltest tests[] =
  {
  /* First, signed numbers:  */
  /* simple... */
  {"123", 123, 0, 0, 0},
  {"+123", 123, 0, 0, 0},
  {"  123", 123, 0, 0, 0},
  {" 123 ", 123, 0, ' ', 0},
  {"   -17", -17, 0, 0, 0},

  /* implicit base... */
  {"0123", 0123, 0, 0, 0},
  {"0123a", 0123, 0, 'a', 0},
  {"01239", 0123, 0, '9', 0},
  {"0x123", 0x123, 0, 0, 0},
  {"-0x123", -0x123, 0, 0, 0},
  {"0x0xc", 0, 0, 'x', 0},
  {" +0x123fg", 0x123f, 0, 'g', 0},

  /* explicit base... */
  {"123", 0x123, 16, 0, 0},
  {"0x123", 0x123, 16, 0, 0},
  {"123", 0123, 8, 0, 0},
  {"0123", 0123, 8, 0, 0},
  {"0123", 123, 10, 0, 0},
  {"0x123", 0, 10, 'x', 0},

  /* case insensitivity... */
  {"abcd", 0xabcd, 16, 0, 0},
  {"AbCd", 0xabcd, 16, 0, 0},
  {"0xABCD", 0xabcd, 16, 0, 0},
  {"0Xabcd", 0xabcd, 16, 0, 0},

  /* odd bases... */
  {"0xyz", 33 * 35 + 34, 35, 'z', 0},
  {"yz!", 34 * 36 + 35, 36, '!', 0},
  {"-yz", -(34*36 + 35), 36, 0, 0},
  {"GhI4", ((16*20 + 17)*20 + 18)*20 + 4, 20, 0, 0},

  /* extremes... */
#if LONG_MAX == 0x7fffffff
  {"2147483647", 2147483647, 0, 0, 0},
  {"2147483648", 2147483647, 0, 0, ERANGE},
  {"214748364888", 2147483647, 0, 0, ERANGE},
  {"2147483650", 2147483647, 0, 0, ERANGE},
  {"-2147483648", 0x80000000, 0, 0, 0},
  {"-2147483649", 0x80000000, 0, 0, ERANGE},
  {"0x1122334455z", 2147483647, 16, 'z', ERANGE},
#else
  {"9223372036854775807", 9223372036854775807, 0, 0, 0},
  {"9223372036854775808", 9223372036854775807, 0, 0, ERANGE},
  {"922337203685477580777", 9223372036854775807, 0, 0, ERANGE},
  {"9223372036854775810", 9223372036854775807, 0, 0, ERANGE},
  {"-2147483648", -2147483648, 0, 0, 0},
  {"-9223372036854775808", 0x8000000000000000, 0, 0, 0},
  {"-9223372036854775809", 0x8000000000000000, 0, 0, ERANGE},
  {"0x112233445566778899z", 9223372036854775807, 16, 'z', ERANGE},
  {"0xFFFFFFFFFFFF00FF" , 9223372036854775807, 0, 0, ERANGE},
#endif
  {NULL, 0, 0, 0, 0},

  /* Then unsigned.  */
  {"  0", 0, 0, 0, 0},
  {"0xffffffffg", 0xffffffff, 0, 'g', 0},
#if LONG_MAX == 0x7fffffff
  {"-0xfedcba98", 0x01234568, 0, 0, 0},
  {"0xf1f2f3f4f5", 0xffffffff, 0, 0, ERANGE},
  {"-0x123456789", 0xffffffff, 0, 0, ERANGE},
#else
  {"0xffffffffffffffffg", 0xffffffffffffffff, 0, 'g', 0},
  {"-0xfedcba987654321", 0xf0123456789abcdf, 0, 0, 0},
  {"0xf1f2f3f4f5f6f7f8f9", 0xffffffffffffffff, 0, 0, ERANGE},
  {"-0x123456789abcdef01", 0xffffffffffffffff, 0, 0, ERANGE},
#endif
  {NULL, 0, 0, 0, 0},
  };

/* Prototypes for local functions.  */
static void expand (char *dst, int c);

int
main (void)
{
  register const struct ltest *lt;
  char *ep;
  int status = 0;
  int save_errno;

  for (lt = tests; lt->str != NULL; ++lt)
    {
      register long int l;

      errno = 0;
      l = strtol (lt->str, &ep, lt->base);
      save_errno = errno;
      printf ("strtol(\"%s\", , %d) test %u",
	      lt->str, lt->base, (unsigned int) (lt - tests));
      if (l == (long int) lt->expect && *ep == lt->left
	  && save_errno == lt->err)
	puts("\tOK");
      else
	{
	  puts("\tBAD");
	  if (l != (long int) lt->expect)
	    printf("  returns %ld, expected %ld\n",
		   l, (long int) lt->expect);
	  if (lt->left != *ep)
	    {
	      char exp1[5], exp2[5];
	      expand (exp1, *ep);
	      expand (exp2, lt->left);
	      printf ("  leaves '%s', expected '%s'\n", exp1, exp2);
	    }
	  if (save_errno != lt->err)
	    printf ("  errno %d (%s)  instead of %d (%s)\n",
		    save_errno, strerror (save_errno),
		    lt->err, strerror (lt->err));
	  status = 1;
	}
    }

  for (++lt; lt->str != NULL; lt++)
    {
      register unsigned long int ul;

      errno = 0;
      ul = strtoul (lt->str, &ep, lt->base);
      save_errno = errno;
      printf ("strtoul(\"%s\", , %d) test %u",
	      lt->str, lt->base, (unsigned int) (lt - tests));
      if (ul == lt->expect && *ep == lt->left && save_errno == lt->err)
	puts("\tOK");
      else
	{
	  puts ("\tBAD");
	  if (ul != lt->expect)
	    printf ("  returns %lu, expected %lu\n",
		    ul, lt->expect);
	  if (lt->left != *ep)
	    {
	      char exp1[5], exp2[5];
	      expand (exp1, *ep);
	      expand (exp2, lt->left);
	      printf ("  leaves '%s', expected '%s'\n", exp1, exp2);
	    }
	  if (save_errno != lt->err)
	    printf ("  errno %d (%s) instead of %d (%s)\n",
		    save_errno, strerror (save_errno),
		    lt->err, strerror (lt->err));
	  status = 1;
	}
    }

  return status ? EXIT_FAILURE : EXIT_SUCCESS;
}

static void
expand (dst, c)
     char *dst;
     int c;
{
  if (isprint (c))
    {
      dst[0] = c;
      dst[1] = '\0';
    }
  else
    (void) sprintf (dst, "%#.3o", (unsigned int) c);
}
