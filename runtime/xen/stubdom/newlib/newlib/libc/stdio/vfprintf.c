/*
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

/*
FUNCTION
<<vfprintf>>, <<vprintf>>, <<vsprintf>>, <<vsnprintf>>, <<vasprintf>>, <<vasnprintf>>---format argument list

INDEX
	vfprintf
INDEX
	vprintf
INDEX
	vsprintf
INDEX
	vsnprintf
INDEX
	vasprintf
INDEX
	vasnprintf

ANSI_SYNOPSIS
	#include <stdio.h>
	#include <stdarg.h>
	int vprintf(const char *<[fmt]>, va_list <[list]>);
	int vfprintf(FILE *<[fp]>, const char *<[fmt]>, va_list <[list]>);
	int vsprintf(char *<[str]>, const char *<[fmt]>, va_list <[list]>);
	int vsnprintf(char *<[str]>, size_t <[size]>, const char *<[fmt]>,
                      va_list <[list]>);
	int vasprintf(char **<[strp]>, const char *<[fmt]>, va_list <[list]>);
	char *vasnprintf(char *<[str]>, size_t *<[size]>, const char *<[fmt]>,
                         va_list <[list]>);

	int _vprintf_r(struct _reent *<[reent]>, const char *<[fmt]>,
                        va_list <[list]>);
	int _vfprintf_r(struct _reent *<[reent]>, FILE *<[fp]>,
                        const char *<[fmt]>, va_list <[list]>);
	int _vsprintf_r(struct _reent *<[reent]>, char *<[str]>,
                        const char *<[fmt]>, va_list <[list]>);
	int _vasprintf_r(struct _reent *<[reent]>, char **<[str]>,
                         const char *<[fmt]>, va_list <[list]>);
	int _vsnprintf_r(struct _reent *<[reent]>, char *<[str]>,
                         size_t <[size]>, const char *<[fmt]>,
                         va_list <[list]>);
	char *_vasnprintf_r(struct _reent *<[reent]>, char *<[str]>,
                            size_t *<[size]>, const char *<[fmt]>,
                            va_list <[list]>);

DESCRIPTION
<<vprintf>>, <<vfprintf>>, <<vasprintf>>, <<vsprintf>>, <<vsnprintf>>,
and <<vasnprintf>> are (respectively) variants of <<printf>>,
<<fprintf>>, <<asprintf>>, <<sprintf>>, <<snprintf>>, and
<<asnprintf>>.  They differ only in allowing their caller to pass the
variable argument list as a <<va_list>> object (initialized by
<<va_start>>) rather than directly accepting a variable number of
arguments.  The caller is responsible for calling <<va_end>>.

<<_vprintf_r>>, <<_vfprintf_r>>, <<_vasprintf_r>>, <<_vsprintf_r>>,
<<_vsnprintf_r>>, and <<_vasnprintf_r>> are reentrant versions of the
above.

RETURNS
The return values are consistent with the corresponding functions.

PORTABILITY
ANSI C requires <<vprintf>>, <<vfprintf>>, <<vsprintf>>, and
<<vsnprintf>>.  The remaining functions are newlib extensions.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
/*static char *sccsid = "from: @(#)vfprintf.c	5.50 (Berkeley) 12/16/92";*/
static char *rcsid = "$Id: vfprintf.c,v 1.43 2002/08/13 02:40:06 fitzsim Exp $";
#endif /* LIBC_SCCS and not lint */

/*
 * Actual printf innards.
 *
 * This code is large and complicated...
 */
#include <newlib.h>

#ifdef INTEGER_ONLY
# define VFPRINTF vfiprintf
# define _VFPRINTF_R _vfiprintf_r
#else
# define VFPRINTF vfprintf
# define _VFPRINTF_R _vfprintf_r
# ifndef NO_FLOATING_POINT
#  define FLOATING_POINT
# endif
#endif

#define _NO_POS_ARGS
#ifdef _WANT_IO_POS_ARGS
# undef _NO_POS_ARGS
#endif

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <stdint.h>
#include <wchar.h>
#include <sys/lock.h>
#include <stdarg.h>
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
#if defined _WANT_IO_LONG_LONG \
	&& (defined __GNUC__ || __STDC_VERSION__ >= 199901L)
# undef _NO_LONGLONG
#endif

/*
 * Flush out all the vectors defined by the given uio,
 * then reset it so that it can be reused.
 */
static int
_DEFUN(__sprint_r, (ptr, fp, uio),
       struct _reent *ptr _AND
       FILE *fp _AND
       register struct __suio *uio)
{
	register int err;

	if (uio->uio_resid == 0) {
		uio->uio_iovcnt = 0;
		return (0);
	}
	err = __sfvwrite_r(ptr, fp, uio);
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
_DEFUN(__sbprintf, (rptr, fp, fmt, ap),
       struct _reent *rptr _AND
       register FILE *fp   _AND
       _CONST char *fmt  _AND
       va_list ap)
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
	fake._bf._size = fake._w = sizeof (buf);
	fake._lbfsize = 0;	/* not actually used, but Just In Case */
#ifndef __SINGLE_THREAD__
	__lock_init_recursive (fake._lock);
#endif

	/* do the work, then copy any error status */
	ret = _VFPRINTF_R (rptr, &fake, fmt, ap);
	if (ret >= 0 && _fflush_r (rptr, &fake))
		ret = EOF;
	if (fake._flags & __SERR)
		fp->_flags |= __SERR;

#ifndef __SINGLE_THREAD__
	__lock_close_recursive (fake._lock);
#endif
	return (ret);
}


#ifdef FLOATING_POINT
# include <locale.h>
# include <math.h>

/* For %La, an exponent of 15 bits occupies the exponent character, a
   sign, and up to 5 digits.  */
# define MAXEXPLEN		7
# define DEFPREC		6

# ifdef _NO_LONGDBL

extern char *_dtoa_r _PARAMS((struct _reent *, double, int,
			      int, int *, int *, char **));

#  define _PRINTF_FLOAT_TYPE double
#  define _DTOA_R _dtoa_r
#  define FREXP frexp

# else /* !_NO_LONGDBL */

extern char *_ldtoa_r _PARAMS((struct _reent *, _LONG_DOUBLE, int,
			      int, int *, int *, char **));

extern int _EXFUN(_ldcheck,(_LONG_DOUBLE *));

#  define _PRINTF_FLOAT_TYPE _LONG_DOUBLE
#  define _DTOA_R _ldtoa_r
/* FIXME - frexpl is not yet supported; and cvt infloops if (double)f
   converts a finite value into infinity.  */
/* #  define FREXP frexpl */
#  define FREXP(f,e) ((_LONG_DOUBLE) frexp ((double)f, e))
# endif /* !_NO_LONGDBL */

static char *cvt(struct _reent *, _PRINTF_FLOAT_TYPE, int, int, char *, int *,
                 int, int *, char *);

static int exponent(char *, int, int);

#endif /* FLOATING_POINT */

