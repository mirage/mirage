/* Simple transformations functions.
   Copyright (C) 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1997.

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

#include <byteswap.h>
#include <dlfcn.h>
#include <endian.h>
#include <errno.h>
#include <gconv.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <sys/param.h>

#define BUILTIN_ALIAS(s1, s2) /* nothing */
#define BUILTIN_TRANSFORMATION(From, To, Cost, Name, Fct, MinF, MaxF, \
			       MinT, MaxT) \
  extern int Fct (struct __gconv_step *, struct __gconv_step_data *,	      \
		  __const unsigned char **, __const unsigned char *,	      \
		  unsigned char **, size_t *, int, int);
#include "gconv_builtin.h"


#ifndef EILSEQ
# define EILSEQ EINVAL
#endif


/* Transform from the internal, UCS4-like format, to UCS4.  The
   difference between the internal ucs4 format and the real UCS4
   format is, if any, the endianess.  The Unicode/ISO 10646 says that
   unless some higher protocol specifies it differently, the byte
   order is big endian.*/
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		internal_ucs4_loop
#define TO_LOOP			internal_ucs4_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_internal_ucs4


static inline int
internal_ucs4_loop (struct __gconv_step *step,
		    struct __gconv_step_data *step_data,
		    const unsigned char **inptrp, const unsigned char *inend,
		    unsigned char **outptrp, unsigned char *outend,
		    size_t *irreversible)
{
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;

#if __BYTE_ORDER == __LITTLE_ENDIAN
  /* Sigh, we have to do some real work.  */
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4)
    {
      *((uint32_t *) outptr) = bswap_32 (*(const uint32_t *) inptr);
      outptr = (unsigned char *)((uint32_t *) outptr + 1);
    }

  *inptrp = inptr;
  *outptrp = outptr;
#elif __BYTE_ORDER == __BIG_ENDIAN
  /* Simply copy the data.  */
  *inptrp = inptr + n_convert * 4;
  *outptrp = memcpy (outptr, inptr, n_convert * 4);
  *outptrp += n_convert * 4;
#else
# error "This endianess is not supported."
#endif

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}

#ifndef _STRING_ARCH_unaligned
static inline int
internal_ucs4_loop_unaligned (struct __gconv_step *step,
			      struct __gconv_step_data *step_data,
			      const unsigned char **inptrp,
			      const unsigned char *inend,
			      unsigned char **outptrp, unsigned char *outend,
			      size_t *irreversible)
{
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;

# if __BYTE_ORDER == __LITTLE_ENDIAN
  /* Sigh, we have to do some real work.  */
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4, outptr += 4)
    {
      outptr[0] = inptr[3];
      outptr[1] = inptr[2];
      outptr[2] = inptr[1];
      outptr[3] = inptr[0];
    }

  *inptrp = inptr;
  *outptrp = outptr;
# elif __BYTE_ORDER == __BIG_ENDIAN
  /* Simply copy the data.  */
  *inptrp = inptr + n_convert * 4;
  *outptrp = memcpy (outptr, inptr, n_convert * 4);
  *outptrp += n_convert * 4;
# else
#  error "This endianess is not supported."
# endif

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}
#endif


static inline int
internal_ucs4_loop_single (struct __gconv_step *step,
			   struct __gconv_step_data *step_data,
			   const unsigned char **inptrp,
			   const unsigned char *inend,
			   unsigned char **outptrp, unsigned char *outend,
			   size_t *irreversible)
{
  mbstate_t *state = step_data->__statep;
  size_t cnt = state->__count & 7;

  while (*inptrp < inend && cnt < 4)
    state->__value.__wchb[cnt++] = *(*inptrp)++;

  if (__builtin_expect (cnt < 4, 0))
    {
      /* Still not enough bytes.  Store the ones in the input buffer.  */
      state->__count &= ~7;
      state->__count |= cnt;

      return __GCONV_INCOMPLETE_INPUT;
    }

#if __BYTE_ORDER == __LITTLE_ENDIAN
  (*outptrp)[0] = state->__value.__wchb[3];
  (*outptrp)[1] = state->__value.__wchb[2];
  (*outptrp)[2] = state->__value.__wchb[1];
  (*outptrp)[3] = state->__value.__wchb[0];

  *outptrp += 4;
#elif __BYTE_ORDER == __BIG_ENDIAN
  {
    uint32_t **p = (uint32_t **)outptrp;
    uint32_t *q = *p;
    /* XXX unaligned */
    *q = state->__value.__wch;
    outptrp = (unsigned char *)(p + 1);
  }
#else
# error "This endianess is not supported."
#endif

  /* Clear the state buffer.  */
  state->__count &= ~7;

  return __GCONV_OK;
}

