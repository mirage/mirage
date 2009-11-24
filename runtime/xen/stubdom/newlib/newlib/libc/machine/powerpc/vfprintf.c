/*
FUNCTION
<<vprintf>>, <<vfprintf>>, <<vsprintf>>---format argument list

INDEX
	vprintf
INDEX
	vfprintf
INDEX
	vsprintf
INDEX
	vsnprintf

ANSI_SYNOPSIS
	#include <stdio.h>
	#include <stdarg.h>
	int vprintf(const char *<[fmt]>, va_list <[list]>);
	int vfprintf(FILE *<[fp]>, const char *<[fmt]>, va_list <[list]>);
	int vsprintf(char *<[str]>, const char *<[fmt]>, va_list <[list]>);
	int vsnprintf(char *<[str]>, size_t <[size]>, const char *<[fmt]>, va_list <[list]>);

	int _vprintf_r(void *<[reent]>, const char *<[fmt]>,
                        va_list <[list]>);
	int _vfprintf_r(void *<[reent]>, FILE *<[fp]>, const char *<[fmt]>,
                        va_list <[list]>);
	int _vsprintf_r(void *<[reent]>, char *<[str]>, const char *<[fmt]>,
                        va_list <[list]>);
	int _vsnprintf_r(void *<[reent]>, char *<[str]>, size_t <[size]>, const char *<[fmt]>,
                        va_list <[list]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	#include <varargs.h>
	int vprintf( <[fmt]>, <[list]>)
	char *<[fmt]>;
	va_list <[list]>;

	int vfprintf(<[fp]>, <[fmt]>, <[list]>)
	FILE *<[fp]>;
	char *<[fmt]>;
	va_list <[list]>;

	int vsprintf(<[str]>, <[fmt]>, <[list]>)
	char *<[str]>;
	char *<[fmt]>;
	va_list <[list]>;

	int vsnprintf(<[str]>, <[size]>, <[fmt]>, <[list]>)
	char *<[str]>;
        size_t <[size]>;
	char *<[fmt]>;
	va_list <[list]>;

	int _vprintf_r(<[reent]>, <[fmt]>, <[list]>)
	char *<[reent]>;
	char *<[fmt]>;
	va_list <[list]>;

	int _vfprintf_r(<[reent]>, <[fp]>, <[fmt]>, <[list]>)
	char *<[reent]>;
	FILE *<[fp]>;
	char *<[fmt]>;
	va_list <[list]>;

	int _vsprintf_r(<[reent]>, <[str]>, <[fmt]>, <[list]>)
	char *<[reent]>;
	char *<[str]>;
	char *<[fmt]>;
	va_list <[list]>;

	int _vsnprintf_r(<[reent]>, <[str]>, <[size]>, <[fmt]>, <[list]>)
	char *<[reent]>;
	char *<[str]>;
        size_t <[size]>;
	char *<[fmt]>;
	va_list <[list]>;

DESCRIPTION
<<vprintf>>, <<vfprintf>>, <<vsprintf>> and <<vsnprintf>> are (respectively)
variants of <<printf>>, <<fprintf>>, <<sprintf>> and <<snprintf>>.  They differ
only in allowing their caller to pass the variable argument list as a
<<va_list>> object (initialized by <<va_start>>) rather than directly
accepting a variable number of arguments.

RETURNS
The return values are consistent with the corresponding functions:
<<vsprintf>> returns the number of bytes in the output string,
save that the concluding <<NULL>> is not counted.
<<vprintf>> and <<vfprintf>> return the number of characters transmitted.
If an error occurs, <<vprintf>> and <<vfprintf>> return <<EOF>>. No
error returns occur for <<vsprintf>>.

PORTABILITY
ANSI C requires all three functions.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

/*-
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Chris Torek.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#if defined(LIBC_SCCS) && !defined(lint)
/*static char *sccsid = "from: @(#)vfprintf.c	5.50 (Berkeley) 12/16/92";*/
static char *rcsid = "$Id: vfprintf.c,v 1.13 2007/03/29 06:25:44 nickc Exp $";
#endif /* LIBC_SCCS and not lint */

/*
 * Actual printf innards.
 *
 * This code is large and complicated...
 */

#ifdef INTEGER_ONLY
#define VFPRINTF vfiprintf
#define _VFPRINTF_R _vfiprintf_r
#else
#define VFPRINTF vfprintf
#define _VFPRINTF_R _vfprintf_r
#ifndef NO_FLOATING_POINT
#define FLOATING_POINT
#endif
#endif

#include <_ansi.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <reent.h>
#include <wchar.h>
#include <string.h>
#ifdef __ALTIVEC__
#include <altivec.h>
#endif

#ifdef _HAVE_STDC
#include <stdarg.h>
#else
#include <varargs.h>
#endif

#include "local.h"
#include "fvwrite.h"
#include "vfieeefp.h"

/* Currently a test is made to see if long double processing is warranted.
   This could be changed in the future should the _ldtoa_r code be
   preferred over _dtoa_r.  */
#define _NO_LONGDBL
#if defined _WANT_IO_LONG_DOUBLE && (LDBL_MANT_DIG > DBL_MANT_DIG)
#undef _NO_LONGDBL
#endif

#define _NO_LONGLONG
#if defined _WANT_IO_LONG_LONG && defined __GNUC__
# undef _NO_LONGLONG
#endif