/* BUF must be big enough for the maximum %#llo (assuming long long is
   at most 64 bits, this would be 23 characters), the maximum
   multibyte character %C, and the maximum default precision of %La
   (assuming long double is at most 128 bits with 113 bits of
   mantissa, this would be 29 characters).  %e, %f, and %g use
   reentrant storage shared with mprec.  All other formats that use
   buf get by with fewer characters.  Making BUF slightly bigger
   reduces the need for malloc in %.*a and %S, when large precision or
   long strings are processed.  */
#define	BUF		40
#if defined _MB_CAPABLE && MB_LEN_MAX > BUF
# undef BUF
# define BUF MB_LEN_MAX
#endif

#ifndef _NO_LONGLONG
# define quad_t long long
# define u_quad_t unsigned long long
#else
# define quad_t long
# define u_quad_t unsigned long
#endif

typedef quad_t * quad_ptr_t;
typedef _PTR     void_ptr_t;
typedef char *   char_ptr_t;
typedef long *   long_ptr_t;
typedef int  *   int_ptr_t;
typedef short *  short_ptr_t;

#ifndef _NO_POS_ARGS
# ifdef NL_ARGMAX
#  define MAX_POS_ARGS NL_ARGMAX
# else
#  define MAX_POS_ARGS 32
# endif

union arg_val
{
  int val_int;
  u_int val_u_int;
  long val_long;
  u_long val_u_long;
  float val_float;
  double val_double;
  _LONG_DOUBLE val__LONG_DOUBLE;
  int_ptr_t val_int_ptr_t;
  short_ptr_t val_short_ptr_t;
  long_ptr_t val_long_ptr_t;
  char_ptr_t val_char_ptr_t;
  quad_ptr_t val_quad_ptr_t;
  void_ptr_t val_void_ptr_t;
  quad_t val_quad_t;
  u_quad_t val_u_quad_t;
  wint_t val_wint_t;
};

static union arg_val *
_EXFUN(get_arg, (struct _reent *data, int n, char *fmt, 
                 va_list *ap, int *numargs, union arg_val *args, 
                 int *arg_type, char **last_fmt));
#endif /* !_NO_POS_ARGS */

/*
 * Macros for converting digits to letters and vice versa
 */
#define	to_digit(c)	((c) - '0')
#define is_digit(c)	((unsigned)to_digit (c) <= 9)
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
# define QUADINT	0x020		/* quad integer */
#else /* ifdef _NO_LONGLONG, make QUADINT equivalent to LONGINT, so
	 that %lld behaves the same as %ld, not as %d, as expected if:
	 sizeof (long long) = sizeof long > sizeof int  */
# define QUADINT	LONGINT
#endif
#define	SHORTINT	0x040		/* short integer */
#define	ZEROPAD		0x080		/* zero (as opposed to blank) pad */
#define FPT		0x100		/* Floating point number */
#ifdef _WANT_IO_C99_FORMATS
# define CHARINT	0x200		/* char as integer */
#else /* define as 0, to make SARG and UARG occupy fewer instructions  */
# define CHARINT	0
#endif

int _EXFUN(_VFPRINTF_R, (struct _reent *, FILE *, _CONST char *, va_list));

int 
_DEFUN(VFPRINTF, (fp, fmt0, ap),
       FILE * fp         _AND
       _CONST char *fmt0 _AND
       va_list ap)
{
  int result;
  result = _VFPRINTF_R (_REENT, fp, fmt0, ap);
  return result;
}

int 
_DEFUN(_VFPRINTF_R, (data, fp, fmt0, ap),
       struct _reent *data _AND
       FILE * fp           _AND
       _CONST char *fmt0   _AND
       va_list ap)
{
	register char *fmt;	/* format string */
	register int ch;	/* character from fmt */
	register int n, m;	/* handy integers (short term usage) */
	register char *cp;	/* handy char pointer (short term usage) */
	register struct __siov *iovp;/* for PRINT macro */
	register int flags;	/* flags as above */
	char *fmt_anchor;       /* current format spec being processed */
#ifndef _NO_POS_ARGS
	int N;                  /* arg number */
	int arg_index;          /* index into args processed directly */
	int numargs;            /* number of varargs read */
	char *saved_fmt;        /* saved fmt pointer */
	union arg_val args[MAX_POS_ARGS];
	int arg_type[MAX_POS_ARGS];
	int is_pos_arg;         /* is current format positional? */
	int old_is_pos_arg;     /* is current format positional? */
#endif
	int ret;		/* return value accumulator */
	int width;		/* width from format (%8d), or 0 */
	int prec;		/* precision from format (%.3d), or -1 */
	char sign;		/* sign prefix (' ', '+', '-', or \0) */
#ifdef FLOATING_POINT
	char *decimal_point = _localeconv_r (data)->decimal_point;
	char softsign;		/* temporary negative sign for floats */
	union { int i; _PRINTF_FLOAT_TYPE fp; } _double_ = {0};
# define _fpvalue (_double_.fp)
	int expt;		/* integer value of exponent */
	int expsize = 0;	/* character count for expstr */
	int ndig = 0;		/* actual number of digits returned by cvt */
	char expstr[MAXEXPLEN];	/* buffer for exponent string */
#endif /* FLOATING_POINT */
	u_quad_t _uquad;	/* integer arguments %[diouxX] */
	enum { OCT, DEC, HEX } base;/* base for [diouxX] conversion */
	int dprec;		/* a copy of prec if [diouxX], 0 otherwise */
	int realsz;		/* field size expanded by dprec */
	int size;		/* size of converted field or string */
	char *xdigs = NULL;	/* digits for [xX] conversion */
#define NIOV 8
	struct __suio uio;	/* output information: summary */
	struct __siov iov[NIOV];/* ... and individual io vectors */
	char buf[BUF];		/* space for %c, %S, %[diouxX], %[aA] */
	char ox[2];		/* space for 0x hex-prefix */
#ifdef _MB_CAPABLE
	wchar_t wc;
	mbstate_t state;        /* mbtowc calls from library must not change state */
#endif
	char *malloc_buf = NULL;/* handy pointer for malloced buffers */

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

#ifdef _MB_CAPABLE
	memset (&state, '\0', sizeof (state));
#endif
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
			PRINT (with, PADSIZE); \
			n -= PADSIZE; \
		} \
		PRINT (with, n); \
	} \
}
#define	FLUSH() { \
	if (uio.uio_resid && __sprint_r(data, fp, &uio)) \
		goto error; \
	uio.uio_iovcnt = 0; \
	iovp = iov; \
}

	/* Macros to support positional arguments */