#include <iconv/skeleton.c>


/* Transform from UCS4 to the internal, UCS4-like format.  Unlike
   for the other direction we have to check for correct values here.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		ucs4_internal_loop
#define TO_LOOP			ucs4_internal_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_ucs4_internal


static inline int
ucs4_internal_loop (struct __gconv_step *step,
		    struct __gconv_step_data *step_data,
		    const unsigned char **inptrp, const unsigned char *inend,
		    unsigned char **outptrp, unsigned char *outend,
		    size_t *irreversible)
{
  int flags = step_data->__flags;
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4)
    {
      uint32_t inval;

#if __BYTE_ORDER == __LITTLE_ENDIAN
      inval = bswap_32 (*(const uint32_t *) inptr);
#else
      inval = *(const uint32_t *) inptr;
#endif

      if (__builtin_expect (inval > 0x7fffffff, 0))
	{
	  /* The value is too large.  We don't try transliteration here since
	     this is not an error because of the lack of possibilities to
	     represent the result.  This is a genuine bug in the input since
	     UCS4 does not allow such values.  */
	  if (irreversible == NULL)
	    /* We are transliterating, don't try to correct anything.  */
	    return __GCONV_ILLEGAL_INPUT;

	  if (flags & __GCONV_IGNORE_ERRORS)
	    {
	      /* Just ignore this character.  */
	      *irreversible = *irreversible + 1;
	      continue;
	    }

	  *inptrp = inptr;
	  *outptrp = outptr;
	  return __GCONV_ILLEGAL_INPUT;
	}

      *((uint32_t *) outptr) = inval;
      outptr = (unsigned char *) ((uint32_t *) outptr + 1);
    }

  *inptrp = inptr;
  *outptrp = outptr;

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}

#ifndef _STRING_ARCH_unaligned
static inline int
ucs4_internal_loop_unaligned (struct __gconv_step *step,
			      struct __gconv_step_data *step_data,
			      const unsigned char **inptrp,
			      const unsigned char *inend,
			      unsigned char **outptrp, unsigned char *outend,
			      size_t *irreversible)
{
  int flags = step_data->__flags;
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4)
    {
      if (__builtin_expect (inptr[0] > 0x80, 0))
	{
	  /* The value is too large.  We don't try transliteration here since
	     this is not an error because of the lack of possibilities to
	     represent the result.  This is a genuine bug in the input since
	     UCS4 does not allow such values.  */
	  if (irreversible == NULL)
	    /* We are transliterating, don't try to correct anything.  */
	    return __GCONV_ILLEGAL_INPUT;

	  if (flags & __GCONV_IGNORE_ERRORS)
	    {
	      /* Just ignore this character.  */
	      *irreversible = *irreversible + 1;
	      continue;
	    }

	  *inptrp = inptr;
	  *outptrp = outptr;
 	  return __GCONV_ILLEGAL_INPUT;
	}

# if __BYTE_ORDER == __LITTLE_ENDIAN
      outptr[3] = inptr[0];
      outptr[2] = inptr[1];
      outptr[1] = inptr[2];
      outptr[0] = inptr[3];
# else
      outptr[0] = inptr[0];
      outptr[1] = inptr[1];
      outptr[2] = inptr[2];
      outptr[3] = inptr[3];
# endif
      outptr += 4;
    }

  *inptrp = inptr;
  *outptrp = outptr;

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}
#endif


