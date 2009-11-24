/*-
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/* Split from vfscanf.c  */

#include <_ansi.h>
#include <reent.h>
#include <newlib.h>
#include <stdio.h>
#include "local.h"

/*
 * Fill in the given table from the scanset at the given format
 * (just after `[').  Return a pointer to the character past the
 * closing `]'.  The table has a 1 wherever characters should be
 * considered part of the scanset.
 */

u_char *
_DEFUN(__sccl, (tab, fmt),
       register char *tab _AND
       register u_char *fmt)
{
  register int c, n, v;

  /* first `clear' the whole table */
  c = *fmt++;			/* first char hat => negated scanset */
  if (c == '^')
    {
      v = 1;			/* default => accept */
      c = *fmt++;		/* get new first char */
    }
  else
    v = 0;			/* default => reject */
  /* should probably use memset here */
  for (n = 0; n < 256; n++)
    tab[n] = v;
  if (c == 0)
    return fmt - 1;		/* format ended before closing ] */

  /*
   * Now set the entries corresponding to the actual scanset to the
   * opposite of the above.
   *
   * The first character may be ']' (or '-') without being special; the
   * last character may be '-'.
   */

  v = 1 - v;
  for (;;)
    {
      tab[c] = v;		/* take character c */
    doswitch:
      n = *fmt++;		/* and examine the next */
      switch (n)
	{

	case 0:		/* format ended too soon */
	  return fmt - 1;

	case '-':
	  /*
	   * A scanset of the form [01+-] is defined as `the digit 0, the
	   * digit 1, the character +, the character -', but the effect of a
	   * scanset such as [a-zA-Z0-9] is implementation defined.  The V7
	   * Unix scanf treats `a-z' as `the letters a through z', but treats
	   * `a-a' as `the letter a, the character -, and the letter a'.
	   *
	   * For compatibility, the `-' is not considerd to define a range if
	   * the character following it is either a close bracket (required by
	   * ANSI) or is not numerically greater than the character we just
	   * stored in the table (c).
	   */
	  n = *fmt;
	  if (n == ']' || n < c)
	    {
	      c = '-';
	      break;		/* resume the for(;;) */
	    }
	  fmt++;
	  do
	    {			/* fill in the range */
	      tab[++c] = v;
	    }
	  while (c < n);
#if 1			/* XXX another disgusting compatibility hack */
	  /*
	   * Alas, the V7 Unix scanf also treats formats such
	   * as [a-c-e] as `the letters a through e'. This too
	   * is permitted by the standard....
	   */
	  goto doswitch;
#else
	  c = *fmt++;
	  if (c == 0)
	    return fmt - 1;
	  if (c == ']')
	    return fmt;
#endif

	  break;


	case ']':		/* end of scanset */
	  return fmt;

	default:		/* just another character */
	  c = n;
	  break;
	}
    }
  /* NOTREACHED */
}