#ifndef _NO_POS_ARGS
# define GET_ARG(n, ap, type)						\
	(is_pos_arg							\
	 ? (n < numargs							\
	    ? args[n].val_##type					\
	    : get_arg (data, n, fmt_anchor, &ap, &numargs, args,	\
		       arg_type, &saved_fmt)->val_##type)		\
	 : (arg_index++ < numargs					\
	    ? args[n].val_##type					\
	    : (numargs < MAX_POS_ARGS					\
	       ? args[numargs++].val_##type = va_arg (ap, type)		\
	       : va_arg (ap, type))))
#else
# define GET_ARG(n, ap, type) (va_arg (ap, type))
#endif

	/*
	 * To extend shorts properly, we need both signed and unsigned
	 * argument extraction methods.
	 */
#ifndef _NO_LONGLONG
#define	SARG() \
	(flags&QUADINT ? GET_ARG (N, ap, quad_t) : \
	    flags&LONGINT ? GET_ARG (N, ap, long) : \
	    flags&SHORTINT ? (long)(short)GET_ARG (N, ap, int) : \
	    flags&CHARINT ? (long)(signed char)GET_ARG (N, ap, int) : \
	    (long)GET_ARG (N, ap, int))
#define	UARG() \
	(flags&QUADINT ? GET_ARG (N, ap, u_quad_t) : \
	    flags&LONGINT ? GET_ARG (N, ap, u_long) : \
	    flags&SHORTINT ? (u_long)(u_short)GET_ARG (N, ap, int) : \
	    flags&CHARINT ? (u_long)(unsigned char)GET_ARG (N, ap, int) : \
	    (u_long)GET_ARG (N, ap, u_int))
#else
#define	SARG() \
	(flags&LONGINT ? GET_ARG (N, ap, long) : \
	    flags&SHORTINT ? (long)(short)GET_ARG (N, ap, int) : \
	    flags&CHARINT ? (long)(signed char)GET_ARG (N, ap, int) : \
	    (long)GET_ARG (N, ap, int))
#define	UARG() \
	(flags&LONGINT ? GET_ARG (N, ap, u_long) : \
	    flags&SHORTINT ? (u_long)(u_short)GET_ARG (N, ap, int) : \
	    flags&CHARINT ? (u_long)(unsigned char)GET_ARG (N, ap, int) : \
	    (u_long)GET_ARG (N, ap, u_int))
#endif

	CHECK_INIT (data, fp);
	_flockfile (fp);

	/* sorry, fprintf(read_only_file, "") returns EOF, not 0 */
	if (cantwrite (data, fp)) {
		_funlockfile (fp);	
		return (EOF);
	}

	/* optimise fprintf(stderr) (and other unbuffered Unix files) */
	if ((fp->_flags & (__SNBF|__SWR|__SRW)) == (__SNBF|__SWR) &&
	    fp->_file >= 0) {
		_funlockfile (fp);
		return (__sbprintf (data, fp, fmt0, ap));
	}

	fmt = (char *)fmt0;
	uio.uio_iov = iovp = iov;
	uio.uio_resid = 0;
	uio.uio_iovcnt = 0;
	ret = 0;
#ifndef _NO_POS_ARGS
	arg_index = 0;
	saved_fmt = NULL;
	arg_type[0] = -1;
	numargs = 0;
	is_pos_arg = 0;
#endif

	/*
	 * Scan the format for conversions (`%' character).
	 */
	for (;;) {
	        cp = fmt;
#ifdef _MB_CAPABLE
	        while ((n = _mbtowc_r (data, &wc, fmt, MB_CUR_MAX, &state)) > 0) {
                    if (wc == '%')
                        break;
                    fmt += n;
		}
#else
                while (*fmt != '\0' && *fmt != '%')
                    fmt += 1;
#endif
		if ((m = fmt - cp) != 0) {
			PRINT (cp, m);
			ret += m;
		}
#ifdef _MB_CAPABLE
		if (n <= 0)
                    goto done;
#else
                if (*fmt == '\0')
                    goto done;
#endif
		fmt_anchor = fmt;
		fmt++;		/* skip over '%' */

		flags = 0;
		dprec = 0;
		width = 0;
		prec = -1;
		sign = '\0';
#ifndef _NO_POS_ARGS
		N = arg_index;
		is_pos_arg = 0;
#endif

rflag:		ch = *fmt++;
reswitch:	switch (ch) {
#ifdef _WANT_IO_C99_FORMATS
		case '\'':
		  /* The ' flag is required by POSIX, but not C99.
		     In the C locale, LC_NUMERIC requires
		     thousands_sep to be the empty string.  And since
		     no other locales are supported (yet), this flag
		     is currently a no-op.  */
		  goto rflag;
#endif
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
#ifndef _NO_POS_ARGS
			/* we must check for positional arg used for dynamic width */
			n = N;
			old_is_pos_arg = is_pos_arg;
			is_pos_arg = 0;
			if (is_digit (*fmt)) {
				char *old_fmt = fmt;

				n = 0;
				ch = *fmt++;
				do {
					n = 10 * n + to_digit (ch);
					ch = *fmt++;
				} while (is_digit (ch));

				if (ch == '$') {
					if (n <= MAX_POS_ARGS) {
						n -= 1;
						is_pos_arg = 1;
					}
					else
						goto error;
				}
				else {
					fmt = old_fmt;
					goto rflag;
				}
			}
#endif /* !_NO_POS_ARGS */

			/*
			 * ``A negative field width argument is taken as a
			 * - flag followed by a positive field width.''
			 *	-- ANSI X3J11
			 * They don't exclude field widths read from args.
			 */
			width = GET_ARG (n, ap, int);
#ifndef _NO_POS_ARGS
			is_pos_arg = old_is_pos_arg;
#endif
			if (width >= 0)
				goto rflag;
			width = -width;
			/* FALLTHROUGH */
		case '-':
			flags |= LADJUST;
			goto rflag;
		case '+':
			sign = '+';
			goto rflag;
		case '.':
			if ((ch = *fmt++) == '*') {
#ifndef _NO_POS_ARGS
				/* we must check for positional arg used for dynamic width */
				n = N;
				old_is_pos_arg = is_pos_arg;
				is_pos_arg = 0;
				if (is_digit (*fmt)) {
					char *old_fmt = fmt;

					n = 0;
					ch = *fmt++;
					do {
						n = 10 * n + to_digit (ch);
						ch = *fmt++;
					} while (is_digit (ch));

					if (ch == '$') {
						if (n <= MAX_POS_ARGS) {
							n -= 1;
							is_pos_arg = 1;
						}
						else
							goto error;
					}
					else {
						fmt = old_fmt;
						goto rflag;
					}
				}
#endif /* !_NO_POS_ARGS */
				prec = GET_ARG (n, ap, int);
#ifndef _NO_POS_ARGS
				is_pos_arg = old_is_pos_arg;
#endif
				if (prec < 0)
					prec = -1;
				goto rflag;
			}
			n = 0;
			while (is_digit (ch)) {
				n = 10 * n + to_digit (ch);
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
				n = 10 * n + to_digit (ch);
				ch = *fmt++;
			} while (is_digit (ch));
#ifndef _NO_POS_ARGS
			if (ch == '$') {
				if (n <= MAX_POS_ARGS) {
					N = n - 1;
					is_pos_arg = 1;
					goto rflag;
				}
				else
					goto error;
			}
#endif /* !_NO_POS_ARGS */
			width = n;
			goto reswitch;
#ifdef FLOATING_POINT
		case 'L':
			flags |= LONGDBL;
			goto rflag;
#endif
		case 'h':
#ifdef _WANT_IO_C99_FORMATS
			if (*fmt == 'h') {
				fmt++;
				flags |= CHARINT;
			} else
#endif
				flags |= SHORTINT;
			goto rflag;
		case 'l':
#if defined _WANT_IO_C99_FORMATS || !defined _NO_LONGLONG
			if (*fmt == 'l') {
				fmt++;
				flags |= QUADINT;
			} else
#endif
				flags |= LONGINT;
			goto rflag;
		case 'q': /* extension */
			flags |= QUADINT;
			goto rflag;
#ifdef _WANT_IO_C99_FORMATS
		case 'j':
		  if (sizeof (intmax_t) == sizeof (long))
		    flags |= LONGINT;
		  else
		    flags |= QUADINT;
		  goto rflag;
		case 'z':
		  if (sizeof (size_t) < sizeof (int))
		    /* POSIX states size_t is 16 or more bits, as is short.  */
		    flags |= SHORTINT;
		  else if (sizeof (size_t) == sizeof (int))
		    /* no flag needed */;
		  else if (sizeof (size_t) <= sizeof (long))
		    flags |= LONGINT;
		  else
		    /* POSIX states that at least one programming
		       environment must support size_t no wider than
		       long, but that means other environments can
		       have size_t as wide as long long.  */
		    flags |= QUADINT;
		  goto rflag;
		case 't':
		  if (sizeof (ptrdiff_t) < sizeof (int))
		    /* POSIX states ptrdiff_t is 16 or more bits, as
		       is short.  */
		    flags |= SHORTINT;
		  else if (sizeof (ptrdiff_t) == sizeof (int))
		    /* no flag needed */;
		  else if (sizeof (ptrdiff_t) <= sizeof (long))
		    flags |= LONGINT;
		  else
		    /* POSIX states that at least one programming
		       environment must support ptrdiff_t no wider than
		       long, but that means other environments can
		       have ptrdiff_t as wide as long long.  */
		    flags |= QUADINT;
		  goto rflag;
		case 'C':
#endif /* _WANT_IO_C99_FORMATS */
		case 'c':
			cp = buf;
#ifdef _MB_CAPABLE
			if (ch == 'C' || (flags & LONGINT)) {
				mbstate_t ps;

				memset ((_PTR)&ps, '\0', sizeof (mbstate_t));
				if ((size = (int)_wcrtomb_r (data, cp,
					       (wchar_t)GET_ARG (N, ap, wint_t),
						&ps)) == -1) {
					fp->_flags |= __SERR;
					goto error; 
				}
			}
			else
#endif /* _MB_CAPABLE */
			{
				*cp = GET_ARG (N, ap, int);
				size = 1;
			}
			sign = '\0';
			break;
		case 'D':  /* extension */
			flags |= LONGINT;
			/*FALLTHROUGH*/
		case 'd':
		case 'i':
			_uquad = SARG ();
#ifndef _NO_LONGLONG
			if ((quad_t)_uquad < 0)
#else
			if ((long) _uquad < 0)
#endif
			{

				_uquad = -_uquad;
				sign = '-';
			}
			base = DEC;
			goto number;
#ifdef FLOATING_POINT
# ifdef _WANT_IO_C99_FORMATS
		case 'a':
		case 'A':
		case 'F':
# endif
		case 'e':
		case 'E':
		case 'f':
		case 'g':
		case 'G':
# ifdef _NO_LONGDBL
			if (flags & LONGDBL) {
				_fpvalue = (double) GET_ARG (N, ap, _LONG_DOUBLE);
			} else {
				_fpvalue = GET_ARG (N, ap, double);
			}

			/* do this before tricky precision changes

			   If the output is infinite or NaN, leading
			   zeros are not permitted.  Otherwise, scanf
			   could not read what printf wrote.
			 */
			if (isinf (_fpvalue)) {
				if (_fpvalue < 0)
					sign = '-';
				if (ch <= 'G') /* 'A', 'E', 'F', or 'G' */
					cp = "INF";
				else
					cp = "inf";
				size = 3;
				flags &= ~ZEROPAD;
				break;
			}
			if (isnan (_fpvalue)) {
				if (ch <= 'G') /* 'A', 'E', 'F', or 'G' */
					cp = "NAN";
				else
					cp = "nan";
				size = 3;
				flags &= ~ZEROPAD;
				break;
			}

# else /* !_NO_LONGDBL */

			if (flags & LONGDBL) {
				_fpvalue = GET_ARG (N, ap, _LONG_DOUBLE);
			} else {
				_fpvalue = (_LONG_DOUBLE)GET_ARG (N, ap, double);
			}

			/* do this before tricky precision changes */
			expt = _ldcheck (&_fpvalue);
			if (expt == 2) {
				if (_fpvalue < 0)
					sign = '-';
				if (ch <= 'G') /* 'A', 'E', 'F', or 'G' */
					cp = "INF";
				else
					cp = "inf";
				size = 3;
				flags &= ~ZEROPAD;
				break;
			}
			if (expt == 1) {
				if (ch <= 'G') /* 'A', 'E', 'F', or 'G' */
					cp = "NAN";
				else
					cp = "nan";
				size = 3;
				flags &= ~ZEROPAD;
				break;
			}
# endif /* !_NO_LONGDBL */

# ifdef _WANT_IO_C99_FORMATS
			if (ch == 'a' || ch == 'A') {
				ox[0] = '0';
				ox[1] = ch == 'a' ? 'x' : 'X';
				flags |= HEXPREFIX;
				if (prec >= BUF)
				  {
				    if ((malloc_buf =
					 (char *)_malloc_r (data, prec + 1))
					== NULL)
				      {
					fp->_flags |= __SERR;
					goto error;
				      }
				    cp = malloc_buf;
				  }
				else
				  cp = buf;
			} else
# endif /* _WANT_IO_C99_FORMATS */
			if (prec == -1) {
				prec = DEFPREC;
			} else if ((ch == 'g' || ch == 'G') && prec == 0) {
				prec = 1;
			}

			flags |= FPT;

			cp = cvt (data, _fpvalue, prec, flags, &softsign,
				  &expt, ch, &ndig, cp);

			if (ch == 'g' || ch == 'G') {
				if (expt <= -4 || expt > prec)
					ch -= 2; /* 'e' or 'E' */
				else
					ch = 'g';
			}
# ifdef _WANT_IO_C99_FORMATS
			else if (ch == 'F')
				ch = 'f';
# endif
			if (ch <= 'e') {	/* 'a', 'A', 'e', or 'E' fmt */
				--expt;
				expsize = exponent (expstr, expt, ch);
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
				sign = '-';
			break;
#endif /* FLOATING_POINT */
		case 'n':
#ifndef _NO_LONGLONG
			if (flags & QUADINT)
				*GET_ARG (N, ap, quad_ptr_t) = ret;
			else 
#endif
			if (flags & LONGINT)
				*GET_ARG (N, ap, long_ptr_t) = ret;
			else if (flags & SHORTINT)
				*GET_ARG (N, ap, short_ptr_t) = ret;
#ifdef _WANT_IO_C99_FORMATS
			else if (flags & CHARINT)
				*GET_ARG (N, ap, char_ptr_t) = ret;
#endif
			else
				*GET_ARG (N, ap, int_ptr_t) = ret;
			continue;	/* no output */
		case 'O': /* extension */
			flags |= LONGINT;
			/*FALLTHROUGH*/
		case 'o':
			_uquad = UARG ();
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
			_uquad = (uintptr_t) GET_ARG (N, ap, void_ptr_t);
			base = HEX;
			xdigs = "0123456789abcdef";
			flags |= HEXPREFIX;
			ox[0] = '0';
			ox[1] = ch = 'x';
			goto nosign;
		case 's':
#ifdef _WANT_IO_C99_FORMATS
		case 'S':
#endif
			sign = '\0';
			cp = GET_ARG (N, ap, char_ptr_t);
#ifndef __OPTIMIZE_SIZE__
			/* Behavior is undefined if the user passed a
			   NULL string when precision is not 0.
			   However, if we are not optimizing for size,
			   we might as well mirror glibc behavior.  */
			if (cp == NULL) {
				cp = "(null)";
				size = ((unsigned) prec > 6U) ? 6 : prec;
			}
			else
#endif /* __OPTIMIZE_SIZE__ */
#ifdef _MB_CAPABLE
			if (ch == 'S' || (flags & LONGINT)) {
				mbstate_t ps;
				_CONST wchar_t *wcp;

				wcp = (_CONST wchar_t *)cp;
				size = m = 0;
				memset ((_PTR)&ps, '\0', sizeof (mbstate_t));

				/* Count number of bytes needed for multibyte
				   string that will be produced from widechar
				   string.  */
				if (prec >= 0) {
					while (1) {
						if (wcp[m] == L'\0')
							break;
						if ((n = (int)_wcrtomb_r (data,
						     buf, wcp[m], &ps)) == -1) {
							fp->_flags |= __SERR;
							goto error;
						}
						if (n + size > prec)
							break;
						m += 1;
						size += n;
						if (size == prec)
							break;
					}
				}
				else {
					if ((size = (int)_wcsrtombs_r (data,
						   NULL, &wcp, 0, &ps)) == -1) {
						fp->_flags |= __SERR;
						goto error;
					}
					wcp = (_CONST wchar_t *)cp;
				}

				if (size == 0)
					break;

				if (size >= BUF) {
					if ((malloc_buf =
					     (char *)_malloc_r (data, size + 1))
					    == NULL) {
						fp->_flags |= __SERR;
						goto error;
					}
					cp = malloc_buf;
				} else
					cp = buf;

				/* Convert widechar string to multibyte string. */
				memset ((_PTR)&ps, '\0', sizeof (mbstate_t));
				if (_wcsrtombs_r (data, cp, &wcp, size, &ps)
				    != size) {
					fp->_flags |= __SERR;
					goto error;
				}
				cp[size] = '\0';
			}
			else
#endif /* _MB_CAPABLE */
			if (prec >= 0) {
				/*
				 * can't use strlen; can only look for the
				 * NUL in the first `prec' characters, and
				 * strlen () will go further.
				 */
				char *p = memchr (cp, 0, prec);

				if (p != NULL) {
					size = p - cp;
					if (size > prec)
						size = prec;
				} else
					size = prec;
			} else
				size = strlen (cp);

			break;
		case 'U': /* extension */
			flags |= LONGINT;
			/*FALLTHROUGH*/
		case 'u':
			_uquad = UARG ();
			base = DEC;
			goto nosign;
		case 'X':
			xdigs = "0123456789ABCDEF";
			goto hex;
		case 'x':
			xdigs = "0123456789abcdef";
hex:			_uquad = UARG ();
			base = HEX;
			/* leading 0x/X only if non-zero */
			if (flags & ALT && _uquad != 0) {
				ox[0] = '0';
				ox[1] = ch;
				flags |= HEXPREFIX;
			}

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
						*--cp = to_char (_uquad & 7);
						_uquad >>= 3;
					} while (_uquad);
					/* handle octal leading 0 */
					if (flags & ALT && *cp != '0')
						*--cp = '0';
					break;

				case DEC:
					/* many numbers are 1 digit */
					while (_uquad >= 10) {
						*--cp = to_char (_uquad % 10);
						_uquad /= 10;
					}
					*--cp = to_char (_uquad);
					break;

				case HEX:
					do {
						*--cp = xdigs[_uquad & 15];
						_uquad >>= 4;
					} while (_uquad);
					break;

				default:
					cp = "bug in vfprintf: bad base";
					size = strlen (cp);
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
		 * If flags&FPT, ch must be in [aAeEfg].
		 *
		 * Compute actual size, so we know how much to pad.
		 * size excludes decimal prec; realsz includes it.
		 */
		realsz = dprec > size ? dprec : size;
		if (sign)
			realsz++;
		if (flags & HEXPREFIX)
			realsz+= 2;

		/* right-adjusting blank padding */
		if ((flags & (LADJUST|ZEROPAD)) == 0)
			PAD (width - realsz, blanks);

		/* prefix */
		if (sign)
			PRINT (&sign, 1);
		if (flags & HEXPREFIX)
			PRINT (ox, 2);

		/* right-adjusting zero padding */
		if ((flags & (LADJUST|ZEROPAD)) == ZEROPAD)
			PAD (width - realsz, zeroes);

		/* leading zeroes from decimal precision */
		PAD (dprec - size, zeroes);

		/* the string or number proper */
#ifdef FLOATING_POINT
		if ((flags & FPT) == 0) {
			PRINT (cp, size);
		} else {	/* glue together f_p fragments */
			if (ch >= 'f') {	/* 'f' or 'g' */
				if (_fpvalue == 0) {
					/* kludge for __dtoa irregularity */
					PRINT ("0", 1);
					if (expt < ndig || flags & ALT) {
						PRINT (decimal_point, 1);
						PAD (ndig - 1, zeroes);
					}
				} else if (expt <= 0) {
					PRINT ("0", 1);
					if (expt || ndig || flags & ALT) {
						PRINT (decimal_point, 1);
						PAD (-expt, zeroes);
						PRINT (cp, ndig);
					}
				} else if (expt >= ndig) {
					PRINT (cp, ndig);
					PAD (expt - ndig, zeroes);
					if (flags & ALT)
						PRINT (decimal_point, 1);
				} else {
					PRINT (cp, expt);
					cp += expt;
					PRINT (decimal_point, 1);
					PRINT (cp, ndig - expt);
				}
			} else {	/* 'a', 'A', 'e', or 'E' */
				if (ndig > 1 || flags & ALT) {
					PRINT (cp, 1);
					cp++;
					PRINT (decimal_point, 1);
					if (_fpvalue) {
						PRINT (cp, ndig - 1);
					} else	/* 0.[0..] */
						/* __dtoa irregularity */
						PAD (ndig - 1, zeroes);
				} else	/* XeYYY */
					PRINT (cp, 1);
				PRINT (expstr, expsize);
			}
		}
#else /* !FLOATING_POINT */
		PRINT (cp, size);
#endif
		/* left-adjusting padding (always blank) */
		if (flags & LADJUST)
			PAD (width - realsz, blanks);

		/* finally, adjust ret */
		ret += width > realsz ? width : realsz;

		FLUSH ();	/* copy out the I/O vectors */

                if (malloc_buf != NULL) {
			_free_r (data, malloc_buf);
			malloc_buf = NULL;
		}
	}
done:
	FLUSH ();
error:
	if (malloc_buf != NULL)
		_free_r (data, malloc_buf);
	_funlockfile (fp);
	return (__sferror (fp) ? EOF : ret);
	/* NOTREACHED */
}

#ifdef FLOATING_POINT

/* Using reentrant DATA, convert finite VALUE into a string of digits
   with no decimal point, using NDIGITS precision and FLAGS as guides
   to whether trailing zeros must be included.  Set *SIGN to nonzero
   if VALUE was negative.  Set *DECPT to the exponent plus one.  Set
   *LENGTH to the length of the returned string.  CH must be one of
   [aAeEfFgG]; if it is [aA], then the return string lives in BUF,
   otherwise the return value shares the mprec reentrant storage.  */
static char *
cvt(struct _reent *data, _PRINTF_FLOAT_TYPE value, int ndigits, int flags,
    char *sign, int *decpt, int ch, int *length, char *buf)
{
	int mode, dsgn;
	char *digits, *bp, *rve;
# ifdef _NO_LONGDBL
	union double_union tmp;

	tmp.d = value;
	if (word0 (tmp) & Sign_bit) { /* this will check for < 0 and -0.0 */
		value = -value;
		*sign = '-';
	} else
		*sign = '\000';
# else /* !_NO_LONGDBL */
	union
	{
	  struct ldieee ieee;
	  _LONG_DOUBLE val;
	} ld;

	ld.val = value;
	if (ld.ieee.sign) { /* this will check for < 0 and -0.0 */
		value = -value;
		*sign = '-';
	} else
		*sign = '\000';
# endif /* !_NO_LONGDBL */

# ifdef _WANT_IO_C99_FORMATS
	if (ch == 'a' || ch == 'A') {
		/* This code assumes FLT_RADIX is a power of 2.  The initial
		   division ensures the digit before the decimal will be less
		   than FLT_RADIX (unless it is rounded later).	 There is no
		   loss of precision in these calculations.  */
		value = FREXP (value, decpt) / 8;
		if (!value)
			*decpt = 1;
		digits = ch == 'a' ? "0123456789abcdef" : "0123456789ABCDEF";
		bp = buf;
		do {
			value *= 16;
			mode = (int) value;
			value -= mode;
			*bp++ = digits[mode];
		} while (ndigits-- && value);
		if (value > 0.5 || (value == 0.5 && mode & 1)) {
			/* round to even */
			rve = bp;
			while (*--rve == digits[0xf]) {
				*rve = '0';
			}
			*rve = *rve == '9' ? digits[0xa] : *rve + 1;
		} else {
			while (ndigits-- >= 0) {
				*bp++ = '0';
			}
		}
		*length = bp - buf;
		return buf;
	}
# endif /* _WANT_IO_C99_FORMATS */
	if (ch == 'f' || ch == 'F') {
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

	digits = _DTOA_R (data, value, mode, ndigits, decpt, &dsgn, &rve);

	if ((ch != 'g' && ch != 'G') || flags & ALT) {	/* Print trailing zeros */
		bp = digits + ndigits;
		if (ch == 'f' || ch == 'F') {
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
exponent(char *p0, int exp, int fmtch)
{
	register char *p, *t;
	char expbuf[MAXEXPLEN];
# ifdef _WANT_IO_C99_FORMATS
	int isa = fmtch == 'a' || fmtch == 'A';
# else
#  define isa 0
# endif

	p = p0;
	*p++ = isa ? 'p' - 'a' + fmtch : fmtch;
	if (exp < 0) {
		exp = -exp;
		*p++ = '-';
	}
	else
		*p++ = '+';
	t = expbuf + MAXEXPLEN;
	if (exp > 9) {
		do {
			*--t = to_char (exp % 10);
		} while ((exp /= 10) > 9);
		*--t = to_char (exp);
		for (; t < expbuf + MAXEXPLEN; *p++ = *t++);
	}
	else {
		if (!isa)
			*p++ = '0';
		*p++ = to_char (exp);
	}
	return (p - p0);
}
#endif /* FLOATING_POINT */


#ifndef _NO_POS_ARGS

/* Positional argument support.
   Written by Jeff Johnston

   Copyright (c) 2002 Red Hat Incorporated.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

      Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

      Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
      
      The name of Red Hat Incorporated may not be used to endorse
      or promote products derived from this software without specific
      prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED.  IN NO EVENT SHALL RED HAT INCORPORATED BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */

typedef enum {
  ZERO,   /* '0' */
  DIGIT,  /* '1-9' */
  DOLLAR, /* '$' */
  MODFR,  /* spec modifier */
  SPEC,   /* format specifier */
  DOT,    /* '.' */
  STAR,   /* '*' */
  FLAG,   /* format flag */
  OTHER,  /* all other chars */ 
  MAX_CH_CLASS /* place-holder */
} CH_CLASS;

typedef enum { 
  START,  /* start */
  SFLAG,  /* seen a flag */
  WDIG,   /* seen digits in width area */
  WIDTH,  /* processed width */
  SMOD,   /* seen spec modifier */
  SDOT,   /* seen dot */ 
  VARW,   /* have variable width specifier */
  VARP,   /* have variable precision specifier */
  PREC,   /* processed precision */
  VWDIG,  /* have digits in variable width specification */
  VPDIG,  /* have digits in variable precision specification */
  DONE,   /* done */   
  MAX_STATE, /* place-holder */ 
} STATE;

typedef enum {
  NOOP,  /* do nothing */
  NUMBER, /* build a number from digits */
  SKIPNUM, /* skip over digits */
  GETMOD,  /* get and process format modifier */
  GETARG,  /* get and process argument */
  GETPW,   /* get variable precision or width */
  GETPWB,  /* get variable precision or width and pushback fmt char */
  GETPOS,  /* get positional parameter value */
  PWPOS,   /* get positional parameter value for variable width or precision */
} ACTION;

_CONST static CH_CLASS chclass[256] = {
  /* 00-07 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 08-0f */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 10-17 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 18-1f */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 20-27 */  FLAG,    OTHER,   OTHER,   FLAG,    DOLLAR,  OTHER,   OTHER,   FLAG,
  /* 28-2f */  OTHER,   OTHER,   STAR,    FLAG,    OTHER,   FLAG,    DOT,     OTHER,
  /* 30-37 */  ZERO,    DIGIT,   DIGIT,   DIGIT,   DIGIT,   DIGIT,   DIGIT,   DIGIT,
  /* 38-3f */  DIGIT,   DIGIT,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 40-47 */  OTHER,   SPEC,    OTHER,   SPEC,    SPEC,    SPEC,    SPEC,    SPEC,
  /* 48-4f */  OTHER,   OTHER,   OTHER,   OTHER,   MODFR,   OTHER,   OTHER,   SPEC, 
  /* 50-57 */  OTHER,   OTHER,   OTHER,   SPEC,    OTHER,   SPEC,    OTHER,   OTHER,
  /* 58-5f */  SPEC,    OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 60-67 */  OTHER,   SPEC,    OTHER,   SPEC,    SPEC,    SPEC,    SPEC,    SPEC,
  /* 68-6f */  MODFR,   SPEC,    MODFR,   OTHER,   MODFR,   OTHER,   SPEC,    SPEC,
  /* 70-77 */  SPEC,    MODFR,   OTHER,   SPEC,    MODFR,   SPEC,    OTHER,   OTHER,
  /* 78-7f */  SPEC,    OTHER,   MODFR,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 80-87 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 88-8f */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 90-97 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* 98-9f */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* a0-a7 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* a8-af */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* b0-b7 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* b8-bf */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* c0-c7 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* c8-cf */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* d0-d7 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* d8-df */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* e0-e7 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* e8-ef */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* f0-f7 */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
  /* f8-ff */  OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,   OTHER,
};

_CONST static STATE state_table[MAX_STATE][MAX_CH_CLASS] = {
  /*             '0'     '1-9'     '$'     MODFR    SPEC    '.'     '*'    FLAG    OTHER */ 
  /* START */  { SFLAG,   WDIG,    DONE,   SMOD,    DONE,   SDOT,  VARW,   SFLAG,  DONE },
  /* SFLAG */  { SFLAG,   WDIG,    DONE,   SMOD,    DONE,   SDOT,  VARW,   SFLAG,  DONE },
  /* WDIG  */  { DONE,    DONE,    WIDTH,  SMOD,    DONE,   SDOT,  DONE,   DONE,   DONE },
  /* WIDTH */  { DONE,    DONE,    DONE,   SMOD,    DONE,   SDOT,  DONE,   DONE,   DONE },
  /* SMOD  */  { DONE,    DONE,    DONE,   DONE,    DONE,   DONE,  DONE,   DONE,   DONE },
  /* SDOT  */  { SDOT,    PREC,    DONE,   SMOD,    DONE,   DONE,  VARP,   DONE,   DONE },
  /* VARW  */  { DONE,    VWDIG,   DONE,   SMOD,    DONE,   SDOT,  DONE,   DONE,   DONE },
  /* VARP  */  { DONE,    VPDIG,   DONE,   SMOD,    DONE,   DONE,  DONE,   DONE,   DONE },
  /* PREC  */  { DONE,    DONE,    DONE,   SMOD,    DONE,   DONE,  DONE,   DONE,   DONE },
  /* VWDIG */  { DONE,    DONE,    WIDTH,  DONE,    DONE,   DONE,  DONE,   DONE,   DONE },
  /* VPDIG */  { DONE,    DONE,    PREC,   DONE,    DONE,   DONE,  DONE,   DONE,   DONE },
};

_CONST static ACTION action_table[MAX_STATE][MAX_CH_CLASS] = {
  /*             '0'     '1-9'     '$'     MODFR    SPEC    '.'     '*'    FLAG    OTHER */ 
  /* START */  { NOOP,    NUMBER,  NOOP,   GETMOD,  GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* SFLAG */  { NOOP,    NUMBER,  NOOP,   GETMOD,  GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* WDIG  */  { NOOP,    NOOP,    GETPOS, GETMOD,  GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* WIDTH */  { NOOP,    NOOP,    NOOP,   GETMOD,  GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* SMOD  */  { NOOP,    NOOP,    NOOP,   NOOP,    GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* SDOT  */  { NOOP,    SKIPNUM, NOOP,   GETMOD,  GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* VARW  */  { NOOP,    NUMBER,  NOOP,   GETPW,   GETPWB, GETPW, NOOP,   NOOP,   NOOP },
  /* VARP  */  { NOOP,    NUMBER,  NOOP,   GETPW,   GETPWB, NOOP,  NOOP,   NOOP,   NOOP },
  /* PREC  */  { NOOP,    NOOP,    NOOP,   GETMOD,  GETARG, NOOP,  NOOP,   NOOP,   NOOP },
  /* VWDIG */  { NOOP,    NOOP,    PWPOS,  NOOP,    NOOP,   NOOP,  NOOP,   NOOP,   NOOP },
  /* VPDIG */  { NOOP,    NOOP,    PWPOS,  NOOP,    NOOP,   NOOP,  NOOP,   NOOP,   NOOP },
};

/* function to get positional parameter N where n = N - 1 */
static union arg_val *
_DEFUN(get_arg, (data, n, fmt, ap, numargs_p, args, arg_type, last_fmt),
       struct _reent *data _AND
       int n               _AND
       char *fmt           _AND
       va_list *ap         _AND
       int *numargs_p      _AND
       union arg_val *args _AND
       int *arg_type       _AND
       char **last_fmt)
{
  int ch;
  int number, flags;
  int spec_type;
  int numargs = *numargs_p;
  CH_CLASS chtype;
  STATE state, next_state;
  ACTION action;
  int pos, last_arg;
  int max_pos_arg = n;
  /* Only need types that can be reached via vararg promotions.  */
  enum types { INT, LONG_INT, QUAD_INT, CHAR_PTR, DOUBLE, LONG_DOUBLE, WIDE_CHAR };
# ifdef _MB_CAPABLE
  wchar_t wc;
  mbstate_t wc_state;
  int nbytes;
# endif

  /* if this isn't the first call, pick up where we left off last time */
  if (*last_fmt != NULL)
    fmt = *last_fmt;

# ifdef _MB_CAPABLE
  memset (&wc_state, '\0', sizeof (wc_state));
# endif

  /* we need to process either to end of fmt string or until we have actually
     read the desired parameter from the vararg list. */
  while (*fmt && n >= numargs)
    {
# ifdef _MB_CAPABLE
      while ((nbytes = _mbtowc_r (data, &wc, fmt, MB_CUR_MAX, &wc_state)) > 0) 
	{
	  fmt += nbytes;
	  if (wc == '%') 
	    break;
	}

      if (nbytes <= 0)
	break;
# else
      while (*fmt != '\0' && *fmt != '%')
	fmt += 1;

      if (*fmt == '\0')
	break;
# endif /* ! _MB_CAPABLE */
      state = START;
      flags = 0;
      pos = -1;
      number = 0;
      spec_type = INT;

      /* Use state/action table to process format specifiers.  We ignore invalid
         formats and we are only interested in information that tells us how to
         read the vararg list. */
      while (state != DONE)
	{
	  ch = *fmt++;
	  chtype = chclass[ch];
	  next_state = state_table[state][chtype];
	  action = action_table[state][chtype];
	  state = next_state;

	  switch (action)
	    {
	    case GETMOD:  /* we have format modifier */
	      switch (ch)
		{
		case 'h':
		  /* No flag needed, since short and char promote to int.  */
		  break;
		case 'L':
		  flags |= LONGDBL;
		  break;
		case 'q':
		  flags |= QUADINT;
		  break;
# ifdef _WANT_IO_C99_FORMATS
		case 'j':
		  if (sizeof (intmax_t) == sizeof (long))
		    flags |= LONGINT;
		  else
		    flags |= QUADINT;
		  break;
		case 'z':
		  if (sizeof (size_t) <= sizeof (int))
		    /* no flag needed */;
		  else if (sizeof (size_t) <= sizeof (long))
		    flags |= LONGINT;
		  else
		    /* POSIX states that at least one programming
		       environment must support size_t no wider than
		       long, but that means other environments can
		       have size_t as wide as long long.  */
		    flags |= QUADINT;
		  break;
		case 't':
		  if (sizeof (ptrdiff_t) <= sizeof (int))
		    /* no flag needed */;
		  else if (sizeof (ptrdiff_t) <= sizeof (long))
		    flags |= LONGINT;
		  else
		    /* POSIX states that at least one programming
		       environment must support ptrdiff_t no wider than
		       long, but that means other environments can
		       have ptrdiff_t as wide as long long.  */
		    flags |= QUADINT;
		  break;
# endif /* _WANT_IO_C99_FORMATS */
		case 'l':
		default:
# if defined _WANT_IO_C99_FORMATS || !defined _NO_LONGLONG
		  if (*fmt == 'l')
		    {
		      flags |= QUADINT;
		      ++fmt;
		    }
		  else
# endif
		    flags |= LONGINT;
		  break;
		}
	      break;
	    case GETARG: /* we have format specifier */
	      {
		numargs &= (MAX_POS_ARGS - 1);
		/* process the specifier and translate it to a type to fetch from varargs */
		switch (ch)
		  {
		  case 'd':
		  case 'i':
		  case 'o':
		  case 'x':
		  case 'X':
		  case 'u':
		    if (flags & LONGINT)
		      spec_type = LONG_INT;
# ifndef _NO_LONGLONG
		    else if (flags & QUADINT)
		      spec_type = QUAD_INT;
# endif
		    else
		      spec_type = INT;
		    break;
		  case 'D':
		  case 'U':
		  case 'O':
		    spec_type = LONG_INT;
		    break;
# ifdef _WANT_IO_C99_FORMATS
		  case 'a':
		  case 'A':
		  case 'F':
# endif
		  case 'f':
		  case 'g':
		  case 'G':
		  case 'E':
		  case 'e':
# ifndef _NO_LONGDBL
		    if (flags & LONGDBL)
		      spec_type = LONG_DOUBLE;
		    else
# endif
		      spec_type = DOUBLE;
		    break;
		  case 's':
# ifdef _WANT_IO_C99_FORMATS
		  case 'S':
# endif
		  case 'p':
		  case 'n':
		    spec_type = CHAR_PTR;
		    break;
		  case 'c':
# ifdef _WANT_IO_C99_FORMATS
		    if (flags & LONGINT)
		      spec_type = WIDE_CHAR;
		    else
# endif
		      spec_type = INT;
		    break;
# ifdef _WANT_IO_C99_FORMATS
		  case 'C':
		    spec_type = WIDE_CHAR;
		    break;
# endif
		  }

		/* if we have a positional parameter, just store the type, otherwise
		   fetch the parameter from the vararg list */
		if (pos != -1)
		  arg_type[pos] = spec_type;
		else
		  {
		    switch (spec_type)
		      {
		      case LONG_INT:
			args[numargs++].val_long = va_arg (*ap, long);
			break;
		      case QUAD_INT:
			args[numargs++].val_quad_t = va_arg (*ap, quad_t);
			break;
		      case WIDE_CHAR:
			args[numargs++].val_wint_t = va_arg (*ap, wint_t);
			break;
		      case INT:
			args[numargs++].val_int = va_arg (*ap, int);
			break;
		      case CHAR_PTR:
			args[numargs++].val_char_ptr_t = va_arg (*ap, char *);
			break;
		      case DOUBLE:
			args[numargs++].val_double = va_arg (*ap, double);
			break;
		      case LONG_DOUBLE:
			args[numargs++].val__LONG_DOUBLE = va_arg (*ap, _LONG_DOUBLE);
			break;
		      }
		  }
	      }
	      break;
	    case GETPOS: /* we have positional specifier */
	      if (arg_type[0] == -1)
		memset (arg_type, 0, sizeof (int) * MAX_POS_ARGS);
	      pos = number - 1;
	      max_pos_arg = (max_pos_arg > pos ? max_pos_arg : pos);
	      break;
	    case PWPOS:  /* we have positional specifier for width or precision */
	      if (arg_type[0] == -1)
		memset (arg_type, 0, sizeof (int) * MAX_POS_ARGS);
	      number -= 1;
	      arg_type[number] = INT;
	      max_pos_arg = (max_pos_arg > number ? max_pos_arg : number);
	      break;
	    case GETPWB: /* we require format pushback */
	      --fmt;
	      /* fallthrough */
	    case GETPW:  /* we have a variable precision or width to acquire */
	      args[numargs++].val_int = va_arg (*ap, int);
	      break;
	    case NUMBER: /* we have a number to process */
	      number = (ch - '0');
	      while ((ch = *fmt) != '\0' && is_digit (ch))
		{
		  number = number * 10 + (ch - '0');
		  ++fmt;
		}
	      break;
	    case SKIPNUM: /* we have a number to skip */
	      while ((ch = *fmt) != '\0' && is_digit (ch))
		++fmt;
	      break;
	    case NOOP:
	    default:
	      break; /* do nothing */
	    }
	}
    }

  /* process all arguments up to at least the one we are looking for and if we
     have seen the end of the string, then process up to the max argument needed */
  if (*fmt == '\0')
    last_arg = max_pos_arg;
  else
    last_arg = n;

  while (numargs <= last_arg)
    {
      switch (arg_type[numargs])
	{
	case LONG_INT:
	  args[numargs++].val_long = va_arg (*ap, long);
	  break;
	case QUAD_INT:
	  args[numargs++].val_quad_t = va_arg (*ap, quad_t);
	  break;
	case CHAR_PTR:
	  args[numargs++].val_char_ptr_t = va_arg (*ap, char *);
	  break;
	case DOUBLE:
	  args[numargs++].val_double = va_arg (*ap, double);
	  break;
	case LONG_DOUBLE:
	  args[numargs++].val__LONG_DOUBLE = va_arg (*ap, _LONG_DOUBLE);
	  break;
	case WIDE_CHAR:
	  args[numargs++].val_wint_t = va_arg (*ap, wint_t);
	  break;
	case INT:
	default:
	  args[numargs++].val_int = va_arg (*ap, int);
	  break;
	}
    }

  /* alter the global numargs value and keep a reference to the last bit of the fmt
     string we processed here because the caller will continue processing where we started */
  *numargs_p = numargs;
  *last_fmt = fmt;
  return &args[n];
}
#endif /* !_NO_POS_ARGS */