static inline int
ucs4_internal_loop_single (struct __gconv_step *step,
			   struct __gconv_step_data *step_data,
			   const unsigned char **inptrp,
			   const unsigned char *inend,
			   unsigned char **outptrp, unsigned char *outend,
			   size_t *irreversible)
{
  mbstate_t *state = step_data->__statep;
  int flags = step_data->__flags;
  size_t cnt = state->__count & 7;

  while (*inptrp < inend && cnt < 4)
    state->__value.__wchb[cnt++] = *(*inptrp)++;

  if (__builtin_expect (cnt < 4, 0))
    {
      /* Still not enough bytes.  Store the ones in the input buffer.  */
      state->__count &= ~7;
      state->__count |= cnt;

      return __GCONV_INCOMPLETE_INPUT;
    }

  if (__builtin_expect (((unsigned char *) state->__value.__wchb)[0] > 0x80,
			0))
    {
      /* The value is too large.  We don't try transliteration here since
	 this is not an error because of the lack of possibilities to
	 represent the result.  This is a genuine bug in the input since
	 UCS4 does not allow such values.  */
      if (!(flags & __GCONV_IGNORE_ERRORS))
	{
	  *inptrp -= cnt - (state->__count & 7);
	  return __GCONV_ILLEGAL_INPUT;
	}
    }
  else
    {
#if __BYTE_ORDER == __LITTLE_ENDIAN
      (*outptrp)[0] = state->__value.__wchb[3];
      (*outptrp)[1] = state->__value.__wchb[2];
      (*outptrp)[2] = state->__value.__wchb[1];
      (*outptrp)[3] = state->__value.__wchb[0];
#elif __BYTE_ORDER == __BIG_ENDIAN
      (*outptrp)[0] = state->__value.__wchb[0];
      (*outptrp)[1] = state->__value.__wchb[1];
      (*outptrp)[2] = state->__value.__wchb[2];
      (*outptrp)[3] = state->__value.__wchb[3];
#endif

      *outptrp += 4;
    }

  /* Clear the state buffer.  */
  state->__count &= ~7;

  return __GCONV_OK;
}

#include <iconv/skeleton.c>


/* Similarly for the little endian form.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		internal_ucs4le_loop
#define TO_LOOP			internal_ucs4le_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_internal_ucs4le


static inline int
internal_ucs4le_loop (struct __gconv_step *step,
		      struct __gconv_step_data *step_data,
		      const unsigned char **inptrp, const unsigned char *inend,
		      unsigned char **outptrp, unsigned char *outend,
		      size_t *irreversible)
{
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;

#if __BYTE_ORDER == __BIG_ENDIAN
  /* Sigh, we have to do some real work.  */
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4)
    *((uint32_t *) outptr)++ = bswap_32 (*(const uint32_t *) inptr);

  *inptrp = inptr;
  *outptrp = outptr;
#elif __BYTE_ORDER == __LITTLE_ENDIAN
  /* Simply copy the data.  */
  *inptrp = inptr + n_convert * 4;
  *outptrp = memcpy (outptr, inptr, n_convert * 4);
  *outptrp += n_convert * 4;
#else
# error "This endianess is not supported."
#endif

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}

#ifndef _STRING_ARCH_unaligned
static inline int
internal_ucs4le_loop_unaligned (struct __gconv_step *step,
				struct __gconv_step_data *step_data,
				const unsigned char **inptrp,
				const unsigned char *inend,
				unsigned char **outptrp, unsigned char *outend,
				size_t *irreversible)
{
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;

# if __BYTE_ORDER == __BIG_ENDIAN
  /* Sigh, we have to do some real work.  */
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4, outptr += 4)
    {
      outptr[0] = inptr[3];
      outptr[1] = inptr[2];
      outptr[2] = inptr[1];
      outptr[3] = inptr[0];
    }

  *inptrp = inptr;
  *outptrp = outptr;
# elif __BYTE_ORDER == __LITTLE_ENDIAN
  /* Simply copy the data.  */
  *inptrp = inptr + n_convert * 4;
  *outptrp = memcpy (outptr, inptr, n_convert * 4);
  *outptrp += n_convert * 4;
# else
#  error "This endianess is not supported."
# endif

  /* Determine the status.  */
  if (*inptrp + 4 > inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}
#endif


static inline int
internal_ucs4le_loop_single (struct __gconv_step *step,
			     struct __gconv_step_data *step_data,
			     const unsigned char **inptrp,
			     const unsigned char *inend,
			     unsigned char **outptrp, unsigned char *outend,
			     size_t *irreversible)
{
  mbstate_t *state = step_data->__statep;
  size_t cnt = state->__count & 7;

  while (*inptrp < inend && cnt < 4)
    state->__value.__wchb[cnt++] = *(*inptrp)++;

  if (__builtin_expect (cnt < 4, 0))
    {
      /* Still not enough bytes.  Store the ones in the input buffer.  */
      state->__count &= ~7;
      state->__count |= cnt;

      return __GCONV_INCOMPLETE_INPUT;
    }

#if __BYTE_ORDER == __BIG_ENDIAN
  (*outptrp)[0] = state->__value.__wchb[3];
  (*outptrp)[1] = state->__value.__wchb[2];
  (*outptrp)[2] = state->__value.__wchb[1];
  (*outptrp)[3] = state->__value.__wchb[0];

  *outptrp += 4;
#else
  {
  /* XXX unaligned */
  uint32_t **p = (uint32_t **)outptrp;
  uint32_t *q = *p;
  *q = state->__value.__wch;
  outptrp = (unsigned char **)(p + 1);
  }
#endif

  /* Clear the state buffer.  */
  state->__count &= ~7;

  return __GCONV_OK;
}

