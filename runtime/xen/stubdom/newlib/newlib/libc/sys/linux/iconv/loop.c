/* Conversion loop frame work.
   Copyright (C) 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1998.

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

/* This file provides a frame for the reader loop in all conversion modules.
   The actual code must (of course) be provided in the actual module source
   code but certain actions can be written down generically, with some
   customization options which are these:

     MIN_NEEDED_INPUT	minimal number of input bytes needed for the next
			conversion.
     MIN_NEEDED_OUTPUT	minimal number of bytes produced by the next round
			of conversion.

     MAX_NEEDED_INPUT	you guess it, this is the maximal number of input
			bytes needed.  It defaults to MIN_NEEDED_INPUT
     MAX_NEEDED_OUTPUT	likewise for output bytes.

     LOOPFCT		name of the function created.  If not specified
			the name is `loop' but this prevents the use
			of multiple functions in the same file.

     BODY		this is supposed to expand to the body of the loop.
			The user must provide this.

     EXTRA_LOOP_DECLS	extra arguments passed from converion loop call.

     INIT_PARAMS	code to define and initialize variables from params.
     UPDATE_PARAMS	code to store result in params.
*/

#include <assert.h>
#include <machine/endian.h>
#include <gconv.h>
#include <stdint.h>
#include <string.h>
#include <wchar.h>
#include <sys/param.h>		/* For MIN.  */
#define __need_size_t
#include <stddef.h>


/* We have to provide support for machines which are not able to handled
   unaligned memory accesses.  Some of the character encodings have
   representations with a fixed width of 2 or 4 bytes.  But if we cannot
   access unaligned memory we still have to read byte-wise.  */
#undef FCTNAME2
#if defined _STRING_ARCH_unaligned || !defined DEFINE_UNALIGNED
/* We can handle unaligned memory access.  */
# define get16(addr) *((__const uint16_t *) (addr))
# define get32(addr) *((__const uint32_t *) (addr))

/* We need no special support for writing values either.  */
# define put16(addr, val) *((uint16_t *) (addr)) = (val)
# define put32(addr, val) *((uint32_t *) (addr)) = (val)

# define FCTNAME2(name) name
#else
/* Distinguish between big endian and little endian.  */
# if __BYTE_ORDER == __LITTLE_ENDIAN
#  define get16(addr) \
     (((__const unsigned char *) (addr))[1] << 8			      \
      | ((__const unsigned char *) (addr))[0])
#  define get32(addr) \
     (((((__const unsigned char *) (addr))[3] << 8			      \
	| ((__const unsigned char *) (addr))[2]) << 8			      \
       | ((__const unsigned char *) (addr))[1]) << 8			      \
      | ((__const unsigned char *) (addr))[0])

#  define put16(addr, val) \
     ({ uint16_t __val = (val);						      \
	((unsigned char *) (addr))[0] = __val;				      \
	((unsigned char *) (addr))[1] = __val >> 8;			      \
	(void) 0; })
#  define put32(addr, val) \
     ({ uint32_t __val = (val);						      \
	((unsigned char *) (addr))[0] = __val;				      \
	__val >>= 8;							      \
	((unsigned char *) (addr))[1] = __val;				      \
	__val >>= 8;							      \
	((unsigned char *) (addr))[2] = __val;				      \
	__val >>= 8;							      \
	((unsigned char *) (addr))[3] = __val;				      \
	(void) 0; })
# else
#  define get16(addr) \
     (((__const unsigned char *) (addr))[0] << 8			      \
      | ((__const unsigned char *) (addr))[1])
#  define get32(addr) \
     (((((__const unsigned char *) (addr))[0] << 8			      \
	| ((__const unsigned char *) (addr))[1]) << 8			      \
       | ((__const unsigned char *) (addr))[2]) << 8			      \
      | ((__const unsigned char *) (addr))[3])

#  define put16(addr, val) \
     ({ uint16_t __val = (val);						      \
	((unsigned char *) (addr))[1] = __val;				      \
	((unsigned char *) (addr))[0] = __val >> 8;			      \
	(void) 0; })
#  define put32(addr, val) \
     ({ uint32_t __val = (val);						      \
	((unsigned char *) (addr))[3] = __val;				      \
	__val >>= 8;							      \
	((unsigned char *) (addr))[2] = __val;				      \
	__val >>= 8;							      \
	((unsigned char *) (addr))[1] = __val;				      \
	__val >>= 8;							      \
	((unsigned char *) (addr))[0] = __val;				      \
	(void) 0; })
# endif

# define FCTNAME2(name) name##_unaligned
#endif
#define FCTNAME(name) FCTNAME2(name)


/* We need at least one byte for the next round.  */
#ifndef MIN_NEEDED_INPUT
# error "MIN_NEEDED_INPUT definition missing"
#endif

/* Let's see how many bytes we produce.  */
#ifndef MAX_NEEDED_INPUT
# define MAX_NEEDED_INPUT	MIN_NEEDED_INPUT
#endif

/* We produce at least one byte in the next round.  */
#ifndef MIN_NEEDED_OUTPUT
# error "MIN_NEEDED_OUTPUT definition missing"
#endif

