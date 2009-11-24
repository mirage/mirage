/*
FUNCTION
<<vscanf>>, <<vfscanf>>, <<vsscanf>>---format argument list

INDEX
	vscanf
INDEX
	vfscanf
INDEX
	vsscanf

ANSI_SYNOPSIS
	#include <stdio.h>
	#include <stdarg.h>
	int vscanf(const char *<[fmt]>, va_list <[list]>);
	int vfscanf(FILE *<[fp]>, const char *<[fmt]>, va_list <[list]>);
	int vsscanf(const char *<[str]>, const char *<[fmt]>, va_list <[list]>);

	int _vscanf_r(void *<[reent]>, const char *<[fmt]>, 
                       va_list <[list]>);
	int _vfscanf_r(void *<[reent]>, FILE *<[fp]>, const char *<[fmt]>, 
                       va_list <[list]>);
	int _vsscanf_r(void *<[reent]>, const char *<[str]>, const char *<[fmt]>, 
                       va_list <[list]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	#include <varargs.h>
	int vscanf( <[fmt]>, <[ist]>)
	char *<[fmt]>;
	va_list <[list]>;

	int vfscanf( <[fp]>, <[fmt]>, <[list]>)
	FILE *<[fp]>;
	char *<[fmt]>;
	va_list <[list]>;
	
	int vsscanf( <[str]>, <[fmt]>, <[list]>)
	char *<[str]>;
	char *<[fmt]>;
	va_list <[list]>;

	int _vscanf_r( <[reent]>, <[fmt]>, <[ist]>)
	char *<[reent]>;
	char *<[fmt]>;
	va_list <[list]>;

	int _vfscanf_r( <[reent]>, <[fp]>, <[fmt]>, <[list]>)
	char *<[reent]>;
	FILE *<[fp]>;
	char *<[fmt]>;
	va_list <[list]>;
	
	int _vsscanf_r( <[reent]>, <[str]>, <[fmt]>, <[list]>)
	char *<[reent]>;
	char *<[str]>;
	char *<[fmt]>;
	va_list <[list]>;

DESCRIPTION
<<vscanf>>, <<vfscanf>>, and <<vsscanf>> are (respectively) variants
of <<scanf>>, <<fscanf>>, and <<sscanf>>.  They differ only in 
allowing their caller to pass the variable argument list as a 
<<va_list>> object (initialized by <<va_start>>) rather than 
directly accepting a variable number of arguments.

RETURNS
The return values are consistent with the corresponding functions:
<<vscanf>> returns the number of input fields successfully scanned,
converted, and stored; the return value does not include scanned
fields which were not stored.  

If <<vscanf>> attempts to read at end-of-file, the return value 
is <<EOF>>.

If no fields were stored, the return value is <<0>>.

The routines <<_vscanf_r>>, <<_vfscanf_f>>, and <<_vsscanf_r>> are
reentrant versions which take an additional first parameter which points to the
reentrancy structure.

PORTABILITY
These are GNU extensions.

Supporting OS subroutines required:
*/

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

#include <_ansi.h>
#include <reent.h>
#include <newlib.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <wchar.h>
#include <string.h>
#ifdef _HAVE_STDC
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include "local.h"

#ifndef	NO_FLOATING_POINT
#define FLOATING_POINT
#endif

#ifdef FLOATING_POINT
#include <float.h>

/* Currently a test is made to see if long double processing is warranted.
   This could be changed in the future should the _ldtoa_r code be
   preferred over _dtoa_r.  */
#define _NO_LONGDBL
#if defined _WANT_IO_LONG_DOUBLE && (LDBL_MANT_DIG > DBL_MANT_DIG)
#undef _NO_LONGDBL
extern _LONG_DOUBLE _strtold _PARAMS((char *s, char **sptr));
#endif

#define _NO_LONGLONG
#if defined _WANT_IO_LONG_LONG && defined __GNUC__
# undef _NO_LONGLONG
#endif

#include "floatio.h"
#define	BUF	(MAXEXP+MAXFRACT+3)	/* 3 = sign + decimal point + NUL */
/* An upper bound for how long a long prints in decimal.  4 / 13 approximates
   log (2).  Add one char for roundoff compensation and one for the sign.  */
