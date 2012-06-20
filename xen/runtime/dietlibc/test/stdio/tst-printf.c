/* Copyright (C) 1991,92,93,95,96,97,98,99, 2000, 2002
     Free Software Foundation, Inc.
   This file is part of the GNU C Library.

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

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <float.h>

static void rfg1 (void);
static void rfg2 (void);
static void rfg3 (void);


static void
fmtchk (const char *fmt)
{
  (void) fputs(fmt, stdout);
  (void) printf(":\t`");
  (void) printf(fmt, 0x12);
  (void) printf("'\n");
}

static void
fmtst1chk (const char *fmt)
{
  (void) fputs(fmt, stdout);
  (void) printf(":\t`");
  (void) printf(fmt, 4, 0x12);
  (void) printf("'\n");
}

static void
fmtst2chk (const char *fmt)
{
  (void) fputs(fmt, stdout);
  (void) printf(":\t`");
  (void) printf(fmt, 4, 4, 0x12);
  (void) printf("'\n");
}

/* This page is covered by the following copyright: */

/* (C) Copyright C E Chew
 *
 * Feel free to copy, use and distribute this software provided:
 *
 *	1. you do not pretend that you wrote it
 *	2. you leave this copyright notice intact.
 */

/*
 * Extracted from exercise.c for glibc-1.05 bug report by Bruce Evans.
 */

#define DEC -123
#define INT 255
#define UNS (~0)

/* Formatted Output Test
 *
 * This exercises the output formatting code.
 */

static void
fp_test (void)
{
  int i, j, k, l;
  char buf[7];
  char *prefix = buf;
  char tp[20];

  puts("\nFormatted output test");
  printf("prefix  6d      6o      6x      6X      6u\n");
  strcpy(prefix, "%");
  for (i = 0; i < 2; i++) {
    for (j = 0; j < 2; j++) {
      for (k = 0; k < 2; k++) {
	for (l = 0; l < 2; l++) {
	  strcpy(prefix, "%");
	  if (i == 0) strcat(prefix, "-");
	  if (j == 0) strcat(prefix, "+");
	  if (k == 0) strcat(prefix, "#");
	  if (l == 0) strcat(prefix, "0");
	  printf("%5s |", prefix);
	  strcpy(tp, prefix);
	  strcat(tp, "6d |");
	  printf(tp, DEC);
	  strcpy(tp, prefix);
	  strcat(tp, "6o |");
	  printf(tp, INT);
	  strcpy(tp, prefix);
	  strcat(tp, "6x |");
	  printf(tp, INT);
	  strcpy(tp, prefix);
	  strcat(tp, "6X |");
	  printf(tp, INT);
	  strcpy(tp, prefix);
	  strcat(tp, "6u |");
	  printf(tp, UNS);
	  printf("\n");
	}
      }
    }
  }
  printf("%10s\n", (char *) NULL);
  printf("%-10s\n", (char *) NULL);
}

