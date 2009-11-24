/*
 * strcmp.c -- strcmp function.  On at least some MIPS chips, a strcmp that is
 * unrolled twice is faster than the 'optimized' C version in newlib.
 *
 * Copyright (c) 2001 Red Hat, Inc.
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.  */

#include <stddef.h>
#include <string.h>
#include <stdlib.h>

int
strcmp (const char *s1, const char *s2)
{ 
  unsigned const char *us1 = (unsigned const char *)s1;
  unsigned const char *us2 = (unsigned const char *)s2;
  int c1a, c1b;
  int c2a, c2b;

  /* If the pointers aren't both aligned to a 16-byte boundary, do the
     comparison byte by byte, so that we don't get an invalid page fault if we
     are comparing a string whose null byte is at the last byte on the last
     valid page.  */
  if (((((long)us1) | ((long)us2)) & 1) == 0)
    {
      c1a = *us1;
      for (;;)
	{
	  c1b = *us2;
	  us1 += 2;
	  if (c1a == '\0')
	    goto ret1;

	  c2a = us1[-1];
	  if (c1a != c1b)
	    goto ret1;

	  c2b = us2[1];
	  us2 += 2;
	  if (c2a == '\0')
	    break;

	  c1a = *us1;
	  if (c2a != c2b)
	    break;
	}

      return c2a - c2b;
    }
  else
    {
      do
	{
	  c1a = *us1++;
	  c1b = *us2++;
	}
      while (c1a != '\0' && c1a == c1b);
    }

 ret1:
  return c1a - c1b;
}