#include <iconv/skeleton.c>


/* And finally from UCS4-LE to the internal encoding.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		ucs4le_internal_loop
#define TO_LOOP			ucs4le_internal_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_ucs4le_internal


static inline int
ucs4le_internal_loop (struct __gconv_step *step,
		      struct __gconv_step_data *step_data,
		      const unsigned char **inptrp, const unsigned char *inend,
		      unsigned char **outptrp, unsigned char *outend,
		      size_t *irreversible)
{
  int flags = step_data->__flags;
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4)
    {
      uint32_t inval;

#if __BYTE_ORDER == __BIG_ENDIAN
      inval = bswap_32 (*(const uint32_t *) inptr);
#else
      inval = *(const uint32_t *) inptr;
#endif

      if (__builtin_expect (inval > 0x7fffffff, 0))
	{
	  /* The value is too large.  We don't try transliteration here since
	     this is not an error because of the lack of possibilities to
	     represent the result.  This is a genuine bug in the input since
	     UCS4 does not allow such values.  */
	  if (irreversible == NULL)
	    /* We are transliterating, don't try to correct anything.  */
	    return __GCONV_ILLEGAL_INPUT;

	  if (flags & __GCONV_IGNORE_ERRORS)
	    {
	      /* Just ignore this character.  */
	      ++*irreversible;
	      continue;
	    }

	  return __GCONV_ILLEGAL_INPUT;
	}

      *((uint32_t *) outptr) = inval;
      outptr = (unsigned char *)((uint32_t *) outptr + 1);
    }

  *inptrp = inptr;
  *outptrp = outptr;

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}

#ifndef _STRING_ARCH_unaligned
static inline int
ucs4le_internal_loop_unaligned (struct __gconv_step *step,
				struct __gconv_step_data *step_data,
				const unsigned char **inptrp,
				const unsigned char *inend,
				unsigned char **outptrp, unsigned char *outend,
				size_t *irreversible)
{
  int flags = step_data->__flags;
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t n_convert = MIN (inend - inptr, outend - outptr) / 4;
  int result;
  size_t cnt;

  for (cnt = 0; cnt < n_convert; ++cnt, inptr += 4)
    {
      if (__builtin_expect (inptr[3] > 0x80, 0))
	{
	  /* The value is too large.  We don't try transliteration here since
	     this is not an error because of the lack of possibilities to
	     represent the result.  This is a genuine bug in the input since
	     UCS4 does not allow such values.  */
	  if (irreversible == NULL)
	    /* We are transliterating, don't try to correct anything.  */
	    return __GCONV_ILLEGAL_INPUT;

	  if (flags & __GCONV_IGNORE_ERRORS)
	    {
	      /* Just ignore this character.  */
	      ++*irreversible;
	      continue;
	    }

	  *inptrp = inptr;
	  *outptrp = outptr;
 	  return __GCONV_ILLEGAL_INPUT;
	}

# if __BYTE_ORDER == __BIG_ENDIAN
      outptr[3] = inptr[0];
      outptr[2] = inptr[1];
      outptr[1] = inptr[2];
      outptr[0] = inptr[3];
# else
      outptr[0] = inptr[0];
      outptr[1] = inptr[1];
      outptr[2] = inptr[2];
      outptr[3] = inptr[3];
# endif

      outptr += 4;
    }

  *inptrp = inptr;
  *outptrp = outptr;

  /* Determine the status.  */
  if (*inptrp == inend)
    result = __GCONV_EMPTY_INPUT;
  else if (*outptrp + 4 > outend)
    result = __GCONV_FULL_OUTPUT;
  else
    result = __GCONV_INCOMPLETE_INPUT;

  return result;
}
#endif