#ifdef __ALTIVEC__
typedef union
{
  vector int v;
  float f[4];
  int   i[16 / sizeof(int)];
  long  l[4];
  short s[8];
  signed char c[16];
} vec_16_byte_union;
#endif /* __ALTIVEC__ */

/*
 * Flush out all the vectors defined by the given uio,
 * then reset it so that it can be reused.
 */
static int
__sprint_r(rptr, fp, uio)
	struct _reent *rptr;
	FILE *fp;
	register struct __suio *uio;
{
	register int err;

	if (uio->uio_resid == 0) {
		uio->uio_iovcnt = 0;
		return (0);
	}
	err = __sfvwrite_r(rptr, fp, uio);
	uio->uio_resid = 0;
	uio->uio_iovcnt = 0;
	return (err);
}

/*
 * Helper function for `fprintf to unbuffered unix file': creates a
 * temporary buffer.  We only work on write-only files; this avoids
 * worries about ungetc buffers and so forth.
 */
static int
__sbprintf_r(rptr, fp, fmt, ap)
	struct _reent *rptr;
	register FILE *fp;
	const char *fmt;
	va_list ap;
{
	int ret;
	FILE fake;
	unsigned char buf[BUFSIZ];

	/* copy the important variables */
	fake._flags = fp->_flags & ~__SNBF;
	fake._file = fp->_file;
	fake._cookie = fp->_cookie;
	fake._write = fp->_write;

	/* set up the buffer */
	fake._bf._base = fake._p = buf;
	fake._bf._size = fake._w = sizeof(buf);
	fake._lbfsize = 0;	/* not actually used, but Just In Case */

	/* do the work, then copy any error status */
	ret = _VFPRINTF_R(rptr, &fake, fmt, ap);
	if (ret >= 0 && fflush(&fake))
		ret = EOF;
	if (fake._flags & __SERR)
		fp->_flags |= __SERR;
	return (ret);
}


#ifdef FLOATING_POINT
#include <locale.h>
#include <math.h>
#include "floatio.h"

#define	BUF		(MAXEXP+MAXFRACT+1)	/* + decimal point */
#define	DEFPREC		6

#ifdef _NO_LONGDBL
static char *cvt _PARAMS((struct _reent *, double, int, int, char *, int *, int, int *));
#else
static char *cvt _PARAMS((struct _reent *, _LONG_DOUBLE, int, int, char *, int *, int, int *));
extern int  _ldcheck _PARAMS((_LONG_DOUBLE *));
#endif

static int exponent _PARAMS((char *, int, int));

#ifdef __SPE__
static char *cvt_ufix64 _PARAMS((struct _reent *, unsigned long long, int,  int *, int *));
#endif /* __SPE__ */

#else /* no FLOATING_POINT */

#define	BUF		40

#endif /* FLOATING_POINT */


/*
 * Macros for converting digits to letters and vice versa
 */
#define	to_digit(c)	((c) - '0')
#define is_digit(c)	((unsigned)to_digit(c) <= 9)
#define	to_char(n)	((n) + '0')

/*
 * Flags used during conversion.
 */
#define	ALT		0x001		/* alternate form */
#define	HEXPREFIX	0x002		/* add 0x or 0X prefix */
#define	LADJUST		0x004		/* left adjustment */
#define	LONGDBL		0x008		/* long double */
#define	LONGINT		0x010		/* long integer */
#ifndef _NO_LONGLONG
#define	QUADINT		0x020		/* quad integer */
#else /* ifdef _NO_LONGLONG, make QUADINT equivalent to LONGINT, so
	 that %lld behaves the same as %ld, not as %d, as expected if:
	 sizeof (long long) = sizeof long > sizeof int  */
#define	QUADINT		LONGINT
#endif
#define	SHORTINT	0x040		/* short integer */
#define	ZEROPAD		0x080		/* zero (as opposed to blank) pad */
#define FPT		0x100		/* Floating point number */
#define VECTOR		0x200		/* vector */
#define FIXEDPOINT	0x400		/* fixed-point */

int 
_DEFUN (VFPRINTF, (fp, fmt0, ap),
	FILE * fp _AND
	_CONST char *fmt0 _AND
	va_list ap)
{
  CHECK_INIT (_REENT, fp);
  return _VFPRINTF_R (_REENT, fp, fmt0, ap);
}