/* Let's see how many bytes we produce.  */
#ifndef MAX_NEEDED_OUTPUT
# define MAX_NEEDED_OUTPUT	MIN_NEEDED_OUTPUT
#endif

/* Default name for the function.  */
#ifndef LOOPFCT
# define LOOPFCT		loop
#endif

/* Make sure we have a loop body.  */
#ifndef BODY
# error "Definition of BODY missing for function" LOOPFCT
#endif


/* If no arguments have to passed to the loop function define the macro
   as empty.  */
#ifndef EXTRA_LOOP_DECLS
# define EXTRA_LOOP_DECLS
#endif


/* To make it easier for the writers of the modules, we define a macro
   to test whether we have to ignore errors.  */
#define ignore_errors_p() \
  (irreversible != NULL && (flags & __GCONV_IGNORE_ERRORS))


/* Error handling with transliteration/transcription function use and
   ignoring of errors.  Note that we cannot use the do while (0) trick
   since `break' and `continue' must reach certain points.  */
#define STANDARD_ERR_HANDLER(Incr) \
  {									      \
    struct __gconv_trans_data *trans;					      \
									      \
    result = __GCONV_ILLEGAL_INPUT;					      \
									      \
    if (irreversible == NULL)						      \
      /* This means we are in call from __gconv_transliterate.  In this	      \
	 case we are not doing any error recovery outself.  */		      \
      break;								      \
									      \
    /* First try the transliteration methods.  */			      \
    for (trans = step_data->__trans; trans != NULL; trans = trans->__next)    \
      {									      \
	result = trans->__trans_fct (step, step_data, trans->__data, *inptrp, \
			       &inptr, inend, &outptr, irreversible);	      \
	if (result != __GCONV_ILLEGAL_INPUT)				      \
	  break;							      \
      }									      \
    /* If any of them recognized the input continue with the loop.  */	      \
    if (result != __GCONV_ILLEGAL_INPUT)				      \
      continue;								      \
									      \
    /* Next see whether we have to ignore the error.  If not, stop.  */	      \
    if (! ignore_errors_p ())						      \
      break;								      \
									      \
    /* When we come here it means we ignore the character.  */		      \
    ++*irreversible;							      \
    inptr += Incr;							      \
    continue;								      \
  }


/* Handling of Unicode 3.1 TAG characters.  Unicode recommends
   "If language codes are not relevant to the particular processing
    operation, then they should be ignored."
   This macro is usually called right before STANDARD_ERR_HANDLER (Incr).  */
#define UNICODE_TAG_HANDLER(Character, Incr) \
  {									      \
    /* TAG characters are those in the range U+E0000..U+E007F.  */	      \
    if (((Character) >> 7) == (0xe0000 >> 7))				      \
      {									      \
	inptr += Incr;							      \
	continue;							      \
      }									      \
  }


/* The function returns the status, as defined in gconv.h.  */
static inline int
FCTNAME (LOOPFCT) (struct __gconv_step *step,
		   struct __gconv_step_data *step_data,
		   const unsigned char **inptrp, const unsigned char *inend,
		   unsigned char **outptrp, const unsigned char *outend,
		   size_t *irreversible EXTRA_LOOP_DECLS)
{
#ifdef LOOP_NEED_STATE
  mbstate_t *state = step_data->__statep;
#endif
#ifdef LOOP_NEED_FLAGS
  int flags = step_data->__flags;
#endif
#ifdef LOOP_NEED_DATA
  void *data = step->__data;
#endif
  int result = __GCONV_EMPTY_INPUT;
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;

#ifdef INIT_PARAMS
  INIT_PARAMS;
#endif

  while (inptr != inend)
    {
      /* `if' cases for MIN_NEEDED_OUTPUT ==/!= 1 is made to help the
	 compiler generating better code.  They will be optimized away
	 since MIN_NEEDED_OUTPUT is always a constant.  */
      if ((MIN_NEEDED_OUTPUT != 1
	   && __builtin_expect (outptr + MIN_NEEDED_OUTPUT > outend, 0))
	  || (MIN_NEEDED_OUTPUT == 1
	      && __builtin_expect (outptr >= outend, 0)))
	{
	  /* Overflow in the output buffer.  */
	  result = __GCONV_FULL_OUTPUT;
	  break;
	}
      if (MIN_NEEDED_INPUT > 1
	  && __builtin_expect (inptr + MIN_NEEDED_INPUT > inend, 0))
	{
	  /* We don't have enough input for another complete input
	     character.  */
	  result = __GCONV_INCOMPLETE_INPUT;
	  break;
	}

      /* Here comes the body the user provides.  It can stop with
	 RESULT set to GCONV_INCOMPLETE_INPUT (if the size of the
	 input characters vary in size), GCONV_ILLEGAL_INPUT, or
	 GCONV_FULL_OUTPUT (if the output characters vary in size).  */
      BODY
    }

  /* Update the pointers pointed to by the parameters.  */
  *inptrp = inptr;
  *outptrp = outptr;
#ifdef UPDATE_PARAMS
  UPDATE_PARAMS;
#endif

  return result;
}


