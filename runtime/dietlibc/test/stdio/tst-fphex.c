/* Test program for %a printf formats.  */

#include <stdio.h>
#include <string.h>

struct testcase
{
  double value;
  const char *fmt;
  const char *expect;
};

static const struct testcase testcases[] =
  {
    { 0x0.0030p+0, "%a",	"0x1.8p-11" },
    { 0x0.0040p+0, "%a",	"0x1p-10" },
    { 0x0.0030p+0, "%040a",	"0x00000000000000000000000000000001.8p-11" },
    { 0x0.0040p+0, "%040a",	"0x0000000000000000000000000000000001p-10" },
    { 0x0.0040p+0, "%40a",	"                                 0x1p-10" },
    { 0x0.0040p+0, "%#40a",	"                                0x1.p-10" },
    { 0x0.0040p+0, "%-40a",	"0x1p-10                                 " },
    { 0x0.0040p+0, "%#-40a",	"0x1.p-10                                " },
    { 0x0.0030p+0, "%040e",	"00000000000000000000000000007.324219e-04" },
    { 0x0.0040p+0, "%040e",	"00000000000000000000000000009.765625e-04" },
  };


int main (int argc, char **argv) {
  const struct testcase *t;
  int result = 0;

  for (t = testcases;
       t < &testcases[sizeof testcases / sizeof testcases[0]];
       ++t)
    {
      char buf[1024];
      int n = snprintf (buf, sizeof buf, t->fmt, t->value);
      if (n != strlen (t->expect) || strcmp (buf, t->expect) != 0)
	{
	  printf ("%s\tExpected \"%s\" (%zu)\n\tGot      \"%s\" (%d, %zu)\n",
		  t->fmt, t->expect, strlen (t->expect), buf, n, strlen (buf));
	  result = 1;
	}
    }

  return result;
}