int 
_DEFUN (_VFPRINTF_R, (data, fp, fmt0, ap),
	struct _reent *data _AND
	FILE * fp _AND
	_CONST char *fmt0 _AND
	va_list ap)
{
	register char *fmt;	/* format string */
	register int ch;	/* character from fmt */
	register int n, m;	/* handy integers (short term usage) */
	register char *cp;	/* handy char pointer (short term usage) */
	register struct __siov *iovp;/* for PRINT macro */
	register int flags;	/* flags as above */
	int ret;		/* return value accumulator */
	int width;		/* width from format (%8d), or 0 */
	int prec;		/* precision from format (%.3d), or -1 */
	char sign;		/* sign prefix (' ', '+', '-', or \0) */
	char old_sign;		/* saved value of sign when looping for vectors */
	int old_ch;		/* saved value of ch when looping for vectors */
	char *format_anchor;    /* start of format to process */
	wchar_t wc;
#ifdef FLOATING_POINT
	char *decimal_point = localeconv()->decimal_point;
	char softsign;		/* temporary negative sign for floats */
#ifdef _NO_LONGDBL
	union { int i; double d; } _double_ = {0};
	#define _fpvalue (_double_.d)
#else
	union { int i; _LONG_DOUBLE ld; } _long_double_ = {0};
	#define _fpvalue (_long_double_.ld)
	int tmp;  
#endif
	int expt;		/* integer value of exponent */
	int expsize = 0;	/* character count for expstr */
	int ndig;		/* actual number of digits returned by cvt */
	char expstr[7];		/* buffer for exponent string */
#endif

#ifndef _NO_LONGLONG
#define	quad_t	  long long
#define	u_quad_t  unsigned long long
#endif

#ifndef _NO_LONGLONG
	u_quad_t _uquad;	/* integer arguments %[diouxX] */
#else
	u_long _uquad;
#endif
	enum { OCT, DEC, HEX } base;/* base for [diouxX] conversion */
	int dprec;		/* a copy of prec if [diouxX], 0 otherwise */
	int realsz;		/* field size expanded by dprec */
	int size;		/* size of converted field or string */
	char *xdigs = NULL;	/* digits for [xX] conversion */
#define NIOV 8
	struct __suio uio;	/* output information: summary */
	struct __siov iov[NIOV];/* ... and individual io vectors */
	char buf[BUF];		/* space for %c, %[diouxX], %[eEfgG] */
	char ox[2];		/* space for 0x hex-prefix */
#ifdef __ALTIVEC__
	char vec_sep;           /* vector separator char */
	int vec_print_count;    /* number of vector chunks remaining */
	vec_16_byte_union vec_tmp;
#endif /* __ALTIVEC__ */ 
        mbstate_t state;          /* mbtowc calls from library must not change state */

	/*
	 * Choose PADSIZE to trade efficiency vs. size.  If larger printf
	 * fields occur frequently, increase PADSIZE and make the initialisers
	 * below longer.
	 */
#define	PADSIZE	16		/* pad chunk size */
	static _CONST char blanks[PADSIZE] =
	 {' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '};
	static _CONST char zeroes[PADSIZE] =
	 {'0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'};

	/*
	 * BEWARE, these `goto error' on error, and PAD uses `n'.
	 */
#define	PRINT(ptr, len) { \
	iovp->iov_base = (ptr); \
	iovp->iov_len = (len); \
	uio.uio_resid += (len); \
	iovp++; \
	if (++uio.uio_iovcnt >= NIOV) { \
		if (__sprint_r(data, fp, &uio)) \
			goto error; \
		iovp = iov; \
	} \
}
#define	PAD(howmany, with) { \
	if ((n = (howmany)) > 0) { \
		while (n > PADSIZE) { \
			PRINT(with, PADSIZE); \
			n -= PADSIZE; \
		} \
		PRINT(with, n); \
	} \
}
#define	FLUSH() { \
	if (uio.uio_resid && __sprint_r(data, fp, &uio)) \
		goto error; \
	uio.uio_iovcnt = 0; \
	iovp = iov; \
}

#ifdef __ALTIVEC__
#define GET_SHORT(ap) \
	(flags&VECTOR ? \
	    (vec_print_count < 8 ? (short)vec_tmp.s[8 - vec_print_count] : \
	        (vec_tmp.v = va_arg(ap, vector int), (short)vec_tmp.s[0])) : \
	    (short)va_arg(ap, int))
#define GET_USHORT(ap) \
	(flags&VECTOR ? \
	    (vec_print_count < 8 ? (u_short)vec_tmp.s[8 - vec_print_count] : \
	        (vec_tmp.v = va_arg(ap, vector int), (u_short)vec_tmp.s[0])) : \
	    (u_short)va_arg(ap, int))

#define GET_LONG(ap) \
	(flags&VECTOR ? \
	    (vec_print_count < 4 ? (long)vec_tmp.l[4 - vec_print_count] : \
	        (vec_tmp.v = va_arg(ap, vector int), vec_tmp.l[0])) : \
	    va_arg(ap, long int))
#define GET_ULONG(ap) \
	(flags&VECTOR ? \
	    (vec_print_count < 4 ? (u_long)vec_tmp.l[4 - vec_print_count] : \
	        (vec_tmp.v = va_arg(ap, vector int), (u_long)vec_tmp.l[0])) : \
	    (u_long)va_arg(ap, unsigned long int))

#define GET_INT(ap) \
	(flags&VECTOR ? \
	    (vec_print_count < 16 ? \
                vec_tmp.c[16 - vec_print_count] : \
	        (vec_tmp.v = va_arg(ap, vector int), (int)vec_tmp.c[0])) : \
	    va_arg(ap, int))
#define GET_UINT(ap) \
	(flags&VECTOR ? \
	    (vec_print_count < 16 ? \
                (u_int)((unsigned char)vec_tmp.c[16 - vec_print_count]) : \
	        (vec_tmp.v = va_arg(ap, vector int), (u_int)((unsigned char)vec_tmp.c[0]))) : \
	    (u_int)va_arg(ap, unsigned int))
#else /* !__ALTIVEC__ */
#define GET_SHORT(ap) ((short)va_arg(ap, int))
#define GET_USHORT(ap) ((u_short)va_arg(ap, int))
#define GET_LONG(ap) (va_arg(ap, long int))
#define GET_ULONG(ap) ((u_long)va_arg(ap, unsigned long int))
#define GET_INT(ap) ((int)va_arg(ap, int))
#define GET_UINT(ap) ((u_int)va_arg(ap, unsigned int))
#endif /* !__ALTIVEC__ */

