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
    unsigned long long int expect;	/* To get this.  */
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

  /* special case for the 32-bit version of strtoll,
     from a ncftp configure test */
  {"99000000001", 1000000000ll * 99ll + 1ll, 0, 0},

  /* extremes... */
  {"9223372036854775807", 9223372036854775807ll, 0, 0, 0},
  {"9223372036854775808", 9223372036854775807ll, 0, 0, ERANGE},
  {"922337203685477580777", 9223372036854775807ll, 0, 0, ERANGE},
  {"9223372036854775810", 9223372036854775807ll, 0, 0, ERANGE},
  {"-2147483648", -2147483648ll, 0, 0, 0},
  {"-9223372036854775808", -9223372036854775807ll - 1, 0, 0, 0},
  {"-9223372036854775809", -9223372036854775807ll - 1, 0, 0, ERANGE},
  {"0x112233445566778899z", 9223372036854775807ll, 16, 'z', ERANGE},
  {"0xFFFFFFFFFFFF00FF" , 9223372036854775807ll, 0, 0, ERANGE},
  {NULL, 0, 0, 0, 0},

  /* Then unsigned.  */
  {"  0", 0, 0, 0, 0},
  {"0xffffffffg", 0xffffffff, 0, 'g', 0},
  {"0xffffffffffffffffg", 0xffffffffffffffffull, 0, 'g', 0},
  {"-0xfedcba987654321", 0xf0123456789abcdfull, 0, 0, 0},
  {"0xf1f2f3f4f5f6f7f8f9", 0xffffffffffffffffull, 0, 0, ERANGE},
  {"-0x123456789abcdef01", 0xffffffffffffffffull, 0, 0, ERANGE},
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
      register long long int l;

      errno = 0;
      l = strtoll (lt->str, &ep, lt->base);
      save_errno = errno;
      printf ("strtoll(\"%s\", , %d) test %u",
	      lt->str, lt->base, (unsigned int) (lt - tests));
      if (l == (long long int) lt->expect && *ep == lt->left
	  && save_errno == lt->err)
	puts("\tOK");
      else
	{
	  puts("\tBAD");
	  if (l != (long long int) lt->expect)
	    printf("  returns %lld, expected %lld\n",
		   l, (long long int) lt->expect);
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
      register unsigned long long int ul;

      errno = 0;
      ul = strtoull (lt->str, &ep, lt->base);
      save_errno = errno;
      printf ("strtoull(\"%s\", , %d) test %u",
	      lt->str, lt->base, (unsigned int) (lt - tests));
      if (ul == lt->expect && *ep == lt->left && save_errno == lt->err)
	puts("\tOK");
      else
	{
	  puts ("\tBAD");
	  if (ul != lt->expect)
	    printf ("  returns %llu, expected %llu\n",
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
