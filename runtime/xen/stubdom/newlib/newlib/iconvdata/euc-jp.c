/* Mapping tables for EUC-JP handling.
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

#include <dlfcn.h>
#include <stdint.h>
#include <gconv.h>
#include <jis0201.h>
#include <jis0208.h>
#include <jis0212.h>

/* Definitions used in the body of the `gconv' function.  */
#define CHARSET_NAME		"EUC-JP//"
#define FROM_LOOP		from_euc_jp
#define TO_LOOP			to_euc_jp
#define DEFINE_INIT		1
#define DEFINE_FINI		1
#define MIN_NEEDED_FROM		1
#define MAX_NEEDED_FROM		3
#define MIN_NEEDED_TO		4


/* First define the conversion function from EUC-JP to UCS4.  */
#define MIN_NEEDED_INPUT	MIN_NEEDED_FROM
#define MAX_NEEDED_INPUT	MAX_NEEDED_FROM
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_TO
#define LOOPFCT			FROM_LOOP
#define BODY \
  {									      \
    uint32_t ch = *inptr;						      \
									      \
    if (ch < 0x8e || (ch >= 0x90 && ch <= 0x9f))			      \
      ++inptr;								      \
    else if (ch == 0xff)						      \
      {									      \
	/* This is illegal.  */						      \
	if (! ignore_errors_p ())					      \
	  {								      \
	    result = __GCONV_ILLEGAL_INPUT;				      \
	    break;							      \
	  }								      \
									      \
	++inptr;							      \
	++*irreversible;						      \
	continue;							      \
      }									      \
    else								      \
      {									      \
	/* Two or more byte character.  First test whether the next	      \
	   character is also available.  */				      \
	int ch2;							      \
									      \
	if (__builtin_expect (inptr + 1 >= inend, 0))			      \
	  {								      \
	    /* The second character is not available.  Store the	      \
	       intermediate result.  */					      \
	    result = __GCONV_INCOMPLETE_INPUT;				      \
	    break;							      \
	  }								      \
									      \
	ch2 = inptr[1];							      \
									      \
	/* All second bytes of a multibyte character must be >= 0xa1. */      \
	if (__builtin_expect (ch2 < 0xa1, 0))				      \
	  {								      \
	    /* This is an illegal character.  */			      \
	    if (! ignore_errors_p ())					      \
	      {								      \
		result = __GCONV_ILLEGAL_INPUT;				      \
		break;							      \
	      }								      \
									      \
	    ++inptr;							      \
	    ++*irreversible;						      \
	    continue;							      \
	  }								      \
									      \
	if (ch == 0x8e)							      \
	  {								      \
	    /* This is code set 2: half-width katakana.  */		      \
	    ch = jisx0201_to_ucs4 (ch2);				      \
	    if (__builtin_expect (ch, 0) == __UNKNOWN_10646_CHAR)	      \
	      {								      \
		/* Illegal character.  */				      \
		if (! ignore_errors_p ())				      \
		  {							      \
		    /* This is an illegal character.  */		      \
		    result = __GCONV_ILLEGAL_INPUT;			      \
		    break;						      \
		  }							      \
	      }								      \
									      \
	    inptr += 2;							      \
	  }								      \
	else								      \
	  {								      \
	    const unsigned char *endp;					      \
									      \
	    if (ch == 0x8f)						      \
	      {								      \
		/* This is code set 3: JIS X 0212-1990.  */		      \
		endp = inptr + 1;					      \
									      \
		ch = jisx0212_to_ucs4 (&endp, inend - endp, 0x80);	      \
	      }								      \
	    else							      \
	      {								      \
		/* This is code set 1: JIS X 0208.  */			      \
		endp = inptr;						      \
									      \
		ch = jisx0208_to_ucs4 (&endp, inend - inptr, 0x80);	      \
	      }								      \
									      \
	    if (__builtin_expect (ch, 1) == 0)				      \
	      {								      \
		/* Not enough input available.  */			      \
		result = __GCONV_INCOMPLETE_INPUT;			      \
		break;							      \
	      }								      \
	    if (__builtin_expect (ch, 0) == __UNKNOWN_10646_CHAR)	      \
	      {								      \
		/* Illegal character.  */				      \
		if (! ignore_errors_p ())				      \
		  {							      \
		    /* This is an illegal character.  */		      \
		    result = __GCONV_ILLEGAL_INPUT;			      \
		    break;						      \
		  }							      \
									      \
		inptr += 2;						      \
		++*irreversible;					      \
		continue;						      \
	      }								      \
	    inptr = endp;						      \
	  }								      \
      }									      \
									      \
    put32 (outptr, ch);							      \
    outptr += 4;							      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>


/* Next, define the other direction.  */
#define MIN_NEEDED_INPUT	MIN_NEEDED_TO
#define MIN_NEEDED_OUTPUT	MIN_NEEDED_FROM
#define MAX_NEEDED_OUTPUT	MAX_NEEDED_FROM
#define LOOPFCT			TO_LOOP
#define BODY \
  {									      \
    uint32_t ch = get32 (inptr);					      \
									      \
    if (ch < 0x8e || (ch >= 0x90 && ch <= 0x9f))			      \
      /* It's plain ASCII or C1.  */					      \
      *outptr++ = ch;							      \
    else if (ch == 0xa5)						      \
      /* YEN sign => backslash  */					      \
      *outptr++ = 0x5c;							      \
    else if (ch == 0x203e)						      \
      /* overscore => asciitilde */					      \
      *outptr++ = 0x7e;							      \
    else								      \
      {									      \
	/* Try the JIS character sets.  */				      \
	size_t found;							      \
									      \
	/* See whether we have room for at least two characters.  */	      \
	if (__builtin_expect (outptr + 1 >= outend, 0))			      \
	  {								      \
	    result = __GCONV_FULL_OUTPUT;				      \
	    break;							      \
	  }								      \
									      \
	found = ucs4_to_jisx0201 (ch, outptr + 1);			      \
	if (found != __UNKNOWN_10646_CHAR)				      \
	  {								      \
	    /* Yes, it's a JIS 0201 character.  Store the shift byte.  */     \
	    *outptr = 0x8e;						      \
	    outptr += 2;						      \
	  }								      \
	else								      \
	  {								      \
	    /* No JIS 0201 character.  */				      \
	    found = ucs4_to_jisx0208 (ch, outptr, 2);			      \
	    /* Please note that we always have enough room for the output. */ \
	    if (found != __UNKNOWN_10646_CHAR)				      \
	      {								      \
		/* It's a JIS 0208 character, adjust it for EUC-JP.  */	      \
		*outptr++ += 0x80;					      \
		*outptr++ += 0x80;					      \
	      }								      \
	    else							      \
	      {								      \
		/* No JIS 0208 character.  */				      \
		found = ucs4_to_jisx0212 (ch, outptr + 1,		      \
					  outend - outptr - 1);		      \
		  							      \
		if (__builtin_expect (found, 1) == 0)			      \
		  {							      \
		    /* We ran out of space.  */				      \
		    result = __GCONV_FULL_OUTPUT;			      \
		    break;						      \
		  }							      \
		else if (__builtin_expect (found, 0) != __UNKNOWN_10646_CHAR) \
		  {							      \
		    /* It's a JIS 0212 character, adjust it for EUC-JP.  */   \
		    *outptr++ = 0x8f;					      \
		    *outptr++ += 0x80;					      \
		    *outptr++ += 0x80;					      \
		  }							      \
		else							      \
		  {							      \
		    UNICODE_TAG_HANDLER (ch, 4);			      \
									      \
		    /* Illegal character.  */				      \
		    STANDARD_ERR_HANDLER (4);				      \
		  }							      \
	      }								      \
	  }								      \
      }									      \
									      \
    inptr += 4;								      \
  }
#define LOOP_NEED_FLAGS
#include <iconv/loop.c>


/* Now define the toplevel functions.  */
#include <iconv/skeleton.c>