#define MAX_LONG_LEN ((CHAR_BIT * sizeof (long)  - 1) * 4 / 13 + 2)
#else
#define	BUF	40
#endif

/*
 * Flags used during conversion.
 */

#define	LONG		0x01	/* l: long or double */
#define	LONGDBL		0x02	/* L: long double or long long */
#define	SHORT		0x04	/* h: short */
#define	SUPPRESS	0x10	/* suppress assignment */
#define	POINTER		0x20	/* weird %p pointer (`fake hex') */
#define	NOSKIP		0x40	/* do not skip blanks */

/*
 * The following are used in numeric conversions only:
 * SIGNOK, NDIGITS, DPTOK, and EXPOK are for floating point;
 * SIGNOK, NDIGITS, PFXOK, and NZDIGITS are for integral.
 */

#define	SIGNOK		0x80	/* +/- is (still) legal */
#define	NDIGITS		0x100	/* no digits detected */

#define	DPTOK		0x200	/* (float) decimal point is still legal */
#define	EXPOK		0x400	/* (float) exponent (e+3, etc) still legal */

#define	PFXOK		0x200	/* 0x prefix is (still) legal */
#define	NZDIGITS	0x400	/* no zero digits detected */
#define	NNZDIGITS	0x800	/* no non-zero digits detected */

#define	VECTOR		0x2000	/* v: vector */
#define	FIXEDPOINT	0x4000	/* r/R: fixed-point */
#define	SIGNED  	0x8000	/* r: signed fixed-point */

/*
 * Conversion types.
 */

#define	CT_CHAR		0	/* %c conversion */
#define	CT_CCL		1	/* %[...] conversion */
#define	CT_STRING	2	/* %s conversion */
#define	CT_INT		3	/* integer, i.e., strtol or strtoul */
#define	CT_FLOAT	4	/* floating, i.e., strtod */

#if 0
#define u_char unsigned char
#endif
#define u_char char
#define u_long unsigned long

#ifndef _NO_LONGLONG
typedef unsigned long long u_long_long;
#endif

typedef union
{
  char c[16] __attribute__ ((__aligned__ (16)));
  short h[8];
  long l[4];
  int i[4];
  float f[4];
} vec_union;

/*static*/ u_char *__sccl ();

/*
 * vfscanf
 */

#define BufferEmpty (fp->_r <= 0 && __srefill(fp))

#ifndef _REENT_ONLY

int
_DEFUN (vfscanf, (fp, fmt, ap), 
    register FILE *fp _AND 
    _CONST char *fmt _AND 
    va_list ap)
{
  CHECK_INIT(_REENT, fp);
  return __svfscanf_r (_REENT, fp, fmt, ap);
}

int
__svfscanf (fp, fmt0, ap)
     register FILE *fp;
     char _CONST *fmt0;
     va_list ap;
{
  return __svfscanf_r (_REENT, fp, fmt0, ap);
}

#endif /* !_REENT_ONLY */

int
_DEFUN (_vfscanf_r, (data, fp, fmt, ap),
    struct _reent *data _AND 
    register FILE *fp _AND 
    _CONST char *fmt _AND 
    va_list ap)
{
  return __svfscanf_r (data, fp, fmt, ap);
}