/* Include the file a second time to define the function to handle
   unaligned access.  */
#if !defined DEFINE_UNALIGNED && !defined _STRING_ARCH_unaligned \
    && MIN_NEEDED_FROM != 1 && MAX_NEEDED_FROM % MIN_NEEDED_FROM == 0 \
    && MIN_NEEDED_TO != 1 && MAX_NEEDED_TO % MIN_NEEDED_TO == 0
# undef get16
# undef get32
# undef put16
# undef put32
# undef unaligned

# define DEFINE_UNALIGNED
# include "loop.c"
# undef DEFINE_UNALIGNED
#endif


#if MAX_NEEDED_INPUT > 1
# define SINGLE(fct) SINGLE2 (fct)
# define SINGLE2(fct) fct##_single
static inline int
SINGLE(LOOPFCT) (struct __gconv_step *step,
		 struct __gconv_step_data *step_data,
		 const unsigned char **inptrp, const unsigned char *inend,
		 unsigned char **outptrp, unsigned char *outend,
		 size_t *irreversible EXTRA_LOOP_DECLS)
{
  mbstate_t *state = step_data->__statep;
#ifdef LOOP_NEED_FLAGS
  int flags = step_data->__flags;
#endif
#ifdef LOOP_NEED_DATA
  void *data = step->__data;
#endif
  int result = __GCONV_OK;
  unsigned char bytebuf[MAX_NEEDED_INPUT];
  const unsigned char *inptr = *inptrp;
  unsigned char *outptr = *outptrp;
  size_t inlen;

#ifdef INIT_PARAMS
  INIT_PARAMS;
#endif

#ifdef UNPACK_BYTES
  UNPACK_BYTES
#else
  /* Add the bytes from the state to the input buffer.  */
  for (inlen = 0; inlen < (size_t) (state->__count & 7); ++inlen)
    bytebuf[inlen] = state->__value.__wchb[inlen];
#endif

  /* Are there enough bytes in the input buffer?  */
  if (__builtin_expect (inptr + (MIN_NEEDED_INPUT - inlen) > inend, 0))
    {
      *inptrp = inend;
#ifdef STORE_REST
      inptr = bytebuf;
      inptrp = &inptr;
      inend = &bytebuf[inlen];

      STORE_REST
#else
      /* We don't have enough input for another complete input
	 character.  */
      while (inptr < inend)
	state->__value.__wchb[inlen++] = *inptr++;
#endif

      return __GCONV_INCOMPLETE_INPUT;
    }

  /* Enough space in output buffer.  */
  if ((MIN_NEEDED_OUTPUT != 1 && outptr + MIN_NEEDED_OUTPUT > outend)
      || (MIN_NEEDED_OUTPUT == 1 && outptr >= outend))
    /* Overflow in the output buffer.  */
    return __GCONV_FULL_OUTPUT;

  /*  Now add characters from the normal input buffer.  */
  do
    bytebuf[inlen++] = *inptr++;
  while (inlen < MAX_NEEDED_INPUT && inptr < inend);

  inptr = bytebuf;
  inend = &bytebuf[inlen];

  do
    {
      BODY
    }
  while (0);

  /* Now we either have produced an output character and consumed all the
     bytes from the state and at least one more, or the character is still
     incomplete, or we have some other error (like illegal input character,
     no space in output buffer).  */
  if (__builtin_expect (inptr != bytebuf, 1))
    {
      /* We found a new character.  */
      assert (inptr - bytebuf > (state->__count & 7));

      *inptrp += inptr - bytebuf - (state->__count & 7);
      *outptrp = outptr;

      result = __GCONV_OK;

      /* Clear the state buffer.  */
      state->__count &= ~7;
    }
  else if (result == __GCONV_INCOMPLETE_INPUT)
    {
      /* This can only happen if we have less than MAX_NEEDED_INPUT bytes
	 available.  */
      assert (inend != &bytebuf[MAX_NEEDED_INPUT]);

      *inptrp += inend - bytebuf - (state->__count & 7);
#ifdef STORE_REST
      inptrp = &inptr;

      STORE_REST
#else
      /* We don't have enough input for another complete input
	 character.  */
      while (inptr < inend)
	state->__value.__wchb[inlen++] = *inptr++;
#endif
    }

  return result;
}
# undef SINGLE
# undef SINGLE2
#endif


/* We remove the macro definitions so that we can include this file again
   for the definition of another function.  */
#undef MIN_NEEDED_INPUT
#undef MAX_NEEDED_INPUT
#undef MIN_NEEDED_OUTPUT
#undef MAX_NEEDED_OUTPUT
#undef LOOPFCT
#undef BODY
#undef LOOPFCT
#undef EXTRA_LOOP_DECLS
#undef INIT_PARAMS
#undef UPDATE_PARAMS
#undef UNPACK_BYTES
#undef LOOP_NEED_STATE
#undef LOOP_NEED_FLAGS
#undef LOOP_NEED_DATA
#undef get16
#undef get32
#undef put16
#undef put32
#undef unaligned