int
main (int argc, char *argv[])
{
  static char shortstr[] = "Hi, Z.";
  static char longstr[] = "Good morning, Doctor Chandra.  This is Hal.  \
I am ready for my first lesson today.";
  int result = 0;

  fmtchk("%.4x");
  fmtchk("%04x");
  fmtchk("%4.4x");
  fmtchk("%04.4x");
  fmtchk("%4.3x");
  fmtchk("%04.3x");

  fmtst1chk("%.*x");
  fmtst1chk("%0*x");
  fmtst2chk("%*.*x");
  fmtst2chk("%0*.*x");

  printf("bad format:\t\"%b\"\n");
  printf("nil pointer (padded):\t\"%10p\"\n", (void *) NULL);

  printf("decimal negative:\t\"%d\"\n", -2345);
  printf("octal negative:\t\"%o\"\n", -2345);
  printf("hex negative:\t\"%x\"\n", -2345);
  printf("long decimal number:\t\"%ld\"\n", -123456L);
  printf("long octal negative:\t\"%lo\"\n", -2345L);
  printf("long unsigned decimal number:\t\"%lu\"\n", -123456L);
  printf("zero-padded LDN:\t\"%010ld\"\n", -123456L);
  printf("left-adjusted ZLDN:\t\"%-010ld\"\n", -123456L);
  printf("space-padded LDN:\t\"%10ld\"\n", -123456L);
  printf("left-adjusted SLDN:\t\"%-10ld\"\n", -123456L);

  printf("zero-padded string:\t\"%010s\"\n", shortstr);
  printf("left-adjusted Z string:\t\"%-010s\"\n", shortstr);
  printf("space-padded string:\t\"%10s\"\n", shortstr);
  printf("left-adjusted S string:\t\"%-10s\"\n", shortstr);
  printf("null string:\t\"%s\"\n", (char *)NULL);
  printf("limited string:\t\"%.22s\"\n", longstr);

  printf("e-style >= 1:\t\"%e\"\n", 12.34);
  printf("e-style >= .1:\t\"%e\"\n", 0.1234);
  printf("e-style < .1:\t\"%e\"\n", 0.001234);
  printf("e-style big:\t\"%.60e\"\n", 1e20);
  printf ("e-style == .1:\t\"%e\"\n", 0.1);
  printf("f-style >= 1:\t\"%f\"\n", 12.34);
  printf("f-style >= .1:\t\"%f\"\n", 0.1234);
  printf("f-style < .1:\t\"%f\"\n", 0.001234);
  printf("g-style >= 1:\t\"%g\"\n", 12.34);
  printf("g-style >= .1:\t\"%g\"\n", 0.1234);
  printf("g-style < .1:\t\"%g\"\n", 0.001234);
  printf("g-style big:\t\"%.60g\"\n", 1e20);

  printf (" %6.5f\n", .099999999860301614);
  printf (" %6.5f\n", .1);
  printf ("x%5.4fx\n", .5);

  printf ("%#03x\n", 1);

  printf ("something really insane: %.10000f\n", 1.0);

  {
    double d = FLT_MIN;
    int niter = 17;

    while (niter-- != 0)
      printf ("%.17e\n", d / 2);
    fflush (stdout);
  }

  printf ("%15.5e\n", 4.9406564584124654e-324);

#define FORMAT "|%12.4f|%12.4e|%12.4g|\n"
  printf (FORMAT, 0.0, 0.0, 0.0);
  printf (FORMAT, 1.0, 1.0, 1.0);
  printf (FORMAT, -1.0, -1.0, -1.0);
  printf (FORMAT, 100.0, 100.0, 100.0);
  printf (FORMAT, 1000.0, 1000.0, 1000.0);
  printf (FORMAT, 10000.0, 10000.0, 10000.0);
  printf (FORMAT, 12345.0, 12345.0, 12345.0);
  printf (FORMAT, 100000.0, 100000.0, 100000.0);
  printf (FORMAT, 123456.0, 123456.0, 123456.0);
#undef	FORMAT

  {
    char buf[20];
    char buf2[512];
    printf ("snprintf (\"%%30s\", \"foo\") == %d, \"%.*s\"\n",
	    snprintf (buf, sizeof (buf), "%30s", "foo"), (int) sizeof (buf),
	    buf);
    printf ("snprintf (\"%%.999999u\", 10) == %d\n",
	    snprintf(buf2, sizeof(buf2), "%.999999u", 10));
  }

  fp_test ();

  printf ("%e should be 1.234568e+06\n", 1234567.8);
  printf ("%f should be 1234567.800000\n", 1234567.8);
  printf ("%g should be 1.23457e+06\n", 1234567.8);
  printf ("%g should be 123.456\n", 123.456);
  printf ("%g should be 1e+06\n", 1000000.0);
  printf ("%g should be 10\n", 10.0);
  printf ("%g should be 0.02\n", 0.02);

#if 0
  /* This test rather checks the way the compiler handles constant
     folding.  gcc behavior wrt to this changed in 3.2 so it is not a
     portable test.  */
  {
    double x=1.0;
    printf("%.17f\n",(1.0/x/10.0+1.0)*x-x);
  }
#endif

  {
    char buf[200];

    sprintf(buf,"%*s%*s%*s",-1,"one",-20,"two",-30,"three");

    result |= strcmp (buf,
		      "onetwo                 three                         ");

    puts (result != 0 ? "Test failed!" : "Test ok.");
  }

  {
    char buf[200];

    sprintf (buf, "%07Lo", 040000000000ll);
    printf ("sprintf (buf, \"%%07Lo\", 040000000000ll) = %s", buf);

    if (strcmp (buf, "40000000000") != 0)
      {
	result = 1;
	fputs ("\tFAILED", stdout);
      }
    puts ("");
  }

  printf ("printf (\"%%hhu\", %u) = %hhu\n", UCHAR_MAX + 2, UCHAR_MAX + 2);
  printf ("printf (\"%%hu\", %u) = %hu\n", USHRT_MAX + 2, USHRT_MAX + 2);

  puts ("--- Should be no further output. ---");
  rfg1 ();
  rfg2 ();
  rfg3 ();

  {
    char bytes[7];
    char buf[20];

    memset (bytes, '\xff', sizeof bytes);
    sprintf (buf, "foo%hhn\n", &bytes[3]);
    if (bytes[0] != '\xff' || bytes[1] != '\xff' || bytes[2] != '\xff'
	|| bytes[4] != '\xff' || bytes[5] != '\xff' || bytes[6] != '\xff')
      {
	puts ("%hhn overwrite more bytes");
	result = 1;
      }
    if (bytes[3] != 3)
      {
	puts ("%hhn wrote incorrect value");
	result = 1;
      }
  }

  return result != 0;
}