static inline int
ucs4le_internal_loop_single (struct __gconv_step *step,
			     struct __gconv_step_data *step_data,
			     const unsigned char **inptrp,
			     const unsigned char *inend,
			     unsigned char **outptrp, unsigned char *outend,
			     size_t *irreversible)
{
  mbstate_t *state = step_data->__statep;
  int flags = step_data->__flags;
  size_t cnt = state->__count & 7;

  while (*inptrp < inend && cnt < 4)
    state->__value.__wchb[cnt++] = *(*inptrp)++;

  if (__builtin_expect (cnt < 4, 0))
    {
      /* Still not enough bytes.  Store the ones in the input buffer.  */
      state->__count &= ~7;
      state->__count |= cnt;

      return __GCONV_INCOMPLETE_INPUT;
    }

  if (__builtin_expect (((unsigned char *) state->__value.__wchb)[3] > 0x80,
			0))
    {
      /* The value is too large.  We don't try transliteration here since
	 this is not an error because of the lack of possibilities to
	 represent the result.  This is a genuine bug in the input since
	 UCS4 does not allow such values.  */
      if (!(flags & __GCONV_IGNORE_ERRORS))
	return __GCONV_ILLEGAL_INPUT;
    }
  else
    {
#if __BYTE_ORDER == __BIG_ENDIAN
      (*outptrp)[0] = state->__value.__wchb[3];
      (*outptrp)[1] = state->__value.__wchb[2];
      (*outptrp)[2] = state->__value.__wchb[1];
      (*outptrp)[3] = state->__value.__wchb[0];
#elif __BYTE_ORDER == __BIG_ENDIAN
      (*outptrp)[0] = state->__value.__wchb[0];
      (*outptrp)[1] = state->__value.__wchb[1];
      (*outptrp)[2] = state->__value.__wchb[2];
      (*outptrp)[3] = state->__value.__wchb[3];
#endif

      *outptrp += 4;
    }

  /* Clear the state buffer.  */
  state->__count &= ~7;

  return __GCONV_OK;
}

#include <iconv/skeleton.c>


/* Convert from ISO 646-IRV to the internal (UCS4-like) format.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		1
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		ascii_internal_loop
#define TO_LOOP			ascii_internal_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_ascii_internal
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    if (__builtin_expect (*inptr > '\x7f', 0))				      \
      {									      \
	/* The value is too large.  We don't try transliteration here since   \
	   this is not an error because of the lack of possibilities to	      \
	   represent the result.  This is a genuine bug in the input since    \
	   ASCII does not allow such values.  */			      \
	if (! ignore_errors_p ())					      \
	  {								      \
	    /* This is no correct ANSI_X3.4-1968 character.  */		      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
									      \
	*irreversible = *irreversible + 1;				      \
	++inptr;							      \
      }									      \
    else								      \
      { 								      \
        /* It's an one byte sequence.  */				      \
        *((uint32_t *) outptr) = *inptr;				      \
        ++inptr;							      \
        outptr = (unsigned char *)((uint32_t *) outptr + 1);		      \
      }									      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from the internal (UCS4-like) format to ISO 646-IRV.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		1
#define FROM_DIRECTION		1
#define FROM_LOOP		internal_ascii_loop
#define TO_LOOP			internal_ascii_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_internal_ascii
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    if (__builtin_expect (*((const uint32_t *) inptr) > 0x7f, 0))	      \
      {									      \
	UNICODE_TAG_HANDLER (*((const uint32_t *) inptr), 4);		      \
	STANDARD_ERR_HANDLER (4);					      \
      }									      \
    else								      \
      { 								      \
        /* It's an one byte sequence.  */				      \
        *outptr++ = *((const uint32_t *) inptr);			      \
        inptr = ((const uint32_t *) inptr + 1);				      \
      }									      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from the internal (UCS4-like) format to UTF-8.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		1
#define MAX_NEEDED_TO		6
#define FROM_DIRECTION		1
#define FROM_LOOP		internal_utf8_loop
#define TO_LOOP			internal_utf8_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_internal_utf8
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define MAX_NEEDED_OUTPUT	MAX_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint32_t wc = *((const uint32_t *) inptr);				      \
									      \
    if (wc < 0x80)							      \
      /* It's an one byte sequence.  */					      \
      *outptr++ = (unsigned char) wc;					      \
    else if (__builtin_expect (wc <= 0x7fffffff, 1))			      \
      {									      \
	size_t step;							      \
	char *start;							      \
									      \
	for (step = 2; step < 6; ++step)				      \
	  if ((wc & (~(uint32_t)0 << (5 * step + 1))) == 0)		      \
	    break;							      \
									      \
	if (__builtin_expect (outptr + step > outend, 0))		      \
	  {								      \
	    /* Too long.  */						      \
	    result = __GCONV_FULL_OUTPUT;				      \
	    break;							      \
	  }								      \
									      \
	start = outptr;							      \
	*outptr = (unsigned char) (~0xff >> step);			      \
	outptr += step;							      \
	--step;								      \
	do								      \
	  {								      \
	    start[step] = 0x80 | (wc & 0x3f);				      \
	    wc >>= 6;							      \
	  }								      \
	while (--step > 0);						      \
	start[0] |= wc;							      \
      }									      \
    else								      \
      {									      \
	STANDARD_ERR_HANDLER (4);					      \
      }									      \
									      \
    inptr += 4;								      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from UTF-8 to the internal (UCS4-like) format.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		1