int
__svfscanf_r (rptr, fp, fmt0, ap)
     struct _reent *rptr;
     register FILE *fp;
     char _CONST *fmt0;
     va_list ap;
{
  register u_char *fmt = (u_char *) fmt0;
  register int c;		/* character from format, or conversion */
  register int type;		/* conversion type */
  register size_t width;	/* field width, or 0 */
  register char *p;		/* points into all kinds of strings */
  register int n;		/* handy integer */
  register int flags;		/* flags as defined above */
  register char *p0;		/* saves original value of p when necessary */
  int orig_flags;               /* saved flags used when processing vector */
  int int_width;                /* tmp area to store width when processing int */
  int nassigned;		/* number of fields assigned */
  int nread;			/* number of characters consumed from fp */
  int base = 0;			/* base argument to strtol/strtoul */
  int nbytes = 1;               /* number of bytes read from fmt string */
  wchar_t wc;                   /* wchar to use to read format string */
  char vec_sep;                 /* vector separator char */
  char last_space_char;         /* last white-space char eaten - needed for vec support */
  int vec_read_count;           /* number of vector items to read separately */
  int looped;                   /* has vector processing looped */
  u_long (*ccfn) () = 0;	/* conversion function (strtol/strtoul) */
  char ccltab[256];		/* character class table for %[...] */
  char buf[BUF];		/* buffer for numeric conversions */
  vec_union vec_buf;
  char *lptr;                   /* literal pointer */
#ifdef _MB_CAPABLE
  mbstate_t state;                /* value to keep track of multibyte state */
#endif

  char *ch_dest;
  short *sp;
  int *ip;
  float *flp;
  _LONG_DOUBLE *ldp;
  double *dp;
  long *lp;
#ifndef _NO_LONGLONG
  long long *llp;
#else
	u_long _uquad;
#endif

  /* `basefix' is used to avoid `if' tests in the integer scanner */
  static _CONST short basefix[17] =
    {10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16};

  nassigned = 0;
  nread = 0;
  for (;;)
    {
#ifndef _MB_CAPABLE
      wc = *fmt;
#else
      memset (&state, '\0', sizeof (state));
      nbytes = _mbtowc_r (rptr, &wc, fmt, MB_CUR_MAX, &state);
#endif
      fmt += nbytes;
      if (wc == 0)
	return nassigned;
      if (nbytes == 1 && isspace (wc))
	{
	  for (;;)
	    {
	      if (BufferEmpty)
		return nassigned;
	      if (!isspace (*fp->_p))
		break;
	      nread++, fp->_r--, fp->_p++;
	    }
	  continue;
	}
      if (wc != '%')
	goto literal;
      width = 0;
      flags = 0;
      vec_sep = ' ';
      vec_read_count = 0;
      looped = 0;

      /*
       * switch on the format.  continue if done; break once format
       * type is derived.
       */

    again:
      c = *fmt++;

      switch (c)
	{
	case '%':
	literal:
          lptr = fmt - nbytes;
          for (n = 0; n < nbytes; ++n)
            {
	      if (BufferEmpty)
	        goto input_failure;
	      if (*fp->_p != *lptr)
	        goto match_failure;
	      fp->_r--, fp->_p++;
	      nread++;
              ++lptr;
            }
	  continue;

	case '*':
	  flags |= SUPPRESS;
	  goto again;
	case ',':
	case ';':
	case ':':
	case '_':
	  if (flags == SUPPRESS || flags == 0)
	    vec_sep = c;
	  goto again;
	case 'l':
	  if (flags & SHORT)
	    continue; /* invalid format, don't process any further */
	  if (flags & LONG)
	    {
	      flags &= ~LONG;
	      flags &= ~VECTOR;
	      flags |= LONGDBL;
	    }
	  else
	    {
	      flags |= LONG;
	      if (flags & VECTOR)
		vec_read_count = 4;
	    }
	  goto again;
	case 'L':
	  flags |= LONGDBL;
	  flags &= ~VECTOR;
	  goto again;
	case 'h':
	  flags |= SHORT;
	  if (flags & LONG)
	    continue;  /* invalid format, don't process any further */
	  if (flags & VECTOR)
	    vec_read_count = 8;
	  goto again;
#ifdef __ALTIVEC__
	case 'v':
	  flags |= VECTOR;
	  vec_read_count = (flags & SHORT) ? 8 : ((flags & LONG) ? 4 : 16);
	  goto again;
#endif
	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	  width = width * 10 + c - '0';
	  goto again;

	  /*
	   * Conversions. Those marked `compat' are for
	   * 4.[123]BSD compatibility.
	   *
	   * (According to ANSI, E and X formats are supposed to
	   * the same as e and x.  Sorry about that.)
	   */

	case 'D':		/* compat */
	  flags |= LONG;
	  /* FALLTHROUGH */
	case 'd':
	  type = CT_INT;
	  ccfn = (u_long (*)())_strtol_r;
	  base = 10;
	  break;

	case 'i':
	  type = CT_INT;
	  ccfn = (u_long (*)())_strtol_r;
	  base = 0;
	  break;

	case 'O':		/* compat */
	  flags |= LONG;
	  /* FALLTHROUGH */
	case 'o':
	  type = CT_INT;
	  ccfn = _strtoul_r;
	  base = 8;
	  break;

	case 'u':
	  type = CT_INT;
	  ccfn = _strtoul_r;
	  base = 10;
	  break;

	case 'X':		/* compat   XXX */
	case 'x':
	  flags |= PFXOK;	/* enable 0x prefixing */
	  type = CT_INT;
	  ccfn = _strtoul_r;
	  base = 16;
	  break;

#ifdef FLOATING_POINT
	case 'E':		/* compat   XXX */
	case 'G':		/* compat   XXX */
/* ANSI says that E,G and X behave the same way as e,g,x */
	  /* FALLTHROUGH */
	case 'e':
	case 'f':
	case 'g':
	  type = CT_FLOAT;
	  if (flags & VECTOR)
	    vec_read_count = 4;
	  break;
       
# ifdef __SPE__
	  /* treat fixed-point like %f floating point */
        case 'r':
	  flags |= SIGNED;
	  /* fallthrough */
        case 'R':
          flags |= FIXEDPOINT;
	  type = CT_FLOAT;
          break;
# endif
#endif

	case 's':
	  flags &= ~VECTOR;
	  type = CT_STRING;
	  break;

	case '[':
	  fmt = __sccl (ccltab, fmt);
	  flags |= NOSKIP;
	  flags &= ~VECTOR;
	  type = CT_CCL;
	  break;

	case 'c':
	  flags |= NOSKIP;
	  type = CT_CHAR;
	  if (flags & VECTOR)
	    {
	      /* not allowed to have h or l with c specifier */
	      if (flags & (LONG | SHORT))
		continue;  /* invalid format don't process any further */
	      width = 0;
	      vec_read_count = 16;
	    }
	  break;

	case 'p':		/* pointer format is like hex */
	  flags |= POINTER | PFXOK;
	  type = CT_INT;
	  ccfn = _strtoul_r;
	  base = 16;
	  break;

	case 'n':
	  if (flags & SUPPRESS)	/* ??? */
	    continue;
	  flags &= ~VECTOR;
	  if (flags & SHORT)
	    {
	      sp = va_arg (ap, short *);
	      *sp = nread;
	    }
	  else if (flags & LONG)
	    {
	      lp = va_arg (ap, long *);
	      *lp = nread;
	    }
#ifndef _NO_LONGLONG
	  else if (flags & LONGDBL)
	    {
	      llp = va_arg (ap, long long*);
	      *llp = nread;
	    }
#endif
	  else
	    {
	      ip = va_arg (ap, int *);
	      *ip = nread;
	    }
	  continue;

	  /*
	   * Disgusting backwards compatibility hacks.	XXX
	   */
	case '\0':		/* compat */
	  return EOF;

	default:		/* compat */
	  if (isupper (c))
	    flags |= LONG;
	  type = CT_INT;
	  ccfn = (u_long (*)())_strtol_r;
	  base = 10;
	  break;
	}

    process:
      /*
       * We have a conversion that requires input.
       */
      if (BufferEmpty)
	goto input_failure;

      /*
       * Consume leading white space, except for formats that
       * suppress this.
       */
      last_space_char = '\0';

      if ((flags & NOSKIP) == 0)
	{
	  while (isspace (*fp->_p))
	    {
	      last_space_char = *fp->_p;
	      nread++;
	      if (--fp->_r > 0)
		fp->_p++;
	      else
#ifndef CYGNUS_NEC
	      if (__srefill (fp))
#endif
		goto input_failure;
	    }
	  /*
	   * Note that there is at least one character in the
	   * buffer, so conversions that do not set NOSKIP ca
	   * no longer result in an input failure.
	   */
	}

      /* for vector formats process separator characters after first loop */
      if (looped && (flags & VECTOR))
	{
	  flags = orig_flags; 
	  /* all formats other than default char have a separator char */
	  if (vec_sep != ' ' || type != CT_CHAR)
	    {
	      if (vec_sep == ' ' && last_space_char != ' ' ||
		  vec_sep != ' ' && *fp->_p != vec_sep)
		goto match_failure;
	      if (vec_sep != ' ')
		{
		  nread++;
		  if (--fp->_r > 0)
		    fp->_p++;
		  else
#ifndef CYGNUS_NEC
		    if (__srefill (fp))
#endif
		      goto input_failure;
		}
	    }
	  /* after eating the separator char, we must eat any white-space
	     after the separator char that precedes the data to convert */
	  if ((flags & NOSKIP) == 0)
	    {
	      while (isspace (*fp->_p))
		{
		  last_space_char = *fp->_p;
		  nread++;
		  if (--fp->_r > 0)
		    fp->_p++;
		  else
#ifndef CYGNUS_NEC
		    if (__srefill (fp))
#endif
		      goto input_failure;
		}
	    }

 	}
      else /* save to counter-act changes made to flags when processing */
	orig_flags = flags;

      /*
       * Do the conversion.
       */
      switch (type)
	{

	case CT_CHAR:
	  /* scan arbitrary characters (sets NOSKIP) */
	  if (width == 0)
	    width = 1;
	  if (flags & SUPPRESS)
	    {
	      size_t sum = 0;

	      for (;;)
		{
		  if ((n = fp->_r) < (int)width)
		    {
		      sum += n;
		      width -= n;
		      fp->_p += n;
#ifndef CYGNUS_NEC
		      if (__srefill (fp))
			{
#endif
			  if (sum == 0)
			    goto input_failure;
			  break;
#ifndef CYGNUS_NEC
			}
#endif
		    }
		  else
		    {
		      sum += width;
		      fp->_r -= width;
		      fp->_p += width;
		      break;
		    }
		}
	      nread += sum;
	    }
	  else
	    {
	      int n = width;
	      if (!looped)
		{
		  if (flags & VECTOR)
		    ch_dest = vec_buf.c;
		  else
		    ch_dest = va_arg (ap, char *);
		}
#ifdef CYGNUS_NEC
	      /* Kludge city for the moment */
	      if (fp->_r == 0)
		goto input_failure;

	      while (n && fp->_r)
		{
		  *ch_dest++ = *(fp->_p++);
		  n--;
		  fp->_r--;
		  nread++;
		}
#else
	      size_t r = fread (ch_dest, 1, width, fp);

	      if (r == 0)
		goto input_failure;
	      nread += r;
	      ch_dest += r;
#endif
	      if (!(flags & VECTOR))
		nassigned++;
	    }
	  break;

	case CT_CCL:
	  /* scan a (nonempty) character class (sets NOSKIP) */
	  if (width == 0)
	    width = ~0;		/* `infinity' */
	  /* take only those things in the class */
	  if (flags & SUPPRESS)
	    {
	      n = 0;
	      while (ccltab[*fp->_p])
		{
		  n++, fp->_r--, fp->_p++;
		  if (--width == 0)
		    break;
		  if (BufferEmpty)
		    {
		      if (n == 0)
			goto input_failure;
		      break;
		    }
		}
	      if (n == 0)
		goto match_failure;
	    }
	  else
	    {
	      p0 = p = va_arg (ap, char *);
	      while (ccltab[*fp->_p])
		{
		  fp->_r--;
		  *p++ = *fp->_p++;
		  if (--width == 0)
		    break;
		  if (BufferEmpty)
		    {
		      if (p == p0)
			goto input_failure;
		      break;
		    }
		}
	      n = p - p0;
	      if (n == 0)
		goto match_failure;
	      *p = 0;
	      nassigned++;
	    }
	  nread += n;
	  break;

	case CT_STRING:
	  /* like CCL, but zero-length string OK, & no NOSKIP */
	  if (width == 0)
	    width = ~0;
	  if (flags & SUPPRESS)
	    {
	      n = 0;
	      while (!isspace (*fp->_p))
		{
		  n++, fp->_r--, fp->_p++;
		  if (--width == 0)
		    break;
		  if (BufferEmpty)
		    break;
		}
	      nread += n;
	    }
	  else
	    {
	      p0 = p = va_arg (ap, char *);
	      while (!isspace (*fp->_p))
		{
		  fp->_r--;
		  *p++ = *fp->_p++;
		  if (--width == 0)
		    break;
		  if (BufferEmpty)
		    break;
		}
	      *p = 0;
	      nread += p - p0;
	      nassigned++;
	    }
	  continue;

	case CT_INT:
	  {
	  unsigned int_width_left = 0;
	  int skips = 0;
	  int_width = width;
#ifdef hardway
	  if (int_width == 0 || int_width > sizeof (buf) - 1)
#else
	  /* size_t is unsigned, hence this optimisation */
	  if (int_width - 1 > sizeof (buf) - 2)
#endif
	    {
	      int_width_left = width - (sizeof (buf) - 1);
	      int_width = sizeof (buf) - 1;
	    }
	  flags |= SIGNOK | NDIGITS | NZDIGITS | NNZDIGITS;
	  for (p = buf; int_width; int_width--)
	    {
	      c = *fp->_p;
	      /*
	       * Switch on the character; `goto ok' if we
	       * accept it as a part of number.
	       */
	      switch (c)
		{
		  /*
		   * The digit 0 is always legal, but is special.
		   * For %i conversions, if no digits (zero or nonzero)
		   * have been scanned (only signs), we will have base==0.
		   * In that case, we should set it to 8 and enable 0x
		   * prefixing. Also, if we have not scanned zero digits
		   * before this, do not turn off prefixing (someone else
		   * will turn it off if we have scanned any nonzero digits).
		   */
		case '0':
		  if (! (flags & NNZDIGITS))
		    goto ok;
		  if (base == 0)
		    {
		      base = 8;
		      flags |= PFXOK;
		    }
		  if (flags & NZDIGITS)
		    {
		      flags &= ~(SIGNOK | NZDIGITS | NDIGITS);
		      goto ok;
		    }
		  flags &= ~(SIGNOK | PFXOK | NDIGITS);
		  if (int_width_left)
		    {
		      int_width_left--;
		      int_width++;
		    }
		  ++skips;
		  goto skip;

		  /* 1 through 7 always legal */
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		  base = basefix[base];
		  flags &= ~(SIGNOK | PFXOK | NDIGITS | NNZDIGITS);
		  goto ok;

		  /* digits 8 and 9 ok iff decimal or hex */
		case '8':
		case '9':
		  base = basefix[base];
		  if (base <= 8)
		    break;	/* not legal here */
		  flags &= ~(SIGNOK | PFXOK | NDIGITS | NNZDIGITS);
		  goto ok;

		  /* letters ok iff hex */
		case 'A':
		case 'B':
		case 'C':
		case 'D':
		case 'E':
		case 'F':
		case 'a':
		case 'b':
		case 'c':
		case 'd':
		case 'e':
		case 'f':
		  /* no need to fix base here */
		  if (base <= 10)
		    break;	/* not legal here */
		  flags &= ~(SIGNOK | PFXOK | NDIGITS | NNZDIGITS);
		  goto ok;

		  /* sign ok only as first character */
		case '+':
		case '-':
		  if (flags & SIGNOK)
		    {
		      flags &= ~SIGNOK;
		      goto ok;
		    }
		  break;

		  /* x ok iff flag still set & 2nd char */
		case 'x':
		case 'X':
		  if (flags & PFXOK && p == buf + 1)
		    {
		      base = 16;/* if %i */
		      flags &= ~PFXOK;
		      /* We must reset the NZDIGITS and NDIGITS
		         flags that would have been unset by seeing
		         the zero that preceded the X or x.  */
		      flags |= NZDIGITS | NDIGITS;
		      goto ok;
		    }
		  break;
		}

	      /*
	       * If we got here, c is not a legal character
	       * for a number.  Stop accumulating digits.
	       */
	      break;
	    ok:
	      /*
	       * c is legal: store it and look at the next.
	       */
	      *p++ = c;
	    skip:
	      if (--fp->_r > 0)
		fp->_p++;
	      else
#ifndef CYGNUS_NEC
	      if (__srefill (fp))
#endif
		break;		/* EOF */
	    }
	  /*
	   * If we had only a sign, it is no good; push back the sign.
	   * If the number ends in `x', it was [sign] '0' 'x', so push back
	   * the x and treat it as [sign] '0'.
	   */
	  if (flags & NDIGITS)
	    {
	      if (p > buf)
		_CAST_VOID ungetc (*(u_char *)-- p, fp);
	      goto match_failure;
	    }
	  c = ((u_char *) p)[-1];
	  if (c == 'x' || c == 'X')
	    {
	      --p;
	      /*(void)*/ ungetc (c, fp);
	    }
	  if ((flags & SUPPRESS) == 0)
	    {
	      u_long res;

	      *p = 0;
	      res = (*ccfn) (rptr, buf, (char **) NULL, base);
	      if ((flags & POINTER) && !(flags & VECTOR))
		*(va_arg (ap, _PTR *)) = (_PTR) (unsigned _POINTER_INT) res;
	      else if (flags & SHORT)
		{
		  if (!(flags & VECTOR))
		    sp = va_arg (ap, short *);
		  else if (!looped)
		    sp = vec_buf.h;
		  *sp++ = res;
		}
	      else if (flags & LONG)
		{
		  if (!(flags & VECTOR))
		    lp = va_arg (ap, long *);
		  else if (!looped)
		    lp = vec_buf.l;
		  *lp++ = res;
		}
#ifndef _NO_LONGLONG
	      else if (flags & LONGDBL)
		{
		  u_long_long resll;
		  if (ccfn == _strtoul_r)
		    resll = _strtoull_r (rptr, buf, (char **) NULL, base);
		  else
		    resll = _strtoll_r (rptr, buf, (char **) NULL, base);
		  llp = va_arg (ap, long long*);
		  *llp = resll;
		}
#endif
	      else
		{
		  if (!(flags & VECTOR))
		    {
		      ip = va_arg (ap, int *);
		      *ip++ = res;
		    }
		  else
		    {
		      if (!looped)
			ch_dest = vec_buf.c;
		      *ch_dest++ = (char)res;
		    }
		}
	      if (!(flags & VECTOR))
		nassigned++;
	    }
	  nread += p - buf + skips;
	  break;
	  }

#ifdef FLOATING_POINT
	case CT_FLOAT:
	{
	  /* scan a floating point number as if by strtod */
	  /* This code used to assume that the number of digits is reasonable.
	     However, ANSI / ISO C makes no such stipulation; we have to get
	     exact results even when there is an unreasonable amount of
	     leading zeroes.  */
	  long leading_zeroes = 0;
	  long zeroes, exp_adjust;
	  char *exp_start = NULL;
	  unsigned fl_width = width;
	  unsigned width_left = 0;
#ifdef hardway
	  if (fl_width == 0 || fl_width > sizeof (buf) - 1)
#else
	  /* size_t is unsigned, hence this optimisation */
	  if (fl_width - 1 > sizeof (buf) - 2)
#endif
	    {
	      width_left = fl_width - (sizeof (buf) - 1);
	      fl_width = sizeof (buf) - 1;
	    }
	  flags |= SIGNOK | NDIGITS | DPTOK | EXPOK;
	  zeroes = 0;
	  exp_adjust = 0;
	  for (p = buf; fl_width; )
	    {
	      c = *fp->_p;
	      /*
	       * This code mimicks the integer conversion
	       * code, but is much simpler.
	       */
	      switch (c)
		{

		case '0':
		  if (flags & NDIGITS)
		    {
		      flags &= ~SIGNOK;
		      zeroes++;
		      if (width_left)
			{
			  width_left--;
			  fl_width++;
			}
		      goto fskip;
		    }
		  /* Fall through.  */
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		  flags &= ~(SIGNOK | NDIGITS);
		  goto fok;

		case '+':
		case '-':
		  if (flags & SIGNOK)
		    {
		      flags &= ~SIGNOK;
		      goto fok;
		    }
		  break;
		case '.':
		  if (flags & DPTOK)
		    {
		      flags &= ~(SIGNOK | DPTOK);
		      leading_zeroes = zeroes;
		      goto fok;
		    }
		  break;
		case 'e':
		case 'E':
		  /* no exponent without some digits */
		  if ((flags & (NDIGITS | EXPOK)) == EXPOK
		      || ((flags & EXPOK) && zeroes))
		    {
		      if (! (flags & DPTOK))
			{
			  exp_adjust = zeroes - leading_zeroes;
			  exp_start = p;
			}
		      flags =
			(flags & ~(EXPOK | DPTOK)) |
			SIGNOK | NDIGITS;
		      zeroes = 0;
		      goto fok;
		    }
		  break;
		}
	      break;
	    fok:
	      *p++ = c;
	    fskip:
	      fl_width--;
              ++nread;
	      if (--fp->_r > 0)
		fp->_p++;
	      else
#ifndef CYGNUS_NEC
	      if (__srefill (fp))
#endif
		break;		/* EOF */
	    }
	  if (zeroes)
	    flags &= ~NDIGITS;
	  /*
	   * If no digits, might be missing exponent digits
	   * (just give back the exponent) or might be missing
	   * regular digits, but had sign and/or decimal point.
	   */
	  if (flags & NDIGITS)
	    {
	      if (flags & EXPOK)
		{
		  /* no digits at all */
		  while (p > buf)
                    {
		      ungetc (*(u_char *)-- p, fp);
                      --nread;
                    }
		  goto match_failure;
		}
	      /* just a bad exponent (e and maybe sign) */
	      c = *(u_char *)-- p;
              --nread;
	      if (c != 'e' && c != 'E')
		{
		  _CAST_VOID ungetc (c, fp);	/* sign */
		  c = *(u_char *)-- p;
                  --nread;
		}
	      _CAST_VOID ungetc (c, fp);
	    }
	  if ((flags & SUPPRESS) == 0)
	    {
#ifdef _NO_LONGDBL
	      double res;
#else  /* !_NO_LONG_DBL */
	      long double res;
#endif /* !_NO_LONG_DBL */
	      long new_exp = 0;

	      *p = 0;
	      if ((flags & (DPTOK | EXPOK)) == EXPOK)
		{
		  exp_adjust = zeroes - leading_zeroes;
		  new_exp = -exp_adjust;
		  exp_start = p;
		}
	      else if (exp_adjust)
                new_exp = _strtol_r (rptr, (exp_start + 1), NULL, 10) - exp_adjust;
	      if (exp_adjust)
		{

		  /* If there might not be enough space for the new exponent,
		     truncate some trailing digits to make room.  */
		  if (exp_start >= buf + sizeof (buf) - MAX_LONG_LEN)
		    exp_start = buf + sizeof (buf) - MAX_LONG_LEN - 1;
                 sprintf (exp_start, "e%ld", new_exp);
		}
#ifdef __SPE__
	      if (flags & FIXEDPOINT)
		{
		  __uint64_t ufix64;
		  if (flags & SIGNED)
		    ufix64 = (__uint64_t)_strtosfix64_r (rptr, buf, NULL);
                  else
		    ufix64 = _strtoufix64_r (rptr, buf, NULL);
		  if (flags & SHORT)
		    {
		      __uint16_t *sp = va_arg (ap, __uint16_t *);
		      *sp = (__uint16_t)(ufix64 >> 48);
		    }
		  else if (flags & LONG)
		    {
		      __uint64_t *llp = va_arg (ap, __uint64_t *);
		      *llp = ufix64;
		    }
		  else
		    {
		      __uint32_t *lp = va_arg (ap, __uint32_t *);
		      *lp = (__uint32_t)(ufix64 >> 32);
		    }
		  nassigned++;
		  break;
		}
	      
#endif /* __SPE__ */
#ifdef _NO_LONGDBL
	      res = _strtod_r (rptr, buf, NULL);
#else  /* !_NO_LONGDBL */
	      res = _strtold (buf, NULL);
#endif /* !_NO_LONGDBL */
	      if (flags & LONG)
		{
		  dp = va_arg (ap, double *);
		  *dp = res;
		}
	      else if (flags & LONGDBL)
		{
		  ldp = va_arg (ap, _LONG_DOUBLE *);
		  *ldp = res;
		}
	      else
		{
		  if (!(flags & VECTOR))
		    flp = va_arg (ap, float *);
		  else if (!looped)
		    flp = vec_buf.f;
		  *flp++ = res;
		}
	      if (!(flags & VECTOR))
		nassigned++;
	    }
	  break;
	}
#endif /* FLOATING_POINT */
	}
      if (vec_read_count-- > 1)
	{
	  looped = 1;
	  goto process;
	}
      if (flags & VECTOR)
	{
	  int i;
	  unsigned long *vp = va_arg (ap, unsigned long *);
	  for (i = 0; i < 4; ++i)
	    *vp++ = vec_buf.l[i];
	  nassigned++;
	}
    }
input_failure:
  return nassigned ? nassigned : -1;
match_failure:
  return nassigned;
}