static void
rfg1 (void)
{
  char buf[100];

  sprintf (buf, "%5.s", "xyz");
  if (strcmp (buf, "     ") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "     ");
  sprintf (buf, "%5.f", 33.3);
  if (strcmp (buf, "   33") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "   33");
  sprintf (buf, "%8.e", 33.3e7);
  if (strcmp (buf, "   3e+08") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "   3e+08");
  sprintf (buf, "%8.E", 33.3e7);
  if (strcmp (buf, "   3E+08") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "   3E+08");
  sprintf (buf, "%.g", 33.3);
  if (strcmp (buf, "3e+01") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "3e+01");
  sprintf (buf, "%.G", 33.3);
  if (strcmp (buf, "3E+01") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "3E+01");
}

static void
rfg2 (void)
{
  int prec;
  char buf[100];

  prec = 0;
  sprintf (buf, "%.*g", prec, 3.3);
  if (strcmp (buf, "3") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "3");
  prec = 0;
  sprintf (buf, "%.*G", prec, 3.3);
  if (strcmp (buf, "3") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "3");
  prec = 0;
  sprintf (buf, "%7.*G", prec, 3.33);
  if (strcmp (buf, "      3") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "      3");
  prec = 3;
  sprintf (buf, "%04.*o", prec, 33);
  if (strcmp (buf, " 041") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, " 041");
  prec = 7;
  sprintf (buf, "%09.*u", prec, 33);
  if (strcmp (buf, "  0000033") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, "  0000033");
  prec = 3;
  sprintf (buf, "%04.*x", prec, 33);
  if (strcmp (buf, " 021") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, " 021");
  prec = 3;
  sprintf (buf, "%04.*X", prec, 33);
  if (strcmp (buf, " 021") != 0)
    printf ("got: '%s', expected: '%s'\n", buf, " 021");
}

static void
rfg3 (void)
{
  char buf[100];
  double g = 5.0000001;
  unsigned long l = 1234567890;
  double d = 321.7654321;
  const char s[] = "test-string";
  int i = 12345;
  int h = 1234;

  sprintf (buf,
	   "%1$*5$d %2$*6$hi %3$*7$lo %4$*8$f %9$*12$e %10$*13$g %11$*14$s",
	   i, h, l, d, 8, 5, 14, 14, d, g, s, 14, 3, 14);
  if (strcmp (buf,
	      "   12345  1234    11145401322     321.765432   3.217654e+02   5    test-string") != 0)
    printf ("got: '%s', expected: '%s'\n", buf,
	    "   12345  1234    11145401322     321.765432   3.217654e+02   5    test-string");
}