#define MAX_NEEDED_FROM		6
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		utf8_internal_loop
#define TO_LOOP			utf8_internal_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_utf8_internal
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MAX_NEEDED_INPUT	MAX_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint32_t ch;							      \
    uint32_t cnt;							      \
    uint32_t i;							      \
									      \
    /* Next input byte.  */						      \
    ch = *inptr;							      \
									      \
    if (ch < 0x80)							      \
      {									      \
	/* One byte sequence.  */					      \
	cnt = 1;							      \
	++inptr;							      \
      }									      \
    else								      \
      {									      \
 	if (ch >= 0xc2 && ch < 0xe0)					      \
	  {								      \
 	    /* We expect two bytes.  The first byte cannot be 0xc0 or 0xc1,   \
 	       otherwise the wide character could have been represented	      \
 	       using a single byte.  */					      \
	    cnt = 2;							      \
	    ch &= 0x1f;							      \
	  }								      \
        else if (__builtin_expect ((ch & 0xf0) == 0xe0, 1))		      \
	  {								      \
	    /* We expect three bytes.  */				      \
	    cnt = 3;							      \
	    ch &= 0x0f;							      \
	  }								      \
	else if (__builtin_expect ((ch & 0xf8) == 0xf0, 1))		      \
	  {								      \
	    /* We expect four bytes.  */				      \
	    cnt = 4;							      \
	    ch &= 0x07;							      \
	  }								      \
	else if (__builtin_expect ((ch & 0xfc) == 0xf8, 1))		      \
	  {								      \
	    /* We expect five bytes.  */				      \
	    cnt = 5;							      \
	    ch &= 0x03;							      \
	  }								      \
	else if (__builtin_expect ((ch & 0xfe) == 0xfc, 1))		      \
	  {								      \
	    /* We expect six bytes.  */					      \
	    cnt = 6;							      \
	    ch &= 0x01;							      \
	  }								      \
	else								      \
	  {								      \
	    int skipped;						      \
									      \
	    if (! ignore_errors_p ())					      \
	      {								      \
		/* This is an illegal encoding.  */			      \
		result = __GCONV_ILLEGAL_INPUT;				      \
		break;							      \
	      }								      \
									      \
	    /* Search the end of this ill-formed UTF-8 character.  This	      \
	       is the next byte with (x & 0xc0) != 0x80.  */		      \
	     skipped = 0;						      \
	     do								      \
	       {							      \
		 ++inptr;						      \
		 ++skipped;						      \
	       }							      \
	     while (inptr < inend && (*inptr & 0xc0) == 0x80 && skipped < 5); \
									      \
	     continue;							      \
	  }								      \
									      \
	if (__builtin_expect (inptr + cnt > inend, 0))			      \
	  {								      \
	    /* We don't have enough input.  But before we report that check   \
	       that all the bytes are correct.  */			      \
	    for (i = 1; inptr + i < inend; ++i)				      \
	      if ((inptr[i] & 0xc0) != 0x80)				      \
		break;							      \
									      \
	    if (__builtin_expect (inptr + i == inend, 1))		      \
	      {								      \
		result = __GCONV_INCOMPLETE_INPUT;			      \
		break;							      \
	      }								      \
									      \
	    if (ignore_errors_p ())					      \
	      {								      \
		/* Ignore it.  */					      \
		inptr += i;						      \
		*irreversible = *irreversible + 1;			      \
		continue;						      \
	      }								      \
									      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
									      \
	/* Read the possible remaining bytes.  */			      \
	for (i = 1; i < cnt; ++i)					      \
	  {								      \
	    uint32_t byte = inptr[i];					      \
									      \
	    if ((byte & 0xc0) != 0x80)					      \
	      /* This is an illegal encoding.  */			      \
	      break;							      \
									      \
	    ch <<= 6;							      \
	    ch |= byte & 0x3f;						      \
	  }								      \
									      \
	/* If i < cnt, some trail byte was not >= 0x80, < 0xc0.		      \
	   If cnt > 2 and ch < 2^(5*cnt-4), the wide character ch could	      \
	   have been represented with fewer than cnt bytes.  */		      \
	if (i < cnt || (cnt > 2 && (ch >> (5 * cnt - 4)) == 0))		      \
	  {								      \
	    /* This is an illegal encoding.  */				      \
	    if (ignore_errors_p ())					      \
	      {								      \
		inptr += i;						      \
		*irreversible = *irreversible + 1;			      \
		continue;						      \
	      }								      \
									      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
									      \
	inptr += cnt;							      \
      }									      \
									      \
    /* Now adjust the pointers and store the result.  */		      \
    *((uint32_t *) outptr) = ch;					      \
    outptr = (unsigned char *)((uint32_t *) outptr + 1);		      \
  }
#define LOOP_NEED_FLAGS

#define STORE_REST \
  {									      \
    /* We store the remaining bytes while converting them into the UCS4	      \
       format.  We can assume that the first byte in the buffer is	      \
       correct and that it requires a larger number of bytes than there	      \
       are in the input buffer.  */					      \
    wint_t ch = **inptrp;						      \
    size_t cnt;								      \
									      \
    state->__count = inend - *inptrp;					      \
									      \
    if (ch >= 0xc2 && ch < 0xe0)					      \
      {									      \
	/* We expect two bytes.  The first byte cannot be 0xc0 or	      \
	   0xc1, otherwise the wide character could have been		      \
	   represented using a single byte.  */				      \
	cnt = 2;							      \
	ch &= 0x1f;							      \
      }									      \
    else if (__builtin_expect ((ch & 0xf0) == 0xe0, 1))			      \
      {									      \
	/* We expect three bytes.  */					      \
	cnt = 3;							      \
	ch &= 0x0f;							      \
      }									      \
    else if (__builtin_expect ((ch & 0xf8) == 0xf0, 1))			      \
      {									      \
	/* We expect four bytes.  */					      \
	cnt = 4;							      \
	ch &= 0x07;							      \
      }									      \
    else if (__builtin_expect ((ch & 0xfc) == 0xf8, 1))			      \
      {									      \
	/* We expect five bytes.  */					      \
	cnt = 5;							      \
	ch &= 0x03;							      \
      }									      \
    else								      \
      {									      \
	/* We expect six bytes.  */					      \
	cnt = 6;							      \
	ch &= 0x01;							      \
      }									      \
									      \
    /* The first byte is already consumed.  */				      \
    --cnt;								      \
    while (++(*inptrp) < inend)						      \
      {									      \
	ch <<= 6;							      \
	ch |= **inptrp & 0x3f;						      \
	--cnt;								      \
      }									      \
									      \
    /* Shift for the so far missing bytes.  */				      \
    ch <<= cnt * 6;							      \
									      \
    /* Store the value.  */						      \
    state->__value.__wch = ch;						      \
  }

#define UNPACK_BYTES \
  {									      \
    wint_t wch = state->__value.__wch;					      \
    size_t ntotal;							      \
    inlen = state->__count;						      \
									      \
    if (state->__value.__wch <= 0x7ff)					      \
      {									      \
	bytebuf[0] = 0xc0;						      \
	ntotal = 2;							      \
      }									      \
    else if (__builtin_expect (state->__value.__wch <= 0xffff, 1))	      \
      {									      \
	bytebuf[0] = 0xe0;						      \
	ntotal = 3;							      \
      }									      \
    else if (__builtin_expect (state->__value.__wch < 0x1fffff, 1))	      \
      {									      \
	bytebuf[0] = 0xf0;						      \
	ntotal = 4;							      \
      }									      \
    else if (__builtin_expect (state->__value.__wch < 0x3ffffff, 1))	      \
      {									      \
	bytebuf[0] = 0xf8;						      \
	ntotal = 5;							      \
      }									      \
    else								      \
      {									      \
	bytebuf[0] = 0xfc;						      \
	ntotal = 6;							      \
      }									      \
									      \
    do									      \
      {									      \
	if (--ntotal < inlen)						      \
	  bytebuf[ntotal] = 0x80 | (wch & 0x3f);			      \
	wch >>= 6;							      \
      }									      \
    while (ntotal > 1);							      \
									      \
    bytebuf[0] |= wch;							      \
  }

#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from UCS2 to the internal (UCS4-like) format.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		2
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		ucs2_internal_loop
#define TO_LOOP			ucs2_internal_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_ucs2_internal
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint16_t u1 = *((const uint16_t *) inptr);				      \
									      \
    if (__builtin_expect (u1 >= 0xd800 && u1 < 0xe000, 0))		      \
      {									      \
	/* Surrogate characters in UCS-2 input are not valid.  Reject	      \
	   them.  (Catching this here is not security relevant.)  */	      \
	if (! ignore_errors_p ())					      \
	  {								      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
	inptr += 2;							      \
	*irreversible = *irreversible + 1;				      \
	continue;							      \
      }									      \
									      \
    *((uint32_t *) outptr) = u1;					      \
    outptr = (unsigned char *)((uint32_t *) outptr + 1);		      \
    inptr += 2;								      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from the internal (UCS4-like) format to UCS2.  */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		2
#define FROM_DIRECTION		1
#define FROM_LOOP		internal_ucs2_loop
#define TO_LOOP			internal_ucs2_loop /* This is not used.  */
#define FUNCTION_NAME		__gconv_transform_internal_ucs2
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint32_t val = *((const uint32_t *) inptr);				      \
									      \
    if (__builtin_expect (val >= 0x10000, 0))				      \
      {									      \
	UNICODE_TAG_HANDLER (val, 4);					      \
	STANDARD_ERR_HANDLER (4);					      \
      }									      \
    else if (__builtin_expect (val >= 0xd800 && val < 0xe000, 0))	      \
      {									      \
	/* Surrogate characters in UCS-4 input are not valid.		      \
	   We must catch this, because the UCS-2 output might be	      \
	   interpreted as UTF-16 by other programs.  If we let		      \
	   surrogates pass through, attackers could make a security	      \
	   hole exploit by synthesizing any desired plane 1-16		      \
	   character.  */						      \
	if (! ignore_errors_p ())					      \
	  {								      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
	inptr += 4;							      \
	*irreversible = *irreversible + 1;				      \
	continue;							      \
      }									      \
    else 								      \
      {									      \
	*((uint16_t *) outptr) = val;					      \
	outptr = (unsigned char *)((uint16_t *) outptr + 1);		      \
	inptr += 4;							      \
      }									      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from UCS2 in other endianness to the internal (UCS4-like) format. */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		2
#define MIN_NEEDED_TO		4
#define FROM_DIRECTION		1
#define FROM_LOOP		ucs2reverse_internal_loop
#define TO_LOOP			ucs2reverse_internal_loop/* This is not used.*/
#define FUNCTION_NAME		__gconv_transform_ucs2reverse_internal
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint16_t u1 = bswap_16 (*((const uint16_t *) inptr));		      \
									      \
    if (__builtin_expect (u1 >= 0xd800 && u1 < 0xe000, 0))		      \
      {									      \
	/* Surrogate characters in UCS-2 input are not valid.  Reject	      \
	   them.  (Catching this here is not security relevant.)  */	      \
	if (! ignore_errors_p ())					      \
	  {								      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
	inptr += 2;							      \
	*irreversible = *irreversible + 1;				      \
	continue;							      \
      }									      \
									      \
    *((uint32_t *) outptr) = u1;					      \
    outptr = (unsigned char *)((uint32_t *) outptr + 1);		      \
    inptr += 2;								      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>


/* Convert from the internal (UCS4-like) format to UCS2 in other endianness. */
#define DEFINE_INIT		0
#define DEFINE_FINI		0
#define MIN_NEEDED_FROM		4
#define MIN_NEEDED_TO		2
#define FROM_DIRECTION		1
#define FROM_LOOP		internal_ucs2reverse_loop
#define TO_LOOP			internal_ucs2reverse_loop/* This is not used.*/
#define FUNCTION_NAME		__gconv_transform_internal_ucs2reverse
#define ONE_DIRECTION		1

#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint32_t val = *((const uint32_t *) inptr);				      \
    if (__builtin_expect (val >= 0x10000, 0))				      \
      {									      \
	UNICODE_TAG_HANDLER (val, 4);					      \
	STANDARD_ERR_HANDLER (4);					      \
      }									      \
    else if (__builtin_expect (val >= 0xd800 && val < 0xe000, 0))	      \
      {									      \
	/* Surrogate characters in UCS-4 input are not valid.		      \
	   We must catch this, because the UCS-2 output might be	      \
	   interpreted as UTF-16 by other programs.  If we let		      \
	   surrogates pass through, attackers could make a security	      \
	   hole exploit by synthesizing any desired plane 1-16		      \
	   character.  */						      \
	if (! ignore_errors_p ())					      \
	  {								      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
	inptr += 4;							      \
	*irreversible = *irreversible + 1;				      \
	continue;							      \
      }									      \
    else 								      \
      {									      \
	*((uint16_t *) outptr) = bswap_16 (val);			      \
	outptr = (unsigned char *)((uint16_t *) outptr + 1);		      \
	inptr += 4;							      \
      }									      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>
#include <iconv/skeleton.c>
