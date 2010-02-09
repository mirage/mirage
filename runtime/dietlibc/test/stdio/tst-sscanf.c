/* Copyright (C) 2000, 2002 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Jakub Jelinek <jakub@redhat.com>, 2000.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <stdlib.h>
#include <stdio.h>
#include <locale.h>

const char *str_double[] =
{
  "-.10000E+020.20000E+020.25000E+010.40000E+010.50000E+010.12500E+01",
  "0.10000E+020.20000E+020.25000E+010.40000E+010.50000E+010.12500E+01",
  "-1234567E0198765432E0912345678901987654321091234567890198765432109",
  "-0.1000E+020.20000E+020.25000E+010.40000E+010.50000E+010.12500E+01"
};

const double val_double[] =
{
  -.10000E+02, 0.20000E+02, 0.25000E+01, 0.40000E+01, 0.50000E+01, 0.12500E+01,
  0.10000E+02, 0.20000E+02, 0.25000E+01, 0.40000E+01, 0.50000E+01, 0.12500E+01,
  -1234567E01, 98765432E09, 12345678901.0, 98765432109.0, 12345678901.0,
    98765432109.0,
  -0.1000E+02, 0.20000E+02, 0.25000E+01, 0.40000E+01, 0.50000E+01, 0.12500E+01
};

const char *str_long[] =
{
  "-12345678987654321123456789987654321123456789987654321",
  "-12345678987654321123456789987654321123456789987654321",
  "-12,345,678987,654,321123,456,789987,654,321123,456,789987,654,321",
  "-12,345,678987,654,321123,456,789987,654,321123,456,789987,654,321"
};

const char *fmt_long[] =
{
  "%9ld%9ld%9ld%9ld%9ld%9ld",
  "%I9ld%I9ld%I9ld%I9ld%I9ld%I9ld",
  "%'11ld%'11ld%'11ld%'11ld%'11ld%'11ld",
  "%I'11ld%I'11ld%I'11ld%I'11ld%I'11ld%I'11ld"
};

const long int val_long[] =
{
  -12345678, 987654321, 123456789, 987654321, 123456789, 987654321
};

int
main (void)
{
  double d[6];
  long l[6];
  int i, j;
  int tst_locale;
  int result = 0;

  tst_locale = 1;
  if (tst_locale)
    if (setlocale (LC_ALL, "en_US.ISO-8859-1") == NULL)
      {
	puts ("Failed to set en_US locale, skipping locale related tests");
	tst_locale = 0;
      }

  for (i = 0; i < 4; ++i)
    {
      if (sscanf (str_double[i], "%11lf%11lf%11lf%11lf%11lf%11lf",
		  &d[0], &d[1], &d[2], &d[3], &d[4], &d[5]) != 6)
	{
	  printf ("Double sscanf test %d wrong number of "
		  "assigned inputs\n", i);
	  result = 1;
	}
      else
	for (j = 0; j < 6; ++j)
	  if (d[j] != val_double[6 * i + j])
	    {
	      printf ("Double sscanf test %d failed (%g instead of %g)\n",
		      i, d[j], val_double[6 * i + j]);
	      result = 1;
	      break;
	    }
    }

  for (i = 0; i < 4; ++i)
    {
      if (sscanf (str_long[i], fmt_long[i],
		  &l[0], &l[1], &l[2], &l[3], &l[4], &l[5]) != 6)
	{
	  printf ("Integer sscanf test %d wrong number of "
		  "assigned inputs\n", i);
	  result = 1;
	}
      else
	for (j = 0; j < 6; ++j)
	  if (l[j] != val_long[j])
	    {
	      printf ("Integer sscanf test %d failed (%ld instead %ld)\n",
		      i, l[j], val_long[j]);
	      result = 1;
	      break;
	    }

      if (! tst_locale)
	break;
    }

  return result;
}
