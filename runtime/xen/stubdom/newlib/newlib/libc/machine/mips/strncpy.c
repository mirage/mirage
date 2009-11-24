/*
 * strncpy.S -- strncmp function.  On at least some MIPS chips, you get better
 * code by hand unrolling the loops, and by using store words to zero the
 * remainder of the buffer than the default newlib C version.
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

#include <string.h>
#include <stddef.h>
#include <stdlib.h>

#if !defined(__GNUC__) || (__GNUC__ < 3)
#define __builtin_expect(a,b) a

#else
#ifdef __mips64
/* Don't use limits test for the size of long, in order to allow the use of
   64-bit stores on MIPS3 machines, even if -mlong32 was used.  */
typedef unsigned word_type __attribute__ ((mode (DI)));
#else
typedef unsigned word_type __attribute__ ((mode (SI)));
#endif

typedef unsigned si_type __attribute__ ((mode (SI)));
typedef unsigned hi_type __attribute__ ((mode (HI)));

#ifndef UNROLL_FACTOR
#define UNROLL_FACTOR 4

#elif (UNROLL_FACTOR != 2) && (UNROLL_FACTOR != 4)
#error "UNROLL_FACTOR must be 2 or 4"
#endif
#endif

char *
strncpy (char *dst0, const char *src0, size_t count)
{
#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__) || defined(__mips16) || !defined(__GNUC__) || (__GNUC__ < 3)
  char *dst, *end;
  const char *src;
  int ch;

  dst = dst0;
  src = src0;
  end = dst + count;
  while (dst != end)
    {
      *dst++ = ch = *src++;
      if (__builtin_expect (ch == '\0', 0))
	{
	  while (dst != end)
	    *dst++ = '\0';

	  break;
	}
    }

  return dst0;

#else
  unsigned char *dst;
  unsigned char *dst_end;
  unsigned char *end;
  const unsigned char *src;
  int ch0, ch1;
#if UNROLL_FACTOR > 2
  int ch2, ch3;
#endif
  int ch;
  int odd_bytes;
  size_t long_count;

  dst = (unsigned char *)dst0;
  src = (unsigned const char *)src0;
  if (__builtin_expect (count >= 4, 1))
    {
      odd_bytes = (count & (UNROLL_FACTOR - 1));
      count -= odd_bytes;

      do
	{
	  ch0 = src[0];
	  ch1 = src[1];
#if UNROLL_FACTOR > 2
	  ch2 = src[2];
	  ch3 = src[3];
#endif
	  src += UNROLL_FACTOR;
	  count -= UNROLL_FACTOR;

	  dst[0] = ch0;
	  if (ch0 == '\0')
	    goto found_null0;

	  dst[1] = ch1;
	  if (ch1 == '\0')
	    goto found_null1;

#if UNROLL_FACTOR > 2
	  dst[2] = ch2;
	  if (ch2 == '\0')
	    goto found_null2;

	  dst[3] = ch3;
	  if (ch3 == '\0')
	    goto found_null3;
#endif

	  dst += UNROLL_FACTOR;
	}
      while (count);

      /* fall through, count == 0, no null found, deal with last bytes */
      count = odd_bytes;
    }

  end = dst + count;
  while (dst != end)
    {
      *dst++ = ch = *src++;
      if (ch == '\0')
	{
	  while (dst != end)
	    *dst++ = '\0';

	  break;
	}
    }

  return dst0;

  /* Found null byte in first byte, count has been decremented by 4, null has
     been stored in dst[0].  */
 found_null0:
  count++;			/* add 1 to cover remaining byte */
  dst -= 1;			/* adjust dst += 4 gets correct ptr */
  /* fall through */

  /* Found null byte in second byte, count has been decremented by 4, null has
     been stored in dst[1].  */
 found_null1:
#if UNROLL_FACTOR > 2
  count++;			/* add 1 to cover remaining byte */
  dst -= 1;			/* adjust dst += 4 gets correct ptr */
  /* fall through */

  /* Found null byte in third byte, count has been decremented by 4, null has
     been stored in dst[2].  */
 found_null2:
  count++;			/* add 1 to cover remaining byte */
  dst -= 1;			/* adjust dst += 4 gets correct ptr */
  /* fall through */

  /* Found null byte in fourth byte, count is accurate, dst has not been
     updated yet.  */
 found_null3:
#endif
  count += odd_bytes;		/* restore odd byte count */
  dst += UNROLL_FACTOR;

  /* Zero fill remainder of the array.  Unroll the loop, and use word/dword
     stores where we can.  */
  while (count && (((long)dst) & (sizeof (word_type) - 1)) != 0)
    {
      count--;
      *dst++ = 0;
    }

  while (count >= UNROLL_FACTOR*sizeof (word_type))
    {
      count -= UNROLL_FACTOR*sizeof (word_type);
      dst += UNROLL_FACTOR*sizeof (word_type);
#if UNROLL_FACTOR > 2
      ((word_type *)(void *)dst)[-4] = 0;
      ((word_type *)(void *)dst)[-3] = 0;
#endif
      ((word_type *)(void *)dst)[-2] = 0;
      ((word_type *)(void *)dst)[-1] = 0;
    }

#if UNROLL_FACTOR > 2
  if (count >= 2*sizeof (word_type))
    {
      count -= 2*sizeof (word_type);
      ((word_type *)(void *)dst)[0] = 0;
      ((word_type *)(void *)dst)[1] = 0;
      dst += 2*sizeof (word_type);
    }
#endif 

  if (count >= sizeof (word_type))
    {
      count -= sizeof (word_type);
      ((word_type *)(void *)dst)[0] = 0;
      dst += sizeof (word_type);
    }

#ifdef __mips64
  if (count >= sizeof (si_type))
    {
      count -= sizeof (si_type);
      ((si_type *)(void *)dst)[0] = 0;
      dst += sizeof (si_type);
    }
#endif

  if (count >= sizeof (hi_type))
    {
      count -= sizeof (hi_type);
      ((hi_type *)(void *)dst)[0] = 0;
      dst += sizeof (hi_type);
    }

  if (count)
    *dst = '\0';

  return dst0;
#endif
}