#ifndef _NO_LONGLONG
#define	SARG() \
	(flags&QUADINT ? va_arg(ap, quad_t) : \
	    flags&LONGINT ? GET_LONG(ap) : \
	    flags&SHORTINT ? (long)GET_SHORT(ap) : \
	    (long)GET_INT(ap))
#define	UARG() \
	(flags&QUADINT ? va_arg(ap, u_quad_t) : \
	    flags&LONGINT ? GET_ULONG(ap) : \
	    flags&SHORTINT ? (u_long)GET_USHORT(ap) : \
	    (u_long)GET_UINT(ap))
#ifdef __SPE__
#define	SFPARG() \
	(flags&LONGINT ? va_arg(ap, quad_t) : \
	    flags&SHORTINT ? (long)GET_SHORT(ap) : \
	    (long)va_arg(ap, int))
#define	UFPARG() \
	(flags&LONGINT ? va_arg(ap, u_quad_t) : \
	    flags&SHORTINT ? (u_long)GET_USHORT(ap) : \
	    (u_long)va_arg(ap, u_int))
#endif /* __SPE__ */
#else
#define	SARG() \
	(flags&LONGINT ? GET_LONG(ap) : \
	    flags&SHORTINT ? (long)GET_SHORT(ap) : \
	    (long)GET_INT(ap))
#define	UARG() \
	(flags&LONGINT ? GET_ULONG(ap) : \
	    flags&SHORTINT ? (u_long)GET_USHORT(ap) : \
	    (u_long)GET_UINT(ap))
#ifdef __SPE__
#define	SFPARG() \
	(flags&LONGINT ? (va_arg(ap, long) << 32) : \
	    flags&SHORTINT ? (long)GET_SHORT(ap) : \
	    (long)va_arg(ap, int))
#define	UFPARG() \
	(flags&LONGINT ? (va_arg(ap, u_long) <<32) : \
	    flags&SHORTINT ? (u_long)GET_USHORT(ap) : \
	    (u_long)va_arg(ap, u_int))
#endif /* __SPE__ */
#endif

        memset (&state, '\0', sizeof (state));

	/* sorry, fprintf(read_only_file, "") returns EOF, not 0 */
	if (cantwrite (data, fp)) {
		_funlockfile (fp);	
		return (EOF);
	}

	/* optimise fprintf(stderr) (and other unbuffered Unix files) */
	if ((fp->_flags & (__SNBF|__SWR|__SRW)) == (__SNBF|__SWR) &&
	    fp->_file >= 0)
		return (__sbprintf_r(data, fp, fmt0, ap));

	fmt = (char *)fmt0;
	uio.uio_iov = iovp = iov;
	uio.uio_resid = 0;
	uio.uio_iovcnt = 0;
	ret = 0;

	/*
	 * Scan the format for conversions (`%' character).
	 */
	for (;;) {
	        cp = fmt;
	        while ((n = _mbtowc_r(_REENT, &wc, fmt, MB_CUR_MAX, &state)) > 0) {
			fmt += n;
			if (wc == '%') {
				fmt--;
				break;
			}
		}
		if ((m = fmt - cp) != 0) {
			PRINT(cp, m);
			ret += m;
		}
		if (n <= 0)
			goto done;
		fmt++;		/* skip over '%' */

		flags = 0;
		dprec = 0;
		width = 0;
		prec = -1;
		sign = '\0';
		old_sign = '\0';
#ifdef __ALTIVEC__
		vec_print_count = 0;
		vec_sep = ' ';
#endif /* __ALTIVEC__ */

		format_anchor = fmt;
rflag:		ch = *fmt++;
		old_ch = ch;
reswitch:	switch (ch) {
		case ' ':
			/*
			 * ``If the space and + flags both appear, the space
			 * flag will be ignored.''
			 *	-- ANSI X3J11
			 */
			if (!sign)
				sign = ' ';
			goto rflag;
		case '#':
			flags |= ALT;
			goto rflag;
		case '*':
			/*
			 * ``A negative field width argument is taken as a
			 * - flag followed by a positive field width.''
			 *	-- ANSI X3J11
			 * They don't exclude field widths read from args.
			 */
			if ((width = va_arg(ap, int)) >= 0)
				goto rflag;
			width = -width;
			/* FALLTHROUGH */
		case '-':
			flags |= LADJUST;
			goto rflag;
		case '+':
			sign = '+';
			goto rflag;
#ifdef __ALTIVEC__
		case ',':
		case ';':
		case ':':
		case '_':
		        if (vec_sep != ' ')
		          {
		            fmt = format_anchor;
		            continue;
		          }
			vec_sep = ch;
			goto rflag;
#endif /* __ALTIVEC__ */
		case '.':
			if ((ch = *fmt++) == '*') {
				n = va_arg(ap, int);
				prec = n < 0 ? -1 : n;
				goto rflag;
			}
			n = 0;
			while (is_digit(ch)) {
				n = 10 * n + to_digit(ch);
				ch = *fmt++;
			}
			prec = n < 0 ? -1 : n;
			goto reswitch;
		case '0':
			/*
			 * ``Note that 0 is taken as a flag, not as the
			 * beginning of a field width.''
			 *	-- ANSI X3J11
			 */
			flags |= ZEROPAD;
			goto rflag;
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			n = 0;
			do {
				n = 10 * n + to_digit(ch);
				ch = *fmt++;
			} while (is_digit(ch));
			width = n;
			goto reswitch;
#ifdef FLOATING_POINT
		case 'L':
#ifdef __ALTIVEC__
		        if (flags & VECTOR) 
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
			flags |= LONGDBL;
			goto rflag;
#endif
		case 'h':
		        if (flags & LONGINT)
		          {
		            fmt = format_anchor;
		            continue;
		          }
			flags |= SHORTINT;
#ifdef __ALTIVEC__
			if (flags & VECTOR)
			  vec_print_count = 8;
#endif
			goto rflag;
		case 'l':
		        if (flags & SHORTINT)
		          {
		            fmt = format_anchor;
		            continue;
		          }
			if (*fmt == 'l') {
				fmt++;
				flags |= QUADINT;
				flags &= ~VECTOR;
			} else {
				flags |= LONGINT;
#ifdef __ALTIVEC__
				if (flags & VECTOR)
				  vec_print_count = 4;
#endif
			}
			goto rflag;
#ifdef __ALTIVEC__
		case 'v':
		        if (flags & VECTOR) 
			  {
			    fmt = format_anchor;
			    continue;
			  }
			flags |= VECTOR;
			vec_print_count = (flags & SHORTINT) ? 8 : 
			  ((flags & LONGINT) ? 4 : 16);
			goto rflag;
#endif
                case 'q':
#ifdef __ALTIVEC__
		        if (flags & VECTOR) 
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
			flags |= QUADINT;
			goto rflag;
		case 'c':
#ifdef __ALTIVEC__
			if (flags & VECTOR)
			  {
			    int k;
			    vec_16_byte_union tmp;
		            if (flags & (SHORTINT | LONGINT))
		              {
		                fmt = format_anchor;
		                continue;
		              }
			    tmp.v = va_arg(ap, vector int);
			    cp = buf;
			    for (k = 0; k < 15; ++k)
			      {
			        *cp++ = tmp.c[k];
			        if (vec_sep != ' ')
			          *cp++ = vec_sep;
			      }
			    *cp++ = tmp.c[15];
			    size = cp - buf;
			    cp = buf;
			    vec_print_count = 0;
			  }
			else
#endif /* __ALTIVEC__ */
			  {
			    *(cp = buf) = va_arg(ap, int);
			    size = 1;
			  }
			sign = '\0';
			break;
		case 'D':
			flags |= LONGINT;
			/*FALLTHROUGH*/
		case 'd':
		case 'i':
#ifdef __ALTIVEC__
		        if (!(flags & VECTOR) && vec_sep != ' ') 
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
			_uquad = SARG();
#ifndef _NO_LONGLONG
			if ((quad_t)_uquad < 0)
#else
			if ((long) _uquad < 0)
#endif
			{

				_uquad = -_uquad;
				old_sign = sign;
				sign = '-';
			}
			base = DEC;
			goto number;
#ifdef FLOATING_POINT
		case 'e':
		case 'E':
		case 'f':
		case 'g':
		case 'G':
			if (prec == -1) {
				prec = DEFPREC;
			} else if ((ch == 'g' || ch == 'G') && prec == 0) {
				prec = 1;
			}

#ifdef _NO_LONGDBL
			if (flags & LONGDBL) {
				_fpvalue = (double) va_arg(ap, _LONG_DOUBLE);
#ifdef __ALTIVEC__
			} else if (flags & VECTOR) {
				if (vec_print_count >= 4)
                                  {
                                    vec_print_count = 4;
				    vec_tmp.v = va_arg(ap, vector int);
                                  }
				_fpvalue = (double)vec_tmp.f[4 - vec_print_count];
			} else if (vec_sep != ' ') {
			         fmt = format_anchor;
			         continue;
			
#endif /* __ALTIVEC__ */
			} else {
				_fpvalue = va_arg(ap, double);
			}

			/* do this before tricky precision changes */
			if (isinf(_fpvalue)) {
				if (_fpvalue < 0)
				  {
				    old_sign = sign;
				    sign = '-';
				  }
				    
				cp = "Inf";
				size = 3;
				break;
			}
			if (isnan(_fpvalue)) {
				cp = "NaN";
				size = 3;
				break;
			}

#else /* !_NO_LONGDBL */
			
			if (flags & LONGDBL) {
				_fpvalue = va_arg(ap, _LONG_DOUBLE);
#ifdef __ALTIVEC__
			} else if (flags & VECTOR) {
				if (vec_print_count >= 4)
                                  {
                                    vec_print_count = 4;
				    vec_tmp.v = va_arg(ap, vector int);
                                  }
				_fpvalue = (_LONG_DOUBLE)k.f[4 - vec_print_count];
#endif /* __ALTIVEC__ */
			} else {
				_fpvalue = (_LONG_DOUBLE)va_arg(ap, double);
			}

			/* do this before tricky precision changes */
			tmp = _ldcheck (&_fpvalue);
			if (tmp == 2) {
				if (_fpvalue < 0)
				  {
				    old_sign = sign;
				    sign = '-';
				  }
				cp = "Inf";
				size = 3;
				break;
			}
			if (tmp == 1) {
				cp = "NaN";
				size = 3;
				break;
			}
#endif /* !_NO_LONGDBL */

			flags |= FPT;

			cp = cvt(data, _fpvalue, prec, flags, &softsign,
				&expt, ch, &ndig);

			if (ch == 'g' || ch == 'G') {
				if (expt <= -4 || expt > prec)
				  {
				    old_ch = ch;
				    ch = (ch == 'g') ? 'e' : 'E';
				  }
				else
					ch = 'g';
			} 
			if (ch <= 'e') {	/* 'e' or 'E' fmt */
				--expt;
				expsize = exponent(expstr, expt, ch);
				size = expsize + ndig;
				if (ndig > 1 || flags & ALT)
					++size;
			} else if (ch == 'f') {		/* f fmt */
				if (expt > 0) {
					size = expt;
					if (prec || flags & ALT)
						size += prec + 1;
				} else	/* "0.X" */
                                        size = (prec || flags & ALT)
                                                  ? prec + 2
                                                  : 1;
			} else if (expt >= ndig) {	/* fixed g fmt */
				size = expt;
				if (flags & ALT)
					++size;
			} else
				size = ndig + (expt > 0 ?
					1 : 2 - expt);

			if (softsign)
			  {
			    old_sign = sign;
			    sign = '-';
			  }
			break;
#endif /* FLOATING_POINT */
#ifdef __SPE__
                case 'r':
		        flags |= FIXEDPOINT;
	     	        _uquad = SFPARG();
			if ((quad_t)_uquad < 0)
			  {
			    sign = '-';
			    _uquad = -(quad_t)_uquad;
			  }
			if (flags & SHORTINT)
			  _uquad <<= 49;
			else if (flags & LONGINT)
			  _uquad <<= 1;
			else
			  _uquad <<= 33;

			if (_uquad == 0 && sign)
			  {
			    /* we have -1.0 which has to be handled special */
			    cp = "100000";
			    expt = 1;
			    ndig = 6;
			    break;
			  }

			goto fixed_nosign;
                case 'R':
		        flags |= FIXEDPOINT;
		        _uquad = UFPARG();
			if (flags & SHORTINT)
			  _uquad <<= 48;
			else if (!(flags & LONGINT))
			  _uquad <<= 32;
	
fixed_nosign:
			if (prec == -1)
			  prec = DEFPREC;

			cp = cvt_ufix64 (data, _uquad, prec, &expt, &ndig);

			/* act like %f of format "0.X" */
			size = prec + 2;

                        break;
#endif /* __SPE__ */
		case 'n':
#ifdef __ALTIVEC__
		        if (flags & VECTOR)
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
#ifndef _NO_LONGLONG
			if (flags & QUADINT)
				*va_arg(ap, quad_t *) = ret;
			else 
#endif
			if (flags & LONGINT)
				*va_arg(ap, long *) = ret;
			else if (flags & SHORTINT)
				*va_arg(ap, short *) = ret;
			else
				*va_arg(ap, int *) = ret;
			continue;	/* no output */
		case 'O':
			flags |= LONGINT;
			/*FALLTHROUGH*/
		case 'o':
#ifdef __ALTIVEC__
		        if (!(flags & VECTOR) && vec_sep != ' ') 
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
			_uquad = UARG();
			base = OCT;
			goto nosign;
		case 'p':
			/*
			 * ``The argument shall be a pointer to void.  The
			 * value of the pointer is converted to a sequence
			 * of printable characters, in an implementation-
			 * defined manner.''
			 *	-- ANSI X3J11
			 */
			/* NOSTRICT */
#ifdef __ALTIVEC__
		        if (flags & VECTOR)
		          _uquad = UARG();
		        else if (vec_sep != ' ')
			  {
			    fmt = format_anchor;
			    continue;
			  }
			else
#endif /* __ALTIVEC__ */
		          _uquad = (u_long)(unsigned _POINTER_INT)va_arg(ap, void *);
			base = HEX;
			xdigs = "0123456789abcdef";
			flags |= HEXPREFIX;
			ch = 'x';
			goto nosign;
		case 's':
#ifdef __ALTIVEC__
		        if (flags & VECTOR)
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
			if ((cp = va_arg(ap, char *)) == NULL)
				cp = "(null)";
			if (prec >= 0) {
				/*
				 * can't use strlen; can only look for the
				 * NUL in the first `prec' characters, and
				 * strlen() will go further.
				 */
				char *p = memchr(cp, 0, prec);

				if (p != NULL) {
					size = p - cp;
					if (size > prec)
						size = prec;
				} else
					size = prec;
			} else
				size = strlen(cp);
			sign = '\0';
			break;
		case 'U':
			flags |= LONGINT;
			/*FALLTHROUGH*/
		case 'u':
#ifdef __ALTIVEC__
		        if (!(flags & VECTOR) && vec_sep != ' ') 
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
			_uquad = UARG();
			base = DEC;
			goto nosign;
		case 'X':
			xdigs = "0123456789ABCDEF";
			goto hex;
		case 'x':
			xdigs = "0123456789abcdef";
#ifdef __ALTIVEC__
		        if (!(flags & VECTOR) && vec_sep != ' ') 
			  {
			    fmt = format_anchor;
			    continue;
			  }
#endif /* __ALTIVEC__ */
hex:			_uquad = UARG();
			base = HEX;
			/* leading 0x/X only if non-zero */
			if (flags & ALT && _uquad != 0)
				flags |= HEXPREFIX;

			/* unsigned conversions */
nosign:			sign = '\0';
			/*
			 * ``... diouXx conversions ... if a precision is
			 * specified, the 0 flag will be ignored.''
			 *	-- ANSI X3J11
			 */
number:			if ((dprec = prec) >= 0)
				flags &= ~ZEROPAD;

			/*
			 * ``The result of converting a zero value with an
			 * explicit precision of zero is no characters.''
			 *	-- ANSI X3J11
			 */
			cp = buf + BUF;
			if (_uquad != 0 || prec != 0) {
				/*
				 * Unsigned mod is hard, and unsigned mod
				 * by a constant is easier than that by
				 * a variable; hence this switch.
				 */
				switch (base) {
				case OCT:
					do {
						*--cp = to_char(_uquad & 7);
						_uquad >>= 3;
					} while (_uquad);
					/* handle octal leading 0 */
					if (flags & ALT && *cp != '0')
						*--cp = '0';
					break;

				case DEC:
					/* many numbers are 1 digit */
					while (_uquad >= 10) {
						*--cp = to_char(_uquad % 10);
						_uquad /= 10;
					}
					*--cp = to_char(_uquad);
					break;

				case HEX:
					do {
						*--cp = xdigs[_uquad & 15];
						_uquad >>= 4;
					} while (_uquad);
					break;

				default:
					cp = "bug in vfprintf: bad base";
					size = strlen(cp);
					goto skipsize;
				}
			}
                       /*
			* ...result is to be converted to an 'alternate form'.
			* For o conversion, it increases the precision to force
			* the first digit of the result to be a zero."
			*     -- ANSI X3J11
			*
			* To demonstrate this case, compile and run:
                        *    printf ("%#.0o",0);
			*/
                       else if (base == OCT && (flags & ALT))
                         *--cp = '0';

			size = buf + BUF - cp;
		skipsize:
			break;
		default:	/* "%?" prints ?, unless ? is NUL */
			flags &= ~VECTOR;
			if (ch == '\0')
				goto done;
			/* pretend it was %c with argument ch */
			cp = buf;
			*cp = ch;
			size = 1;
			sign = '\0';
			break;
		}

		/*
		 * All reasonable formats wind up here.  At this point, `cp'
		 * points to a string which (if not flags&LADJUST) should be
		 * padded out to `width' places.  If flags&ZEROPAD, it should
		 * first be prefixed by any sign or other prefix; otherwise,
		 * it should be blank padded before the prefix is emitted.
		 * After any left-hand padding and prefixing, emit zeroes
		 * required by a decimal [diouxX] precision, then print the
		 * string proper, then emit zeroes required by any leftover
		 * floating precision; finally, if LADJUST, pad with blanks.
		 *
		 * Compute actual size, so we know how much to pad.
		 * size excludes decimal prec; realsz includes it.
		 */
		realsz = dprec > size ? dprec : size;
		if (sign)
			realsz++;
		else if (flags & HEXPREFIX)
			realsz+= 2;

		/* right-adjusting blank padding */
		if ((flags & (LADJUST|ZEROPAD)) == 0)
			PAD(width - realsz, blanks);

		/* prefix */
		if (sign) {
			PRINT(&sign, 1);
		} else if (flags & HEXPREFIX) {
			ox[0] = '0';
			ox[1] = ch;
			PRINT(ox, 2);
		}

		/* right-adjusting zero padding */
		if ((flags & (LADJUST|ZEROPAD)) == ZEROPAD)
			PAD(width - realsz, zeroes);

		/* leading zeroes from decimal precision */
		PAD(dprec - size, zeroes);

		/* the string or number proper */
#ifdef FLOATING_POINT
		if ((flags & FPT) == 0) {
#ifdef __SPE__
		        if (flags & FIXEDPOINT) {
				if (_uquad == 0 && !sign) {
					/* kludge for __dtoa irregularity */
					PRINT("0", 1);
					if (expt < ndig || (flags & ALT) != 0) {
						PRINT(decimal_point, 1);
						PAD(ndig - 1, zeroes);
					}
				} else if (expt <= 0) {
					PRINT("0", 1);
					if(expt || ndig) {
						PRINT(decimal_point, 1);
						PAD(-expt, zeroes);
						PRINT(cp, ndig);
					}
				} else if (expt >= ndig) {
					PRINT(cp, ndig);
					PAD(expt - ndig, zeroes);
					if (flags & ALT)
						PRINT(".", 1);
				} else {
					PRINT(cp, expt);
					cp += expt;
					PRINT(".", 1);
					PRINT(cp, ndig-expt);
				}
		        } else
#endif /* __SPE__ */
 			        PRINT(cp, size);
		} else {	/* glue together f_p fragments */
			if (ch >= 'f') {	/* 'f' or 'g' */
				if (_fpvalue == 0) {
					/* kludge for __dtoa irregularity */
					PRINT("0", 1);
					if (expt < ndig || (flags & ALT) != 0) {
						PRINT(decimal_point, 1);
						PAD(ndig - 1, zeroes);
					}
				} else if (expt <= 0) {
					PRINT("0", 1);
					if(expt || ndig) {
						PRINT(decimal_point, 1);
						PAD(-expt, zeroes);
						PRINT(cp, ndig);
					}
				} else if (expt >= ndig) {
					PRINT(cp, ndig);
					PAD(expt - ndig, zeroes);
					if (flags & ALT)
						PRINT(".", 1);
				} else {
					PRINT(cp, expt);
					cp += expt;
					PRINT(".", 1);
					PRINT(cp, ndig-expt);
				}
			} else {	/* 'e' or 'E' */
				if (ndig > 1 || flags & ALT) {
					ox[0] = *cp++;
					ox[1] = '.';
					PRINT(ox, 2);
                                       if (_fpvalue) {
						PRINT(cp, ndig-1);
					} else	/* 0.[0..] */
						/* __dtoa irregularity */
						PAD(ndig - 1, zeroes);
				} else	/* XeYYY */
					PRINT(cp, 1);
				PRINT(expstr, expsize);
			}
		}
#else
		PRINT(cp, size);
#endif
		/* left-adjusting padding (always blank) */
		if (flags & LADJUST)
			PAD(width - realsz, blanks);

		/* finally, adjust ret */
		ret += width > realsz ? width : realsz;

#ifdef __ALTIVEC__		
		if ((flags & VECTOR) && vec_print_count-- > 1)
		  {
		    /* add vector separator */
		    if (ch != 'c' || vec_sep != ' ')
		      {
		        PRINT(&vec_sep, 1);
		        ret += 1;
		      }
		    FLUSH();
		    sign = old_sign;
		    ch = old_ch;
		    goto reswitch;
		  }
#endif /* __ALTIVEC__ */
		FLUSH();	/* copy out the I/O vectors */
	}
done:
	FLUSH();
error:
	return (__sferror(fp) ? EOF : ret);
	/* NOTREACHED */
}

#ifdef FLOATING_POINT

#ifdef _NO_LONGDBL
extern char *_dtoa_r _PARAMS((struct _reent *, double, int,
			      int, int *, int *, char **));
#else
extern char *_ldtoa_r _PARAMS((struct _reent *, _LONG_DOUBLE, int,
			      int, int *, int *, char **));
#undef word0
#define word0(x) ldword0(x)
#endif

static char *
cvt(data, value, ndigits, flags, sign, decpt, ch, length)
	struct _reent *data;
#ifdef _NO_LONGDBL
	double value;
#else
	_LONG_DOUBLE value;
#endif
	int ndigits, flags, *decpt, ch, *length;
	char *sign;
{
	int mode, dsgn;
	char *digits, *bp, *rve;
#ifdef _NO_LONGDBL
        union double_union tmp;
#else
        struct ldieee *ldptr;
#endif

	if (ch == 'f') {
		mode = 3;		/* ndigits after the decimal point */
	} else {
		/* To obtain ndigits after the decimal point for the 'e' 
		 * and 'E' formats, round to ndigits + 1 significant 
		 * figures.
		 */
		if (ch == 'e' || ch == 'E') {
			ndigits++;
		}
		mode = 2;		/* ndigits significant digits */
	}

#ifdef _NO_LONGDBL
        tmp.d = value;

	if (word0(tmp) & Sign_bit) { /* this will check for < 0 and -0.0 */
		value = -value;
		*sign = '-';
        } else
		*sign = '\000';

	digits = _dtoa_r(data, value, mode, ndigits, decpt, &dsgn, &rve);
#else /* !_NO_LONGDBL */
	ldptr = (struct ldieee *)&value;
	if (ldptr->sign) { /* this will check for < 0 and -0.0 */
		value = -value;
		*sign = '-';
        } else
		*sign = '\000';

	digits = _ldtoa_r(data, value, mode, ndigits, decpt, &dsgn, &rve);
#endif /* !_NO_LONGDBL */

	if ((ch != 'g' && ch != 'G') || flags & ALT) {	/* Print trailing zeros */
		bp = digits + ndigits;
		if (ch == 'f') {
			if (*digits == '0' && value)
				*decpt = -ndigits + 1;
			bp += *decpt;
		}
		if (value == 0)	/* kludge for __dtoa irregularity */
			rve = bp;
		while (rve < bp)
			*rve++ = '0';
	}
	*length = rve - digits;
	return (digits);
}

static int
exponent(p0, exp, fmtch)
	char *p0;
	int exp, fmtch;
{
	register char *p, *t;
	char expbuf[40];

	p = p0;
	*p++ = fmtch;
	if (exp < 0) {
		exp = -exp;
		*p++ = '-';
	}
	else
		*p++ = '+';
	t = expbuf + 40;
	if (exp > 9) {
		do {
			*--t = to_char(exp % 10);
		} while ((exp /= 10) > 9);
		*--t = to_char(exp);
		for (; t < expbuf + 40; *p++ = *t++);
	}
	else {
		*p++ = '0';
		*p++ = to_char(exp);
	}
	return (p - p0);
}
#endif /* FLOATING_POINT */

#ifdef __SPE__
extern char *_ufix64toa_r _PARAMS((struct _reent *, unsigned long long, int,
			           int, int *, int *, char **));
static char *
cvt_ufix64 (data, value, ndigits, decpt, length)
	struct _reent *data;
	unsigned long long value;
	int ndigits, *decpt, *length;
{
	int dsgn;
	char *digits, *bp, *rve;

	/* treat the same as %f format and use mode=3 */
	digits = _ufix64toa_r (data, value, 3, ndigits, decpt, &dsgn, &rve);

        /* print trailing zeroes */
	bp = digits + ndigits;
	if (*digits == '0' && value)
	  *decpt = -ndigits + 1;
	bp += *decpt;
	if (value == 0)	/* kludge for __dtoa irregularity */
	  rve = bp;
	while (rve < bp)
	  *rve++ = '0';
	*length = rve - digits;
	return (digits);
}
#endif /* __SPE__ */
