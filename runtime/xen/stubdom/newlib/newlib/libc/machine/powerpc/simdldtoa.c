
 /* Extended precision arithmetic functions for long double I/O.
  * This program has been placed in the public domain.
  */

#ifdef __SPE__

#include <_ansi.h>
#include <reent.h>
#include <string.h>
#include <stdlib.h>
#include "mprec.h"
#include "fix64.h"

/* These are the externally visible entries. */
/* linux name:  long double _IO_strtold (char *, char **); */
void _simdstrtold (char *, char **, LONG_DOUBLE_UNION *);
char * _simdldtoa_r (struct _reent *, LONG_DOUBLE_UNION *, int, int, int *, int *, char **);

 /* Number of 16 bit words in external x type format */
 #define NE 10

 /* Number of 16 bit words in internal format */
 #define NI (NE+3)

 /* Array offset to exponent */
 #define E 1

 /* Array offset to high guard word */
 #define M 2

 /* Number of bits of precision */
 #define NBITS ((NI-4)*16)

 /* Maximum number of decimal digits in ASCII conversion
  * = NBITS*log10(2)
  */
 #define NDEC (NBITS*8/27)

 /* The exponent of 1.0 */
 #define EXONE (0x3fff)

 /* Maximum exponent digits - base 10 */
 #define MAX_EXP_DIGITS 5

/* Control structure for long doublue conversion including rounding precision values.
 * rndprc can be set to 80 (if NE=6), 64, 56, 53, or 24 bits.
 */
typedef struct
{
  int rlast;
  int rndprc;
  int rw;
  int re;
  int outexpon;
  unsigned short rmsk;
  unsigned short rmbit;
  unsigned short rebit;
  unsigned short rbit[NI];
  unsigned short equot[NI];
} LDPARMS;

static void esub(short unsigned int *a, short unsigned int *b, short unsigned int *c, LDPARMS *ldp);
static void emul(short unsigned int *a, short unsigned int *b, short unsigned int *c, LDPARMS *ldp);
static void ediv(short unsigned int *a, short unsigned int *b, short unsigned int *c, LDPARMS *ldp);
static int ecmp(short unsigned int *a, short unsigned int *b);
static int enormlz(short unsigned int *x);
static int eshift(short unsigned int *x, int sc);
static void eshup1(register short unsigned int *x);
static void eshup8(register short unsigned int *x);
static void eshup6(register short unsigned int *x);
static void eshdn1(register short unsigned int *x);
static void eshdn8(register short unsigned int *x);
static void eshdn6(register short unsigned int *x);
static void eneg(short unsigned int *x);
static void emov(register short unsigned int *a, register short unsigned int *b);
static void eclear(register short unsigned int *x);
static void einfin(register short unsigned int *x, register LDPARMS *ldp);
static void efloor(short unsigned int *x, short unsigned int *y, LDPARMS *ldp);
static void etoasc(short unsigned int *x, char *string, int ndigs, int outformat, LDPARMS *ldp);

#if SIMD_LDBL_MANT_DIG == 24
static void e24toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp);
#elif SIMD_LDBL_MANT_DIG == 53
static void e53toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp);
#elif SIMD_LDBL_MANT_DIG == 64
static void e64toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp);
#else
static void e113toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp);
#endif

/*							econst.c	*/
/*  e type constants used by high precision check routines */

#if NE == 10
/* 0.0 */
static unsigned short ezero[NE] =
 {0x0000, 0x0000, 0x0000, 0x0000,
  0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000,};

/* 1.0E0 */
static unsigned short eone[NE] =
 {0x0000, 0x0000, 0x0000, 0x0000,
  0x0000, 0x0000, 0x0000, 0x0000, 0x8000, 0x3fff,};

#else

/* 0.0 */
static unsigned short ezero[NE] = {
0, 0000000,0000000,0000000,0000000,0000000,};
/* 1.0E0 */
static unsigned short eone[NE] = {
0, 0000000,0000000,0000000,0100000,0x3fff,};

#endif

/* Debugging routine for displaying errors */
#ifdef DEBUG
/* Notice: the order of appearance of the following
 * messages is bound to the error codes defined
 * in mconf.h.
 */
static char *ermsg[7] = {
"unknown",      /* error code 0 */
"domain",       /* error code 1 */
"singularity",  /* et seq.      */
"overflow",
"underflow",
"total loss of precision",
"partial loss of precision"
};
#define mtherr(name, code) printf( "\n%s %s error\n", name, ermsg[code] );
#else
#define mtherr(name, code)
#endif

/*							ieee.c
 *
 *    Extended precision IEEE binary floating point arithmetic routines
 *
 * Numbers are stored in C language as arrays of 16-bit unsigned
 * short integers.  The arguments of the routines are pointers to
 * the arrays.
 *
 *
 * External e type data structure, simulates Intel 8087 chip
 * temporary real format but possibly with a larger significand:
 *
 *	NE-1 significand words	(least significant word first,
 *				 most significant bit is normally set)
 *	exponent		(value = EXONE for 1.0,
 *				top bit is the sign)
 *
 *
 * Internal data structure of a number (a "word" is 16 bits):
 *
 * ei[0]	sign word	(0 for positive, 0xffff for negative)
 * ei[1]	biased exponent	(value = EXONE for the number 1.0)
 * ei[2]	high guard word	(always zero after normalization)
 * ei[3]
 * to ei[NI-2]	significand	(NI-4 significand words,
 *				 most significant word first,
 *				 most significant bit is set)
 * ei[NI-1]	low guard word	(0x8000 bit is rounding place)
 *
 *
 *
 *		Routines for external format numbers
 *
 *	asctoe( string, e )	ASCII string to extended double e type
 *	asctoe64( string, &d )	ASCII string to long double
 *	asctoe53( string, &d )	ASCII string to double
 *	asctoe24( string, &f )	ASCII string to single
 *	asctoeg( string, e, prec, ldp ) ASCII string to specified precision
 *	e24toe( &f, e, ldp )	IEEE single precision to e type
 *	e53toe( &d, e, ldp )	IEEE double precision to e type
 *	e64toe( &d, e, ldp )	IEEE long double precision to e type
 *	e113toe( &d, e, ldp )	IEEE long double precision to e type
 *	eabs(e)			absolute value
 *	eadd( a, b, c )		c = b + a
 *	eclear(e)		e = 0
 *	ecmp (a, b)		Returns 1 if a > b, 0 if a == b,
 *				-1 if a < b, -2 if either a or b is a NaN.
 *	ediv( a, b, c, ldp )	c = b / a
 *	efloor( a, b, ldp )	truncate to integer, toward -infinity
 *	efrexp( a, exp, s )	extract exponent and significand
 *	eifrac( e, &l, frac )   e to long integer and e type fraction
 *	euifrac( e, &l, frac )  e to unsigned long integer and e type fraction
 *	einfin( e, ldp )	set e to infinity, leaving its sign alone
 *	eldexp( a, n, b )	multiply by 2**n
 *	emov( a, b )		b = a
 *	emul( a, b, c, ldp )	c = b * a
 *	eneg(e)			e = -e
 *	eround( a, b )		b = nearest integer value to a
 *	esub( a, b, c, ldp )	c = b - a
 *	e24toasc( &f, str, n )	single to ASCII string, n digits after decimal
 *	e53toasc( &d, str, n )	double to ASCII string, n digits after decimal
 *	e64toasc( &d, str, n )	long double to ASCII string
 *	etoasc(e,str,n,fmt,ldp)e to ASCII string, n digits after decimal
 *	etoe24( e, &f )		convert e type to IEEE single precision
 *	etoe53( e, &d )		convert e type to IEEE double precision
 *	etoe64( e, &d )		convert e type to IEEE long double precision
 *	ltoe( &l, e )		long (32 bit) integer to e type
 *	ultoe( &l, e )		unsigned long (32 bit) integer to e type
 *      eisneg( e )             1 if sign bit of e != 0, else 0
 *      eisinf( e )             1 if e has maximum exponent (non-IEEE)
 *				or is infinite (IEEE)
 *      eisnan( e )             1 if e is a NaN
 *	esqrt( a, b )		b = square root of a
 *
 *
 *		Routines for internal format numbers
 *
 *	eaddm( ai, bi )		add significands, bi = bi + ai
 *	ecleaz(ei)		ei = 0
 *	ecleazs(ei)		set ei = 0 but leave its sign alone
 *	ecmpm( ai, bi )		compare significands, return 1, 0, or -1
 *	edivm( ai, bi, ldp )	divide  significands, bi = bi / ai
 *	emdnorm(ai,l,s,exp,ldp) normalize and round off
 *	emovi( a, ai )		convert external a to internal ai
 *	emovo( ai, a, ldp )	convert internal ai to external a
 *	emovz( ai, bi )		bi = ai, low guard word of bi = 0
 *	emulm( ai, bi, ldp )	multiply significands, bi = bi * ai
 *	enormlz(ei)		left-justify the significand
 *	eshdn1( ai )		shift significand and guards down 1 bit
 *	eshdn8( ai )		shift down 8 bits
 *	eshdn6( ai )		shift down 16 bits
 *	eshift( ai, n )		shift ai n bits up (or down if n < 0)
 *	eshup1( ai )		shift significand and guards up 1 bit
 *	eshup8( ai )		shift up 8 bits
 *	eshup6( ai )		shift up 16 bits
 *	esubm( ai, bi )		subtract significands, bi = bi - ai
 *
 *
 * The result is always normalized and rounded to NI-4 word precision
 * after each arithmetic operation.
 *
 * Exception flags are NOT fully supported.
 *
 * Define INFINITY in mconf.h for support of infinity; otherwise a
 * saturation arithmetic is implemented.
 *
 * Define NANS for support of Not-a-Number items; otherwise the
 * arithmetic will never produce a NaN output, and might be confused
 * by a NaN input.
 * If NaN's are supported, the output of ecmp(a,b) is -2 if
 * either a or b is a NaN. This means asking if(ecmp(a,b) < 0)
 * may not be legitimate. Use if(ecmp(a,b) == -1) for less-than
 * if in doubt.
 * Signaling NaN's are NOT supported; they are treated the same
 * as quiet NaN's.
 *
 * Denormals are always supported here where appropriate (e.g., not
 * for conversion to DEC numbers).
 */

/*
 * Revision history:
 *
 *  5 Jan 84	PDP-11 assembly language version
 *  6 Dec 86	C language version
 * 30 Aug 88	100 digit version, improved rounding
 * 15 May 92    80-bit long double support
 * 22 Nov 00    Revised to fit into newlib by Jeff Johnston <jjohnstn@redhat.com>
 *
 * Author:  S. L. Moshier.
 *
 * Copyright (c) 1984,2000 S.L. Moshier
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 *
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR,  THE AUTHOR MAKES NO REPRESENTATION
 * OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY OF THIS
 * SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 *
 */

#include <stdio.h>
/* #include "\usr\include\stdio.h" */
/*#include "ehead.h"*/
/*#include "mconf.h"*/
/*							mconf.h
 *
 *	Common include file for math routines
 *
 *
 *
 * SYNOPSIS:
 *
 * #include "mconf.h"
 *
 *
 *
 * DESCRIPTION:
 *
 * This file contains definitions for error codes that are
 * passed to the common error handling routine mtherr()
 * (which see).
 *
 * The file also includes a conditional assembly definition
 * for the type of computer arithmetic (IEEE, DEC, Motorola
 * IEEE, or UNKnown).
 *
 * For Digital Equipment PDP-11 and VAX computers, certain
 * IBM systems, and others that use numbers with a 56-bit
 * significand, the symbol DEC should be defined.  In this
 * mode, most floating point constants are given as arrays
 * of octal integers to eliminate decimal to binary conversion
 * errors that might be introduced by the compiler.
 *
 * For computers, such as IBM PC, that follow the IEEE 
 * Standard for Binary Floating Point Arithmetic (ANSI/IEEE
 * Std 754-1985), the symbol IBMPC should be defined.  These
 * numbers have 53-bit significands.  In this mode, constants
 * are provided as arrays of hexadecimal 16 bit integers.
 *
 * To accommodate other types of computer arithmetic, all
 * constants are also provided in a normal decimal radix
 * which one can hope are correctly converted to a suitable
 * format by the available C language compiler.  To invoke
 * this mode, the symbol UNK is defined.
 *
 * An important difference among these modes is a predefined
 * set of machine arithmetic constants for each.  The numbers
 * MACHEP (the machine roundoff error), MAXNUM (largest number
 * represented), and several other parameters are preset by
 * the configuration symbol.  Check the file const.c to
 * ensure that these values are correct for your computer.
 *
 * For ANSI C compatibility, define ANSIC equal to 1.  Currently
 * this affects only the atan2() function and others that use it.
 */

/* Constant definitions for math error conditions
 */

#define DOMAIN		1	/* argument domain error */
#define SING		2	/* argument singularity */
#define OVERFLOW	3	/* overflow range error */
#define UNDERFLOW	4	/* underflow range error */
#define TLOSS		5	/* total loss of precision */
#define PLOSS		6	/* partial loss of precision */

#define EDOM		33
#define ERANGE		34

typedef struct
	{
	double r;
	double i;
	}cmplx;

/* Type of computer arithmetic */

#ifndef DEC
#ifdef __IEEE_LITTLE_ENDIAN
#define IBMPC 1
#else  /* !__IEEE_LITTLE_ENDIAN */
#define MIEEE 1
#endif /* !__IEEE_LITTLE_ENDIAN */
#endif /* !DEC */

/* Define 1 for ANSI C atan2() function
 * See atan.c and clog.c.
 */
#define ANSIC 1

/*define VOLATILE volatile*/
#define VOLATILE 

#define NANS
#define INFINITY

/* NaN's require infinity support. */
#ifdef NANS
#ifndef INFINITY
#define INFINITY
#endif
#endif

/* This handles 64-bit long ints. */
#define LONGBITS (8 * sizeof(long))


static void eaddm(short unsigned int *x, short unsigned int *y);
static void esubm(short unsigned int *x, short unsigned int *y);
static void emdnorm(short unsigned int *s, int lost, int subflg, long int exp, int rcntrl, LDPARMS *ldp);
static int  asctoeg(char *ss, short unsigned int *y, int oprec, LDPARMS *ldp);
static void enan(short unsigned int *nan, int size);
#if SIMD_LDBL_MANT_DIG == 24
static void toe24(short unsigned int *x, short unsigned int *y);
#elif SIMD_LDBL_MANT_DIG == 53
static void toe53(short unsigned int *x, short unsigned int *y);
#elif SIMD_LDBL_MANT_DIG == 64
static void toe64(short unsigned int *a, short unsigned int *b);
#else
static void toe113(short unsigned int *a, short unsigned int *b);
#endif
static void eiremain(short unsigned int *den, short unsigned int *num, LDPARMS *ldp);
static int ecmpm(register short unsigned int *a, register short unsigned int *b);
static int edivm(short unsigned int *den, short unsigned int *num, LDPARMS *ldp);
static int emulm(short unsigned int *a, short unsigned int *b, LDPARMS *ldp);
static int eisneg(short unsigned int *x);
static int eisinf(short unsigned int *x);
static void emovi(short unsigned int *a, short unsigned int *b);
static void emovo(short unsigned int *a, short unsigned int *b, LDPARMS *ldp);
static void emovz(register short unsigned int *a, register short unsigned int *b);
static void ecleaz(register short unsigned int *xi);
static void eadd1(short unsigned int *a, short unsigned int *b, short unsigned int *c, int subflg, LDPARMS *ldp);
static int eisnan(short unsigned int *x);
static int eiisnan(short unsigned int *x);

#ifdef DEC
static void etodec(), todec(), dectoe();
#endif

/*
; Clear out entire external format number.
;
; unsigned short x[];
; eclear( x );
*/

static void eclear(register short unsigned int *x)
{
register int i;

for( i=0; i<NE; i++ )
	*x++ = 0;
}



/* Move external format number from a to b.
 *
 * emov( a, b );
 */

static void emov(register short unsigned int *a, register short unsigned int *b)
{
register int i;

for( i=0; i<NE; i++ )
	*b++ = *a++;
}


/*
;	Negate external format number
;
;	unsigned short x[NE];
;	eneg( x );
*/

static void eneg(short unsigned int *x)
{

#ifdef NANS
if( eisnan(x) )
	return;
#endif
x[NE-1] ^= 0x8000; /* Toggle the sign bit */
}



/* Return 1 if external format number is negative,
 * else return zero.
 */
static int eisneg(short unsigned int *x)
{

#ifdef NANS
if( eisnan(x) )
	return( 0 );
#endif
if( x[NE-1] & 0x8000 )
	return( 1 );
else
	return( 0 );
}


/* Return 1 if external format number has maximum possible exponent,
 * else return zero.
 */
static int eisinf(short unsigned int *x)
{

if( (x[NE-1] & 0x7fff) == 0x7fff )
	{
#ifdef NANS
	if( eisnan(x) )
		return( 0 );
#endif
	return( 1 );
	}
else
	return( 0 );
}

/* Check if e-type number is not a number.
 */
static int eisnan(short unsigned int *x)
{

#ifdef NANS
int i;
/* NaN has maximum exponent */
if( (x[NE-1] & 0x7fff) != 0x7fff )
	return (0);
/* ... and non-zero significand field. */
for( i=0; i<NE-1; i++ )
	{
	if( *x++ != 0 )
		return (1);
	}
#endif
return (0);
}

/*
; Fill entire number, including exponent and significand, with
; largest possible number.  These programs implement a saturation
; value that is an ordinary, legal number.  A special value
; "infinity" may also be implemented; this would require tests
; for that value and implementation of special rules for arithmetic
; operations involving inifinity.
*/

static void einfin(register short unsigned int *x, register LDPARMS *ldp)
{
register int i;

#ifdef INFINITY
for( i=0; i<NE-1; i++ )
	*x++ = 0;
*x |= 32767;
ldp = ldp;
#else
for( i=0; i<NE-1; i++ )
	*x++ = 0xffff;
*x |= 32766;
if( ldp->rndprc < NBITS )
	{
	if (ldp->rndprc == 113)
		{
		*(x - 9) = 0;
		*(x - 8) = 0;
		}
	if( ldp->rndprc == 64 )
		{
		*(x-5) = 0;
		}
	if( ldp->rndprc == 53 )
		{
		*(x-4) = 0xf800;
		}
	else
		{
		*(x-4) = 0;
		*(x-3) = 0;
		*(x-2) = 0xff00;
		}
	}
#endif
}

/* Move in external format number,
 * converting it to internal format.
 */
static void emovi(short unsigned int *a, short unsigned int *b)
{
register unsigned short *p, *q;
int i;

q = b;
p = a + (NE-1);	/* point to last word of external number */
/* get the sign bit */
if( *p & 0x8000 )
	*q++ = 0xffff;
else
	*q++ = 0;
/* get the exponent */
*q = *p--;
*q++ &= 0x7fff;	/* delete the sign bit */
#ifdef INFINITY
if( (*(q-1) & 0x7fff) == 0x7fff )
	{
#ifdef NANS
	if( eisnan(a) )
		{
		*q++ = 0;
		for( i=3; i<NI; i++ )
			*q++ = *p--;
		return;
		}
#endif
	for( i=2; i<NI; i++ )
		*q++ = 0;
	return;
	}
#endif
/* clear high guard word */
*q++ = 0;
/* move in the significand */
for( i=0; i<NE-1; i++ )
	*q++ = *p--;
/* clear low guard word */
*q = 0;
}


/* Move internal format number out,
 * converting it to external format.
 */
static void emovo(short unsigned int *a, short unsigned int *b, LDPARMS *ldp)
{
register unsigned short *p, *q;
unsigned short i;

p = a;
q = b + (NE-1); /* point to output exponent */
/* combine sign and exponent */
i = *p++;
if( i )
	*q-- = *p++ | 0x8000;
else
	*q-- = *p++;
#ifdef INFINITY
if( *(p-1) == 0x7fff )
	{
#ifdef NANS
	if( eiisnan(a) )
		{
		enan( b, NBITS );
		return;
		}
#endif
	einfin(b, ldp);
	return;
	}
#endif
/* skip over guard word */
++p;
/* move the significand */
for( i=0; i<NE-1; i++ )
	*q-- = *p++;
}


/* Clear out internal format number.
 */

static void ecleaz(register short unsigned int *xi)
{
register int i;

for( i=0; i<NI; i++ )
	*xi++ = 0;
}

/* same, but don't touch the sign. */

static void ecleazs(register short unsigned int *xi)
{
register int i;

++xi;
for(i=0; i<NI-1; i++)
	*xi++ = 0;
}




/* Move internal format number from a to b.
 */
static void emovz(register short unsigned int *a, register short unsigned int *b)
{
register int i;

for( i=0; i<NI-1; i++ )
	*b++ = *a++;
/* clear low guard word */
*b = 0;
}

/* Return nonzero if internal format number is a NaN.
 */

static int eiisnan (short unsigned int *x)
{
int i;

if( (x[E] & 0x7fff) == 0x7fff )
	{
	for( i=M+1; i<NI; i++ )
		{
		if( x[i] != 0 )
			return(1);
		}
	}
return(0);
}

#if SIMD_LDBL_MANT_DIG == 64

/* Return nonzero if internal format number is infinite. */
static int 
eiisinf (x)
     unsigned short x[];
{

#ifdef NANS
  if (eiisnan (x))
    return (0);
#endif
  if ((x[E] & 0x7fff) == 0x7fff)
    return (1);
  return (0);
}
#endif /* SIMD_LDBL_MANT_DIG == 64 */

/*
;	Compare significands of numbers in internal format.
;	Guard words are included in the comparison.
;
;	unsigned short a[NI], b[NI];
;	cmpm( a, b );
;
;	for the significands:
;	returns	+1 if a > b
;		 0 if a == b
;		-1 if a < b
*/
static int ecmpm(register short unsigned int *a, register short unsigned int *b)
{
int i;

a += M; /* skip up to significand area */
b += M;
for( i=M; i<NI; i++ )
	{
	if( *a++ != *b++ )
		goto difrnt;
	}
return(0);

difrnt:
if( *(--a) > *(--b) )
	return(1);
else
	return(-1);
}


/*
;	Shift significand down by 1 bit
*/

static void eshdn1(register short unsigned int *x)
{
register unsigned short bits;
int i;

x += M;	/* point to significand area */

bits = 0;
for( i=M; i<NI; i++ )
	{
	if( *x & 1 )
		bits |= 1;
	*x >>= 1;
	if( bits & 2 )
		*x |= 0x8000;
	bits <<= 1;
	++x;
	}	
}



/*
;	Shift significand up by 1 bit
*/

static void eshup1(register short unsigned int *x)
{
register unsigned short bits;
int i;

x += NI-1;
bits = 0;

for( i=M; i<NI; i++ )
	{
	if( *x & 0x8000 )
		bits |= 1;
	*x <<= 1;
	if( bits & 2 )
		*x |= 1;
	bits <<= 1;
	--x;
	}
}



/*
;	Shift significand down by 8 bits
*/

static void eshdn8(register short unsigned int *x)
{
register unsigned short newbyt, oldbyt;
int i;

x += M;
oldbyt = 0;
for( i=M; i<NI; i++ )
	{
	newbyt = *x << 8;
	*x >>= 8;
	*x |= oldbyt;
	oldbyt = newbyt;
	++x;
	}
}

/*
;	Shift significand up by 8 bits
*/

static void eshup8(register short unsigned int *x)
{
int i;
register unsigned short newbyt, oldbyt;

x += NI-1;
oldbyt = 0;

for( i=M; i<NI; i++ )
	{
	newbyt = *x >> 8;
	*x <<= 8;
	*x |= oldbyt;
	oldbyt = newbyt;
	--x;
	}
}

/*
;	Shift significand up by 16 bits
*/

static void eshup6(register short unsigned int *x)
{
int i;
register unsigned short *p;

p = x + M;
x += M + 1;

for( i=M; i<NI-1; i++ )
	*p++ = *x++;

*p = 0;
}

/*
;	Shift significand down by 16 bits
*/

static void eshdn6(register short unsigned int *x)
{
int i;
register unsigned short *p;

x += NI-1;
p = x + 1;

for( i=M; i<NI-1; i++ )
	*(--p) = *(--x);

*(--p) = 0;
}

/*
;	Add significands
;	x + y replaces y
*/

static void eaddm(short unsigned int *x, short unsigned int *y)
{
register unsigned long a;
int i;
unsigned int carry;

x += NI-1;
y += NI-1;
carry = 0;
for( i=M; i<NI; i++ )
	{
	a = (unsigned long )(*x) + (unsigned long )(*y) + carry;
	if( a & 0x10000 )
		carry = 1;
	else
		carry = 0;
	*y = (unsigned short )a;
	--x;
	--y;
	}
}

/*
;	Subtract significands
;	y - x replaces y
*/

static void esubm(short unsigned int *x, short unsigned int *y)
{
unsigned long a;
int i;
unsigned int carry;

x += NI-1;
y += NI-1;
carry = 0;
for( i=M; i<NI; i++ )
	{
	a = (unsigned long )(*y) - (unsigned long )(*x) - carry;
	if( a & 0x10000 )
		carry = 1;
	else
		carry = 0;
	*y = (unsigned short )a;
	--x;
	--y;
	}
}


/* Divide significands */


/* Multiply significand of e-type number b
by 16-bit quantity a, e-type result to c. */

static void m16m(short unsigned int a, short unsigned int *b, short unsigned int *c)
{
register unsigned short *pp;
register unsigned long carry;
unsigned short *ps;
unsigned short p[NI];
unsigned long aa, m;
int i;

aa = a;
pp = &p[NI-2];
*pp++ = 0;
*pp = 0;
ps = &b[NI-1];

for( i=M+1; i<NI; i++ )
	{
	if( *ps == 0 )
		{
		--ps;
		--pp;
		*(pp-1) = 0;
		}
	else
		{
		m = (unsigned long) aa * *ps--;
		carry = (m & 0xffff) + *pp;
		*pp-- = (unsigned short )carry;
		carry = (carry >> 16) + (m >> 16) + *pp;
		*pp = (unsigned short )carry;
		*(pp-1) = carry >> 16;
		}
	}
for( i=M; i<NI; i++ )
	c[i] = p[i];
}


/* Divide significands. Neither the numerator nor the denominator
is permitted to have its high guard word nonzero.  */


static int edivm(short unsigned int *den, short unsigned int *num, LDPARMS *ldp)
{
int i;
register unsigned short *p;
unsigned long tnum;
unsigned short j, tdenm, tquot;
unsigned short tprod[NI+1];
unsigned short *equot = ldp->equot;

p = &equot[0];
*p++ = num[0];
*p++ = num[1];

for( i=M; i<NI; i++ )
	{
	*p++ = 0;
	}
eshdn1( num );
tdenm = den[M+1];
for( i=M; i<NI; i++ )
	{
	/* Find trial quotient digit (the radix is 65536). */
	tnum = (((unsigned long) num[M]) << 16) + num[M+1];

	/* Do not execute the divide instruction if it will overflow. */
        if( (tdenm * 0xffffUL) < tnum )
		tquot = 0xffff;
	else
		tquot = tnum / tdenm;

		/* Prove that the divide worked. */
/*
	tcheck = (unsigned long )tquot * tdenm;
	if( tnum - tcheck > tdenm )
		tquot = 0xffff;
*/
	/* Multiply denominator by trial quotient digit. */
	m16m( tquot, den, tprod );
	/* The quotient digit may have been overestimated. */
	if( ecmpm( tprod, num ) > 0 )
		{
		tquot -= 1;
		esubm( den, tprod );
		if( ecmpm( tprod, num ) > 0 )
			{
			tquot -= 1;
			esubm( den, tprod );
			}
		}
/*
	if( ecmpm( tprod, num ) > 0 )
		{
		eshow( "tprod", tprod );
		eshow( "num  ", num );
		printf( "tnum = %08lx, tden = %04x, tquot = %04x\n",
			 tnum, den[M+1], tquot );
		}
*/
	esubm( tprod, num );
/*
	if( ecmpm( num, den ) >= 0 )
		{
		eshow( "num  ", num );
		eshow( "den  ", den );
		printf( "tnum = %08lx, tden = %04x, tquot = %04x\n",
			 tnum, den[M+1], tquot );
		}
*/
	equot[i] = tquot;
	eshup6(num);
	}
/* test for nonzero remainder after roundoff bit */
p = &num[M];
j = 0;
for( i=M; i<NI; i++ )
	{
	j |= *p++;
	}
if( j )
	j = 1;

for( i=0; i<NI; i++ )
	num[i] = equot[i];

return( (int )j );
}



/* Multiply significands */
static int emulm(short unsigned int *a, short unsigned int *b, LDPARMS *ldp) 
{
unsigned short *p, *q;
unsigned short pprod[NI];
unsigned short j;
int i;
unsigned short *equot = ldp->equot;

equot[0] = b[0];
equot[1] = b[1];
for( i=M; i<NI; i++ )
	equot[i] = 0;

j = 0;
p = &a[NI-1];
q = &equot[NI-1];
for( i=M+1; i<NI; i++ )
	{
	if( *p == 0 )
		{
		--p;
		}
	else
		{
		m16m( *p--, b, pprod );
		eaddm(pprod, equot);
		}
	j |= *q;
	eshdn6(equot);
	}

for( i=0; i<NI; i++ )
	b[i] = equot[i];

/* return flag for lost nonzero bits */
return( (int)j );
}


/*
static void eshow(str, x)
char *str;
unsigned short *x;
{
int i;

printf( "%s ", str );
for( i=0; i<NI; i++ )
	printf( "%04x ", *x++ );
printf( "\n" );
}
*/


/*
 * Normalize and round off.
 *
 * The internal format number to be rounded is "s".
 * Input "lost" indicates whether the number is exact.
 * This is the so-called sticky bit.
 *
 * Input "subflg" indicates whether the number was obtained
 * by a subtraction operation.  In that case if lost is nonzero
 * then the number is slightly smaller than indicated.
 *
 * Input "exp" is the biased exponent, which may be negative.
 * the exponent field of "s" is ignored but is replaced by
 * "exp" as adjusted by normalization and rounding.
 *
 * Input "rcntrl" is the rounding control.
 */


static void emdnorm(short unsigned int *s, int lost, int subflg, long int exp, int rcntrl, LDPARMS *ldp)
{
int i, j;
unsigned short r;

/* Normalize */
j = enormlz( s );

/* a blank significand could mean either zero or infinity. */
#ifndef INFINITY
if( j > NBITS )
	{
	ecleazs( s );
	return;
	}
#endif
exp -= j;
#ifndef INFINITY
if( exp >= 32767L )
	goto overf;
#else
if( (j > NBITS) && (exp < 32767L) )
	{
	ecleazs( s );
	return;
	}
#endif
if( exp < 0L )
	{
	if( exp > (long )(-NBITS-1) )
		{
		j = (int )exp;
		i = eshift( s, j );
		if( i )
			lost = 1;
		}
	else
		{
		ecleazs( s );
		return;
		}
	}
/* Round off, unless told not to by rcntrl. */
if( rcntrl == 0 )
	goto mdfin;
/* Set up rounding parameters if the control register changed. */
if( ldp->rndprc != ldp->rlast )
	{
	ecleaz( ldp->rbit );
	switch( ldp->rndprc )
		{
		default:
		case NBITS:
			ldp->rw = NI-1; /* low guard word */
			ldp->rmsk = 0xffff;
			ldp->rmbit = 0x8000;
			ldp->rebit = 1;
			ldp->re = ldp->rw - 1;
			break;
		case 113:
			ldp->rw = 10;
			ldp->rmsk = 0x7fff;
			ldp->rmbit = 0x4000;
			ldp->rebit = 0x8000;
			ldp->re = ldp->rw;
			break;
		case 64:
			ldp->rw = 7;
			ldp->rmsk = 0xffff;
			ldp->rmbit = 0x8000;
			ldp->rebit = 1;
			ldp->re = ldp->rw-1;
			break;
/* For DEC arithmetic */
		case 56:
			ldp->rw = 6;
			ldp->rmsk = 0xff;
			ldp->rmbit = 0x80;
			ldp->rebit = 0x100;
			ldp->re = ldp->rw;
			break;
		case 53:
			ldp->rw = 6;
			ldp->rmsk = 0x7ff;
			ldp->rmbit = 0x0400;
			ldp->rebit = 0x800;
			ldp->re = ldp->rw;
			break;
		case 24:
			ldp->rw = 4;
			ldp->rmsk = 0xff;
			ldp->rmbit = 0x80;
			ldp->rebit = 0x100;
			ldp->re = ldp->rw;
			break;
		}
	ldp->rbit[ldp->re] = ldp->rebit;
	ldp->rlast = ldp->rndprc;
	}

/* Shift down 1 temporarily if the data structure has an implied
 * most significant bit and the number is denormal.
 * For rndprc = 64 or NBITS, there is no implied bit.
 * But Intel long double denormals lose one bit of significance even so.
 */
#if IBMPC
if( (exp <= 0) && (ldp->rndprc != NBITS) )
#else
if( (exp <= 0) && (ldp->rndprc != 64) && (ldp->rndprc != NBITS) )
#endif
	{
	lost |= s[NI-1] & 1;
	eshdn1(s);
	}
/* Clear out all bits below the rounding bit,
 * remembering in r if any were nonzero.
 */
r = s[ldp->rw] & ldp->rmsk;
if( ldp->rndprc < NBITS )
	{
	i = ldp->rw + 1;
	while( i < NI )
		{
		if( s[i] )
			r |= 1;
		s[i] = 0;
		++i;
		}
	}
s[ldp->rw] &= ~ldp->rmsk;
if( (r & ldp->rmbit) != 0 )
	{
	if( r == ldp->rmbit )
		{
		if( lost == 0 )
			{ /* round to even */
			if( (s[ldp->re] & ldp->rebit) == 0 )
				goto mddone;
			}
		else
			{
			if( subflg != 0 )
				goto mddone;
			}
		}
	eaddm( ldp->rbit, s );
	}
mddone:
#if IBMPC
if( (exp <= 0) && (ldp->rndprc != NBITS) )
#else
if( (exp <= 0) && (ldp->rndprc != 64) && (ldp->rndprc != NBITS) )
#endif
	{
	eshup1(s);
	}
if( s[2] != 0 )
	{ /* overflow on roundoff */
	eshdn1(s);
	exp += 1;
	}
mdfin:
s[NI-1] = 0;
if( exp >= 32767L )
	{
#ifndef INFINITY
overf:
#endif
#ifdef INFINITY
	s[1] = 32767;
	for( i=2; i<NI-1; i++ )
		s[i] = 0;
#else
	s[1] = 32766;
	s[2] = 0;
	for( i=M+1; i<NI-1; i++ )
		s[i] = 0xffff;
	s[NI-1] = 0;
	if( (ldp->rndprc < 64) || (ldp->rndprc == 113) )
		{
		s[ldp->rw] &= ~ldp->rmsk;
		if( ldp->rndprc == 24 )
			{
			s[5] = 0;
			s[6] = 0;
			}
		}
#endif
	return;
	}
if( exp < 0 )
	s[1] = 0;
else
	s[1] = (unsigned short )exp;
}



/*
;	Subtract external format numbers.
;
;	unsigned short a[NE], b[NE], c[NE];
;       LDPARMS *ldp;
;	esub( a, b, c, ldp );	 c = b - a
*/

static void esub(short unsigned int *a, short unsigned int *b, short unsigned int *c, LDPARMS *ldp)
{

#ifdef NANS
if( eisnan(a) )
	{
	emov (a, c);
	return;
	}
if( eisnan(b) )
	{
	emov(b,c);
	return;
	}
/* Infinity minus infinity is a NaN.
 * Test for subtracting infinities of the same sign.
 */
if( eisinf(a) && eisinf(b) && ((eisneg (a) ^ eisneg (b)) == 0))
	{
	mtherr( "esub", DOMAIN );
	enan( c, NBITS );
	return;
	}
#endif
eadd1( a, b, c, 1, ldp );
}



static void eadd1(short unsigned int *a, short unsigned int *b, short unsigned int *c, int subflg, LDPARMS *ldp)
{
unsigned short ai[NI], bi[NI], ci[NI];
int i, lost, j, k;
long lt, lta, ltb;

#ifdef INFINITY
if( eisinf(a) )
	{
	emov(a,c);
	if( subflg )
		eneg(c);
	return;
	}
if( eisinf(b) )
	{
	emov(b,c);
	return;
	}
#endif
emovi( a, ai );
emovi( b, bi );
if( subflg )
	ai[0] = ~ai[0];

/* compare exponents */
lta = ai[E];
ltb = bi[E];
lt = lta - ltb;
if( lt > 0L )
	{	/* put the larger number in bi */
	emovz( bi, ci );
	emovz( ai, bi );
	emovz( ci, ai );
	ltb = bi[E];
	lt = -lt;
	}
lost = 0;
if( lt != 0L )
	{
	if( lt < (long )(-NBITS-1) )
		goto done;	/* answer same as larger addend */
	k = (int )lt;
	lost = eshift( ai, k ); /* shift the smaller number down */
	}
else
	{
/* exponents were the same, so must compare significands */
	i = ecmpm( ai, bi );
	if( i == 0 )
		{ /* the numbers are identical in magnitude */
		/* if different signs, result is zero */
		if( ai[0] != bi[0] )
			{
			eclear(c);
			return;
			}
		/* if same sign, result is double */
		/* double denomalized tiny number */
		if( (bi[E] == 0) && ((bi[3] & 0x8000) == 0) )
			{
			eshup1( bi );
			goto done;
			}
		/* add 1 to exponent unless both are zero! */
		for( j=1; j<NI-1; j++ )
			{
			if( bi[j] != 0 )
				{
/* This could overflow, but let emovo take care of that. */
				ltb += 1;
				break;
				}
			}
		bi[E] = (unsigned short )ltb;
		goto done;
		}
	if( i > 0 )
		{	/* put the larger number in bi */
		emovz( bi, ci );
		emovz( ai, bi );
		emovz( ci, ai );
		}
	}
if( ai[0] == bi[0] )
	{
	eaddm( ai, bi );
	subflg = 0;
	}
else
	{
	esubm( ai, bi );
	subflg = 1;
	}
emdnorm( bi, lost, subflg, ltb, 64, ldp );

done:
emovo( bi, c, ldp );
}



/*
;	Divide.
;
;	unsigned short a[NE], b[NE], c[NE];
;       LDPARMS *ldp;
;	ediv( a, b, c, ldp );	c = b / a
*/
static void ediv(short unsigned int *a, short unsigned int *b, short unsigned int *c, LDPARMS *ldp)
{
unsigned short ai[NI], bi[NI];
int i;
long lt, lta, ltb;

#ifdef NANS
/* Return any NaN input. */
if( eisnan(a) )
	{
	emov(a,c);
	return;
	}
if( eisnan(b) )
	{
	emov(b,c);
	return;
	}
/* Zero over zero, or infinity over infinity, is a NaN. */
if( ((ecmp(a,ezero) == 0) && (ecmp(b,ezero) == 0))
	|| (eisinf (a) && eisinf (b)) )
	{
	mtherr( "ediv", DOMAIN );
	enan( c, NBITS );
	return;
	}
#endif
/* Infinity over anything else is infinity. */
#ifdef INFINITY
if( eisinf(b) )
	{
	if( eisneg(a) ^ eisneg(b) )
		*(c+(NE-1)) = 0x8000;
	else
		*(c+(NE-1)) = 0;
	einfin(c, ldp);
	return;
	}
if( eisinf(a) )
	{
	eclear(c);
	return;
	}
#endif
emovi( a, ai );
emovi( b, bi );
lta = ai[E];
ltb = bi[E];
if( bi[E] == 0 )
	{ /* See if numerator is zero. */
	for( i=1; i<NI-1; i++ )
		{
		if( bi[i] != 0 )
			{
			ltb -= enormlz( bi );
			goto dnzro1;
			}
		}
	eclear(c);
	return;
	}
dnzro1:

if( ai[E] == 0 )
	{	/* possible divide by zero */
	for( i=1; i<NI-1; i++ )
		{
		if( ai[i] != 0 )
			{
			lta -= enormlz( ai );
			goto dnzro2;
			}
		}
	if( ai[0] == bi[0] )
		*(c+(NE-1)) = 0;
	else
		*(c+(NE-1)) = 0x8000;
	einfin(c, ldp);
	mtherr( "ediv", SING );
	return;
	}
dnzro2:

i = edivm( ai, bi, ldp );
/* calculate exponent */
lt = ltb - lta + EXONE;
emdnorm( bi, i, 0, lt, 64, ldp );
/* set the sign */
if( ai[0] == bi[0] )
	bi[0] = 0;
else
	bi[0] = 0Xffff;
emovo( bi, c, ldp );
}



/*
;	Multiply.
;
;	unsigned short a[NE], b[NE], c[NE];
;       LDPARMS *ldp
;	emul( a, b, c, ldp );	c = b * a
*/
static void emul(short unsigned int *a, short unsigned int *b, short unsigned int *c, LDPARMS *ldp)
{
unsigned short ai[NI], bi[NI];
int i, j;
long lt, lta, ltb;

#ifdef NANS
/* NaN times anything is the same NaN. */
if( eisnan(a) )
	{
	emov(a,c);
	return;
	}
if( eisnan(b) )
	{
	emov(b,c);
	return;
	}
/* Zero times infinity is a NaN. */
if( (eisinf(a) && (ecmp(b,ezero) == 0))
	|| (eisinf(b) && (ecmp(a,ezero) == 0)) )
	{
	mtherr( "emul", DOMAIN );
	enan( c, NBITS );
	return;
	}
#endif
/* Infinity times anything else is infinity. */
#ifdef INFINITY
if( eisinf(a) || eisinf(b) )
	{
	if( eisneg(a) ^ eisneg(b) )
		*(c+(NE-1)) = 0x8000;
	else
		*(c+(NE-1)) = 0;
	einfin(c, ldp);
	return;
	}
#endif
emovi( a, ai );
emovi( b, bi );
lta = ai[E];
ltb = bi[E];
if( ai[E] == 0 )
	{
	for( i=1; i<NI-1; i++ )
		{
		if( ai[i] != 0 )
			{
			lta -= enormlz( ai );
			goto mnzer1;
			}
		}
	eclear(c);
	return;
	}
mnzer1:

if( bi[E] == 0 )
	{
	for( i=1; i<NI-1; i++ )
		{
		if( bi[i] != 0 )
			{
			ltb -= enormlz( bi );
			goto mnzer2;
			}
		}
	eclear(c);
	return;
	}
mnzer2:

/* Multiply significands */
j = emulm( ai, bi, ldp );
/* calculate exponent */
lt = lta + ltb - (EXONE - 1);
emdnorm( bi, j, 0, lt, 64, ldp );
/* calculate sign of product */
if( ai[0] == bi[0] )
	bi[0] = 0;
else
	bi[0] = 0xffff;
emovo( bi, c, ldp );
}



#if SIMD_LDBL_MANT_DIG > 64
static void e113toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp)
{
register unsigned short r;
unsigned short *e, *p;
unsigned short yy[NI];
int denorm, i;

e = pe;
denorm = 0;
ecleaz(yy);
#ifdef IBMPC
e += 7;
#endif
r = *e;
yy[0] = 0;
if( r & 0x8000 )
	yy[0] = 0xffff;
r &= 0x7fff;
#ifdef INFINITY
if( r == 0x7fff )
	{
#ifdef NANS
#ifdef IBMPC
	for( i=0; i<7; i++ )
		{
		if( pe[i] != 0 )
			{
			enan( y, NBITS );
			return;
			}
		}
#else  /* !IBMPC */
	for( i=1; i<8; i++ )
		{
		if( pe[i] != 0 )
			{
			enan( y, NBITS );
			return;
			}
		}
#endif /* !IBMPC */
#endif /* NANS */
	eclear( y );
	einfin( y, ldp );
	if( *e & 0x8000 )
		eneg(y);
	return;
	}
#endif  /* INFINITY */
yy[E] = r;
p = &yy[M + 1];
#ifdef IBMPC
for( i=0; i<7; i++ )
	*p++ = *(--e);
#else  /* IBMPC */
++e;
for( i=0; i<7; i++ )
	*p++ = *e++;
#endif /* IBMPC */ 
/* If denormal, remove the implied bit; else shift down 1. */
if( r == 0 )
	{
	yy[M] = 0;
	}
else
	{
	yy[M] = 1;
	eshift( yy, -1 );
	}
emovo(yy,y,ldp);
}

/* move out internal format to ieee long double */
static void toe113(short unsigned int *a, short unsigned int *b)
{
register unsigned short *p, *q;
unsigned short i;

#ifdef NANS
if( eiisnan(a) )
	{
	enan( b, 113 );
	return;
	}
#endif
p = a;
#ifdef MIEEE
q = b;
#else
q = b + 7;			/* point to output exponent */
#endif

/* If not denormal, delete the implied bit. */
if( a[E] != 0 )
	{
	eshup1 (a);
	}
/* combine sign and exponent */
i = *p++;
#ifdef MIEEE
if( i )
	*q++ = *p++ | 0x8000;
else
	*q++ = *p++;
#else
if( i )
	*q-- = *p++ | 0x8000;
else
	*q-- = *p++;
#endif
/* skip over guard word */
++p;
/* move the significand */
#ifdef MIEEE
for (i = 0; i < 7; i++)
	*q++ = *p++;
#else
for (i = 0; i < 7; i++)
	*q-- = *p++;
#endif
}
#endif /* SIMD_LDBL_MANT_DIG > 64 */


#if SIMD_LDBL_MANT_DIG == 64
static void e64toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp)
{
unsigned short yy[NI];
unsigned short *p, *q, *e;
int i;

e = pe;
p = yy;

for( i=0; i<NE-5; i++ )
	*p++ = 0;
#ifdef IBMPC
for( i=0; i<5; i++ )
	*p++ = *e++;
#endif
#ifdef DEC
for( i=0; i<5; i++ )
	*p++ = *e++;
#endif
#ifdef MIEEE
p = &yy[0] + (NE-1);
*p-- = *e++;
++e;  /* MIEEE skips over 2nd short */
for( i=0; i<4; i++ )
	*p-- = *e++;
#endif

#ifdef IBMPC
/* For Intel long double, shift denormal significand up 1
   -- but only if the top significand bit is zero.  */
if((yy[NE-1] & 0x7fff) == 0 && (yy[NE-2] & 0x8000) == 0)
  {
    unsigned short temp[NI+1];
    emovi(yy, temp);
    eshup1(temp);
    emovo(temp,y,ldp);
    return;
  }
#endif
#ifdef INFINITY
/* Point to the exponent field.  */
p = &yy[NE-1];
if( *p == 0x7fff )
	{
#ifdef NANS
#ifdef IBMPC
	for( i=0; i<4; i++ )
		{
		if((i != 3 && pe[i] != 0)
		   /* Check for Intel long double infinity pattern.  */
		   || (i == 3 && pe[i] != 0x8000))
			{
			enan( y, NBITS );
			return;
			}
		}
#endif
#ifdef MIEEE
	for( i=2; i<=5; i++ )
		{
		if( pe[i] != 0 )
			{
			enan( y, NBITS );
			return;
			}
		}
#endif
#endif /* NANS */
	eclear( y );
	einfin( y, ldp );
	if( *p & 0x8000 )
		eneg(y);
	return;
	}
#endif /* INFINITY */
p = yy;
q = y;
for( i=0; i<NE; i++ )
	*q++ = *p++;
}

/* move out internal format to ieee long double */
static void toe64(short unsigned int *a, short unsigned int *b)
{
register unsigned short *p, *q;
unsigned short i;

#ifdef NANS
if( eiisnan(a) )
	{
	enan( b, 64 );
	return;
	}
#endif
#ifdef IBMPC
/* Shift Intel denormal significand down 1.  */
if( a[E] == 0 )
  eshdn1(a);
#endif
p = a;
#ifdef MIEEE
q = b;
#else
q = b + 4; /* point to output exponent */
/* NOTE: Intel data type is 96 bits wide, clear the last word here. */
*(q+1)= 0;
#endif

/* combine sign and exponent */
i = *p++;
#ifdef MIEEE
if( i )
	*q++ = *p++ | 0x8000;
else
	*q++ = *p++;
*q++ = 0; /* leave 2nd short blank */
#else
if( i )
	*q-- = *p++ | 0x8000;
else
	*q-- = *p++;
#endif
/* skip over guard word */
++p;
/* move the significand */
#ifdef MIEEE
for( i=0; i<4; i++ )
	*q++ = *p++;
#else
#ifdef INFINITY
#ifdef IBMPC
if (eiisinf (a))
        {
	/* Intel long double infinity.  */
	*q-- = 0x8000;
	*q-- = 0;
	*q-- = 0;
	*q = 0;
	return;
	}
#endif /* IBMPC */
#endif /* INFINITY */
for( i=0; i<4; i++ )
	*q-- = *p++;
#endif
}

#endif /* SIMD_LDBL_MANT_DIG == 64 */

#if SIMD_LDBL_MANT_DIG == 53
/*
; Convert IEEE double precision to e type
;	double d;
;	unsigned short x[N+2];
;	e53toe( &d, x );
*/
static void e53toe(short unsigned int *pe, short unsigned int *y, LDPARMS *ldp)
{
#ifdef DEC

dectoe( pe, y ); /* see etodec.c */

#else

register unsigned short r;
register unsigned short *p, *e;
unsigned short yy[NI];
int denorm, k;

e = pe;
denorm = 0;	/* flag if denormalized number */
ecleaz(yy);
#ifdef IBMPC
e += 3;
#endif
#ifdef DEC
e += 3;
#endif 
r = *e;
yy[0] = 0;
if( r & 0x8000 )
	yy[0] = 0xffff;
yy[M] = (r & 0x0f) | 0x10;
r &= ~0x800f;	/* strip sign and 4 significand bits */
#ifdef INFINITY
if( r == 0x7ff0 )
	{
#ifdef NANS
#ifdef IBMPC
	if( ((pe[3] & 0xf) != 0) || (pe[2] != 0)
		|| (pe[1] != 0) || (pe[0] != 0) )
		{
		enan( y, NBITS );
		return;
		}
#else  /* !IBMPC */
	if( ((pe[0] & 0xf) != 0) || (pe[1] != 0)
		 || (pe[2] != 0) || (pe[3] != 0) )
		{
		enan( y, NBITS );
		return;
		}
#endif /* !IBMPC */
#endif  /* NANS */
	eclear( y );
	einfin( y, ldp );
	if( yy[0] )
		eneg(y);
	return;
	}
#endif
r >>= 4;
/* If zero exponent, then the significand is denormalized.
 * So, take back the understood high significand bit. */ 
if( r == 0 )
	{
	denorm = 1;
	yy[M] &= ~0x10;
	}
r += EXONE - 01777;
yy[E] = r;
p = &yy[M+1];
#ifdef IBMPC
*p++ = *(--e);
*p++ = *(--e);
*p++ = *(--e);
#else  /* !IBMPC */
++e;
*p++ = *e++;
*p++ = *e++;
*p++ = *e++;
#endif /* !IBMPC */
(void )eshift( yy, -5 );
if( denorm )
	{ /* if zero exponent, then normalize the significand */
	if( (k = enormlz(yy)) > NBITS )
		ecleazs(yy);
	else
		yy[E] -= (unsigned short )(k-1);
	}
emovo( yy, y, ldp );
#endif /* !DEC */
}

/*
; e type to IEEE double precision
;	double d;
;	unsigned short x[NE];
;	etoe53( x, &d );
*/

#ifdef DEC

static void etoe53( x, e )
unsigned short *x, *e;
{
etodec( x, e ); /* see etodec.c */
}

static void toe53( x, y )
unsigned short *x, *y;
{
todec( x, y );
}

#else

static void toe53(short unsigned int *x, short unsigned int *y)
{
unsigned short i;
unsigned short *p;


#ifdef NANS
if( eiisnan(x) )
	{
	enan( y, 53 );
	return;
	}
#endif
p = &x[0];
#ifdef IBMPC
y += 3;
#endif
#ifdef DEC
y += 3;
#endif
*y = 0;	/* output high order */
if( *p++ )
	*y = 0x8000;	/* output sign bit */

i = *p++;
if( i >= (unsigned int )2047 )
	{	/* Saturate at largest number less than infinity. */
#ifdef INFINITY
	*y |= 0x7ff0;
#ifdef IBMPC
	*(--y) = 0;
	*(--y) = 0;
	*(--y) = 0;
#else /* !IBMPC */
	++y;
	*y++ = 0;
	*y++ = 0;
	*y++ = 0;
#endif /* IBMPC */
#else /* !INFINITY */
	*y |= (unsigned short )0x7fef;
#ifdef IBMPC
	*(--y) = 0xffff;
	*(--y) = 0xffff;
	*(--y) = 0xffff;
#else /* !IBMPC */
	++y;
	*y++ = 0xffff;
	*y++ = 0xffff;
	*y++ = 0xffff;
#endif
#endif /* !INFINITY */
	return;
	}
if( i == 0 )
	{
	(void )eshift( x, 4 );
	}
else
	{
	i <<= 4;
	(void )eshift( x, 5 );
	}
i |= *p++ & (unsigned short )0x0f;	/* *p = xi[M] */
*y |= (unsigned short )i; /* high order output already has sign bit set */
#ifdef IBMPC
*(--y) = *p++;
*(--y) = *p++;
*(--y) = *p;
#else /* !IBMPC */
++y;
*y++ = *p++;
*y++ = *p++;
*y++ = *p++;
#endif /* !IBMPC */
}

#endif /* not DEC */
#endif /* SIMD_LDBL_MANT_DIG == 53 */

#if SIMD_LDBL_MANT_DIG == 24
/*
; Convert IEEE single precision to e type
;	float d;
;	unsigned short x[N+2];
;	dtox( &d, x );
*/
void e24toe( short unsigned int *pe, short unsigned int *y, LDPARMS *ldp )
{
register unsigned short r;
register unsigned short *p, *e;
unsigned short yy[NI];
int denorm, k;

e = pe;
denorm = 0;	/* flag if denormalized number */
ecleaz(yy);
#ifdef IBMPC
e += 1;
#endif
#ifdef DEC
e += 1;
#endif
r = *e;
yy[0] = 0;
if( r & 0x8000 )
	yy[0] = 0xffff;
yy[M] = (r & 0x7f) | 0200;
r &= ~0x807f;	/* strip sign and 7 significand bits */
#ifdef INFINITY
if( r == 0x7f80 )
	{
#ifdef NANS
#ifdef MIEEE
	if( ((pe[0] & 0x7f) != 0) || (pe[1] != 0) )
		{
		enan( y, NBITS );
		return;
		}
#else  /* !MIEEE */
	if( ((pe[1] & 0x7f) != 0) || (pe[0] != 0) )
		{
		enan( y, NBITS );
		return;
		}
#endif /* !MIEEE */
#endif  /* NANS */
	eclear( y );
	einfin( y, ldp );
	if( yy[0] )
		eneg(y);
	return;
	}
#endif
r >>= 7;
/* If zero exponent, then the significand is denormalized.
 * So, take back the understood high significand bit. */ 
if( r == 0 )
	{
	denorm = 1;
	yy[M] &= ~0200;
	}
r += EXONE - 0177;
yy[E] = r;
p = &yy[M+1];
#ifdef IBMPC
*p++ = *(--e);
#endif
#ifdef DEC
*p++ = *(--e);
#endif
#ifdef MIEEE
++e;
*p++ = *e++;
#endif
(void )eshift( yy, -8 );
if( denorm )
	{ /* if zero exponent, then normalize the significand */
	if( (k = enormlz(yy)) > NBITS )
		ecleazs(yy);
	else
		yy[E] -= (unsigned short )(k-1);
	}
emovo( yy, y, ldp );
}

static void toe24(short unsigned int *x, short unsigned int *y)
{
unsigned short i;
unsigned short *p;

#ifdef NANS
if( eiisnan(x) )
	{
	enan( y, 24 );
	return;
	}
#endif
p = &x[0];
#ifdef IBMPC
y += 1;
#endif
#ifdef DEC
y += 1;
#endif
*y = 0;	/* output high order */
if( *p++ )
	*y = 0x8000;	/* output sign bit */

i = *p++;
if( i >= 255 )
	{	/* Saturate at largest number less than infinity. */
#ifdef INFINITY
	*y |= (unsigned short )0x7f80;
#ifdef IBMPC
	*(--y) = 0;
#endif
#ifdef DEC
	*(--y) = 0;
#endif
#ifdef MIEEE
	++y;
	*y = 0;
#endif
#else /* !INFINITY */
	*y |= (unsigned short )0x7f7f;
#ifdef IBMPC
	*(--y) = 0xffff;
#endif
#ifdef DEC
	*(--y) = 0xffff;
#endif
#ifdef MIEEE
	++y;
	*y = 0xffff;
#endif
#endif /* !INFINITY */
	return;
	}
if( i == 0 )
	{
	(void )eshift( x, 7 );
	}
else
	{
	i <<= 7;
	(void )eshift( x, 8 );
	}
i |= *p++ & (unsigned short )0x7f;	/* *p = xi[M] */
*y |= i;	/* high order output already has sign bit set */
#ifdef IBMPC
*(--y) = *p;
#endif
#ifdef DEC
*(--y) = *p;
#endif
#ifdef MIEEE
++y;
*y = *p;
#endif
}
#endif /* SIMD_LDBL_MANT_DIG == 24 */

/* Compare two e type numbers.
 *
 * unsigned short a[NE], b[NE];
 * ecmp( a, b );
 *
 *  returns +1 if a > b
 *           0 if a == b
 *          -1 if a < b
 *          -2 if either a or b is a NaN.
 */
static int ecmp(short unsigned int *a, short unsigned int *b)
{
unsigned short ai[NI], bi[NI];
register unsigned short *p, *q;
register int i;
int msign;

#ifdef NANS
if (eisnan (a)  || eisnan (b))
	return( -2 );
#endif
emovi( a, ai );
p = ai;
emovi( b, bi );
q = bi;

if( *p != *q )
	{ /* the signs are different */
/* -0 equals + 0 */
	for( i=1; i<NI-1; i++ )
		{
		if( ai[i] != 0 )
			goto nzro;
		if( bi[i] != 0 )
			goto nzro;
		}
	return(0);
nzro:
	if( *p == 0 )
		return( 1 );
	else
		return( -1 );
	}
/* both are the same sign */
if( *p == 0 )
	msign = 1;
else
	msign = -1;
i = NI-1;
do
	{
	if( *p++ != *q++ )
		{
		goto diff;
		}
	}
while( --i > 0 );

return(0);	/* equality */



diff:

if( *(--p) > *(--q) )
	return( msign );		/* p is bigger */
else
	return( -msign );	/* p is littler */
}


/*
;	Shift significand
;
;	Shifts significand area up or down by the number of bits
;	given by the variable sc.
*/
static int eshift(short unsigned int *x, int sc)
{
unsigned short lost;
unsigned short *p;

if( sc == 0 )
	return( 0 );

lost = 0;
p = x + NI-1;

if( sc < 0 )
	{
	sc = -sc;
	while( sc >= 16 )
		{
		lost |= *p;	/* remember lost bits */
		eshdn6(x);
		sc -= 16;
		}

	while( sc >= 8 )
		{
		lost |= *p & 0xff;
		eshdn8(x);
		sc -= 8;
		}

	while( sc > 0 )
		{
		lost |= *p & 1;
		eshdn1(x);
		sc -= 1;
		}
	}
else
	{
	while( sc >= 16 )
		{
		eshup6(x);
		sc -= 16;
		}

	while( sc >= 8 )
		{
		eshup8(x);
		sc -= 8;
		}

	while( sc > 0 )
		{
		eshup1(x);
		sc -= 1;
		}
	}
if( lost )
	lost = 1;
return( (int )lost );
}



/*
;	normalize
;
; Shift normalizes the significand area pointed to by argument
; shift count (up = positive) is returned.
*/
static int enormlz(short unsigned int *x)
{
register unsigned short *p;
int sc;

sc = 0;
p = &x[M];
if( *p != 0 )
	goto normdn;
++p;
if( *p & 0x8000 )
	return( 0 );	/* already normalized */
while( *p == 0 )
	{
	eshup6(x);
	sc += 16;
/* With guard word, there are NBITS+16 bits available.
 * return true if all are zero.
 */
	if( sc > NBITS )
		return( sc );
	}
/* see if high byte is zero */
while( (*p & 0xff00) == 0 )
	{
	eshup8(x);
	sc += 8;
	}
/* now shift 1 bit at a time */
while( (*p  & 0x8000) == 0)
	{
	eshup1(x);
	sc += 1;
	if( sc > (NBITS+16) )
		{
		mtherr( "enormlz", UNDERFLOW );
		return( sc );
		}
	}
return( sc );

/* Normalize by shifting down out of the high guard word
   of the significand */
normdn:

if( *p & 0xff00 )
	{
	eshdn8(x);
	sc -= 8;
	}
while( *p != 0 )
	{
	eshdn1(x);
	sc -= 1;

	if( sc < -NBITS )
		{
		mtherr( "enormlz", OVERFLOW );
		return( sc );
		}
	}
return( sc );
}




/* Convert e type number to decimal format ASCII string.
 * The constants are for 64 bit precision.
 */

#define NTEN 12
#define MAXP 4096

#if NE == 10
static unsigned short etens[NTEN + 1][NE] =
{
  {0x6576, 0x4a92, 0x804a, 0x153f,
   0xc94c, 0x979a, 0x8a20, 0x5202, 0xc460, 0x7525,},	/* 10**4096 */
  {0x6a32, 0xce52, 0x329a, 0x28ce,
   0xa74d, 0x5de4, 0xc53d, 0x3b5d, 0x9e8b, 0x5a92,},	/* 10**2048 */
  {0x526c, 0x50ce, 0xf18b, 0x3d28,
   0x650d, 0x0c17, 0x8175, 0x7586, 0xc976, 0x4d48,},
  {0x9c66, 0x58f8, 0xbc50, 0x5c54,
   0xcc65, 0x91c6, 0xa60e, 0xa0ae, 0xe319, 0x46a3,},
  {0x851e, 0xeab7, 0x98fe, 0x901b,
   0xddbb, 0xde8d, 0x9df9, 0xebfb, 0xaa7e, 0x4351,},
  {0x0235, 0x0137, 0x36b1, 0x336c,
   0xc66f, 0x8cdf, 0x80e9, 0x47c9, 0x93ba, 0x41a8,},
  {0x50f8, 0x25fb, 0xc76b, 0x6b71,
   0x3cbf, 0xa6d5, 0xffcf, 0x1f49, 0xc278, 0x40d3,},
  {0x0000, 0x0000, 0x0000, 0x0000,
   0xf020, 0xb59d, 0x2b70, 0xada8, 0x9dc5, 0x4069,},
  {0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0400, 0xc9bf, 0x8e1b, 0x4034,},
  {0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x2000, 0xbebc, 0x4019,},
  {0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0x9c40, 0x400c,},
  {0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0xc800, 0x4005,},
  {0x0000, 0x0000, 0x0000, 0x0000,
   0x0000, 0x0000, 0x0000, 0x0000, 0xa000, 0x4002,},	/* 10**1 */
};

static unsigned short emtens[NTEN + 1][NE] =
{
  {0x2030, 0xcffc, 0xa1c3, 0x8123,
   0x2de3, 0x9fde, 0xd2ce, 0x04c8, 0xa6dd, 0x0ad8,},	/* 10**-4096 */
  {0x8264, 0xd2cb, 0xf2ea, 0x12d4,
   0x4925, 0x2de4, 0x3436, 0x534f, 0xceae, 0x256b,},	/* 10**-2048 */
  {0xf53f, 0xf698, 0x6bd3, 0x0158,
   0x87a6, 0xc0bd, 0xda57, 0x82a5, 0xa2a6, 0x32b5,},
  {0xe731, 0x04d4, 0xe3f2, 0xd332,
   0x7132, 0xd21c, 0xdb23, 0xee32, 0x9049, 0x395a,},
  {0xa23e, 0x5308, 0xfefb, 0x1155,
   0xfa91, 0x1939, 0x637a, 0x4325, 0xc031, 0x3cac,},
  {0xe26d, 0xdbde, 0xd05d, 0xb3f6,
   0xac7c, 0xe4a0, 0x64bc, 0x467c, 0xddd0, 0x3e55,},
  {0x2a20, 0x6224, 0x47b3, 0x98d7,
   0x3f23, 0xe9a5, 0xa539, 0xea27, 0xa87f, 0x3f2a,},
  {0x0b5b, 0x4af2, 0xa581, 0x18ed,
   0x67de, 0x94ba, 0x4539, 0x1ead, 0xcfb1, 0x3f94,},
  {0xbf71, 0xa9b3, 0x7989, 0xbe68,
   0x4c2e, 0xe15b, 0xc44d, 0x94be, 0xe695, 0x3fc9,},
  {0x3d4d, 0x7c3d, 0x36ba, 0x0d2b,
   0xfdc2, 0xcefc, 0x8461, 0x7711, 0xabcc, 0x3fe4,},
  {0xc155, 0xa4a8, 0x404e, 0x6113,
   0xd3c3, 0x652b, 0xe219, 0x1758, 0xd1b7, 0x3ff1,},
  {0xd70a, 0x70a3, 0x0a3d, 0xa3d7,
   0x3d70, 0xd70a, 0x70a3, 0x0a3d, 0xa3d7, 0x3ff8,},
  {0xcccd, 0xcccc, 0xcccc, 0xcccc,
   0xcccc, 0xcccc, 0xcccc, 0xcccc, 0xcccc, 0x3ffb,},	/* 10**-1 */
};
#else
static unsigned short etens[NTEN+1][NE] = {
{0xc94c,0x979a,0x8a20,0x5202,0xc460,0x7525,},/* 10**4096 */
{0xa74d,0x5de4,0xc53d,0x3b5d,0x9e8b,0x5a92,},/* 10**2048 */
{0x650d,0x0c17,0x8175,0x7586,0xc976,0x4d48,},
{0xcc65,0x91c6,0xa60e,0xa0ae,0xe319,0x46a3,},
{0xddbc,0xde8d,0x9df9,0xebfb,0xaa7e,0x4351,},
{0xc66f,0x8cdf,0x80e9,0x47c9,0x93ba,0x41a8,},
{0x3cbf,0xa6d5,0xffcf,0x1f49,0xc278,0x40d3,},
{0xf020,0xb59d,0x2b70,0xada8,0x9dc5,0x4069,},
{0x0000,0x0000,0x0400,0xc9bf,0x8e1b,0x4034,},
{0x0000,0x0000,0x0000,0x2000,0xbebc,0x4019,},
{0x0000,0x0000,0x0000,0x0000,0x9c40,0x400c,},
{0x0000,0x0000,0x0000,0x0000,0xc800,0x4005,},
{0x0000,0x0000,0x0000,0x0000,0xa000,0x4002,}, /* 10**1 */
};

static unsigned short emtens[NTEN+1][NE] = {
{0x2de4,0x9fde,0xd2ce,0x04c8,0xa6dd,0x0ad8,}, /* 10**-4096 */
{0x4925,0x2de4,0x3436,0x534f,0xceae,0x256b,}, /* 10**-2048 */
{0x87a6,0xc0bd,0xda57,0x82a5,0xa2a6,0x32b5,},
{0x7133,0xd21c,0xdb23,0xee32,0x9049,0x395a,},
{0xfa91,0x1939,0x637a,0x4325,0xc031,0x3cac,},
{0xac7d,0xe4a0,0x64bc,0x467c,0xddd0,0x3e55,},
{0x3f24,0xe9a5,0xa539,0xea27,0xa87f,0x3f2a,},
{0x67de,0x94ba,0x4539,0x1ead,0xcfb1,0x3f94,},
{0x4c2f,0xe15b,0xc44d,0x94be,0xe695,0x3fc9,},
{0xfdc2,0xcefc,0x8461,0x7711,0xabcc,0x3fe4,},
{0xd3c3,0x652b,0xe219,0x1758,0xd1b7,0x3ff1,},
{0x3d71,0xd70a,0x70a3,0x0a3d,0xa3d7,0x3ff8,},
{0xcccd,0xcccc,0xcccc,0xcccc,0xcccc,0x3ffb,}, /* 10**-1 */
};
#endif



/* ASCII string outputs for unix */


#if 0
void _IO_ldtostr(x, string, ndigs, flags, fmt)
long double *x;
char *string;
int ndigs;
int flags;
char fmt;
{
unsigned short w[NI];
char *t, *u;
LDPARMS rnd;
LDPARMS *ldp = &rnd;

rnd.rlast = -1;
rnd.rndprc = NBITS;

if (sizeof(long double) == 16)
  e113toe( (unsigned short *)x, w, ldp );
else
  e64toe( (unsigned short *)x, w, ldp );

etoasc( w, string, ndigs, -1, ldp );
if( ndigs == 0 && flags == 0 )
	{
	/* Delete the decimal point unless alternate format.  */
	t = string;	
	while( *t != '.' )
		++t;
	u = t +  1;
	while( *t != '\0' )
		*t++ = *u++;
	}
if (*string == ' ')
	{
	t = string;	
	u = t + 1;
	while( *t != '\0' )
		*t++ = *u++;
	}
if (fmt == 'E')
	{
	t = string;	
	while( *t != 'e' )
		++t;
	*t = 'E';
	}
}

#endif

/* This routine will not return more than NDEC+1 digits. */

char *
_simdldtoa_r (struct _reent *ptr, LONG_DOUBLE_UNION *d, int mode, int ndigits, int *decpt, 
          int *sign, char **rve)
{
unsigned short e[NI];
char *s, *p;
int i, j, k;
LDPARMS rnd;
LDPARMS *ldp = &rnd;
char *outstr;

rnd.rlast = -1;
rnd.rndprc = NBITS;

  _REENT_CHECK_MP(ptr);

/* reentrancy addition to use mprec storage pool */
if (_REENT_MP_RESULT(ptr))
  {
    _REENT_MP_RESULT(ptr)->_k = _REENT_MP_RESULT_K(ptr);
    _REENT_MP_RESULT(ptr)->_maxwds = 1 << _REENT_MP_RESULT_K(ptr);
    Bfree (ptr, _REENT_MP_RESULT(ptr));
    _REENT_MP_RESULT(ptr) = 0;
  }

#if SIMD_LDBL_MANT_DIG == 24
e24toe( (unsigned short *)d, e, ldp );
#elif SIMD_LDBL_MANT_DIG == 53
e53toe( (unsigned short *)d, e, ldp );
#elif SIMD_LDBL_MANT_DIG == 64
e64toe( (unsigned short *)d, e, ldp );
#else
e113toe( (unsigned short *)d, e, ldp );
#endif

if( eisneg(e) )
        *sign = 1;
else
        *sign = 0;
/* Mode 3 is "f" format.  */
if( mode != 3 )
        ndigits -= 1;
/* Mode 0 is for %.999 format, which is supposed to give a
   minimum length string that will convert back to the same binary value.
   For now, just ask for 20 digits which is enough but sometimes too many.  */
if( mode == 0 )
        ndigits = 20;

/* reentrancy addition to use mprec storage pool */
/* we want to have enough space to hold the formatted result */
i = ndigits + (mode == 3 ? (MAX_EXP_DIGITS + 1) : 1);
j = sizeof (__ULong);
for (_REENT_MP_RESULT_K(ptr) = 0; sizeof (_Bigint) - sizeof (__ULong) + j <= (unsigned)i; j <<= 1)
  _REENT_MP_RESULT_K(ptr)++;
_REENT_MP_RESULT(ptr) = Balloc (ptr, _REENT_MP_RESULT_K(ptr));
outstr = (char *)_REENT_MP_RESULT(ptr);

/* This sanity limit must agree with the corresponding one in etoasc, to
   keep straight the returned value of outexpon.  */
if( ndigits > NDEC )
        ndigits = NDEC;

etoasc( e, outstr, ndigits, mode, ldp );
s =  outstr;
if( eisinf(e) || eisnan(e) )
        {
        *decpt = 9999;
        goto stripspaces;
        }
*decpt = ldp->outexpon + 1;

/* Transform the string returned by etoasc into what the caller wants.  */

/* Look for decimal point and delete it from the string. */
s = outstr;
while( *s != '\0' )
        {
        if( *s == '.' )
               goto yesdecpt;
        ++s;
        }
goto nodecpt;

yesdecpt:

/* Delete the decimal point.  */
while( *s != '\0' )
        {
        *s = *(s+1);
        ++s;
        }

nodecpt:

/* Back up over the exponent field. */
while( *s != 'E' && s > outstr)
        --s;
*s = '\0';

stripspaces:

/* Strip leading spaces and sign. */
p = outstr;
while( *p == ' ' || *p == '-')
        ++p;

/* Find new end of string.  */
s = outstr;
while( (*s++ = *p++) != '\0' )
        ;
--s;

/* Strip trailing zeros.  */
if( mode == 2 )
        k = 1;
else if( ndigits > ldp->outexpon )
        k = ndigits;
else
        k = ldp->outexpon;

while( *(s-1) == '0' && ((s - outstr) > k))
        *(--s) = '\0';

/* In f format, flush small off-scale values to zero.
   Rounding has been taken care of by etoasc. */
if( mode == 3 && ((ndigits + ldp->outexpon) < 0))
        {
        s = outstr;
        *s = '\0';
        *decpt = 0;
        }

if( rve )
        *rve = s;
return outstr;
}

/* Routine used to tell if long double is NaN or Infinity or regular number. 
   Returns:  0 = regular number
             1 = Nan
             2 = Infinity
*/
int
_simdldcheck (LONG_DOUBLE_UNION *d)
{
unsigned short e[NI];
LDPARMS rnd;
LDPARMS *ldp = &rnd;

rnd.rlast = -1;
rnd.rndprc = NBITS;

#if SIMD_LDBL_MANT_DIG == 24
e24toe( (unsigned short *)d, e, ldp );
#elif SIMD_LDBL_MANT_DIG == 53
e53toe( (unsigned short *)d, e, ldp );
#elif SIMD_LDBL_MANT_DIG == 64
e64toe( (unsigned short *)d, e, ldp );
#else
e113toe( (unsigned short *)d, e, ldp );
#endif

if( (e[NE-1] & 0x7fff) == 0x7fff )
	{
#ifdef NANS
	if( eisnan(e) )
		return( 1 );
#endif
	return( 2 );
	}
else
	return( 0 );
} /* _ldcheck */

static void etoasc(short unsigned int *x, char *string, int ndigits, int outformat, LDPARMS *ldp)
{
long digit;
unsigned short y[NI], t[NI], u[NI], w[NI];
unsigned short *p, *r, *ten;
unsigned short sign;
int i, j, k, expon, rndsav, ndigs;
char *s, *ss;
unsigned short m;
unsigned short *equot = ldp->equot;

ndigs = ndigits;
rndsav = ldp->rndprc;
#ifdef NANS
if( eisnan(x) )
	{
	sprintf( string, " NaN " );
	expon = 9999;
	goto bxit;
	}
#endif
ldp->rndprc = NBITS;		/* set to full precision */
emov( x, y ); /* retain external format */
if( y[NE-1] & 0x8000 )
	{
	sign = 0xffff;
	y[NE-1] &= 0x7fff;
	}
else
	{
	sign = 0;
	}
expon = 0;
ten = &etens[NTEN][0];
emov( eone, t );
/* Test for zero exponent */
if( y[NE-1] == 0 )
	{
	for( k=0; k<NE-1; k++ )
		{
		if( y[k] != 0 )
			goto tnzro; /* denormalized number */
		}
	goto isone; /* legal all zeros */
	}
tnzro:

/* Test for infinity.
 */
if( y[NE-1] == 0x7fff )
	{
	if( sign )
		sprintf( string, " -Infinity " );
	else
		sprintf( string, " Infinity " );
	expon = 9999;
	goto bxit;
	}

/* Test for exponent nonzero but significand denormalized.
 * This is an error condition.
 */
if( (y[NE-1] != 0) && ((y[NE-2] & 0x8000) == 0) )
	{
	mtherr( "etoasc", DOMAIN );
	sprintf( string, "NaN" );
	expon = 9999;
	goto bxit;
	}

/* Compare to 1.0 */
i = ecmp( eone, y );
if( i == 0 )
	goto isone;

if( i < 0 )
	{ /* Number is greater than 1 */
/* Convert significand to an integer and strip trailing decimal zeros. */
	emov( y, u );
	u[NE-1] = EXONE + NBITS - 1;

	p = &etens[NTEN-4][0];
	m = 16;
do
	{
	ediv( p, u, t, ldp );
	efloor( t, w, ldp );
	for( j=0; j<NE-1; j++ )
		{
		if( t[j] != w[j] )
			goto noint;
		}
	emov( t, u );
	expon += (int )m;
noint:
	p += NE;
	m >>= 1;
	}
while( m != 0 );

/* Rescale from integer significand */
	u[NE-1] += y[NE-1] - (unsigned int )(EXONE + NBITS - 1);
	emov( u, y );
/* Find power of 10 */
	emov( eone, t );
	m = MAXP;
	p = &etens[0][0];
	while( ecmp( ten, u ) <= 0 )
		{
		if( ecmp( p, u ) <= 0 )
			{
			ediv( p, u, u, ldp );
			emul( p, t, t, ldp );
			expon += (int )m;
			}
		m >>= 1;
		if( m == 0 )
			break;
		p += NE;
		}
	}
else
	{ /* Number is less than 1.0 */
/* Pad significand with trailing decimal zeros. */
	if( y[NE-1] == 0 )
		{
		while( (y[NE-2] & 0x8000) == 0 )
			{
			emul( ten, y, y, ldp );
			expon -= 1;
			}
		}
	else
		{
		emovi( y, w );
		for( i=0; i<NDEC+1; i++ )
			{
			if( (w[NI-1] & 0x7) != 0 )
				break;
/* multiply by 10 */
			emovz( w, u );
			eshdn1( u );
			eshdn1( u );
			eaddm( w, u );
			u[1] += 3;
			while( u[2] != 0 )
				{
				eshdn1(u);
				u[1] += 1;
				}
			if( u[NI-1] != 0 )
				break;
			if( eone[NE-1] <= u[1] )
				break;
			emovz( u, w );
			expon -= 1;
			}
		emovo( w, y, ldp );
		}
	k = -MAXP;
	p = &emtens[0][0];
	r = &etens[0][0];
	emov( y, w );
	emov( eone, t );
	while( ecmp( eone, w ) > 0 )
		{
		if( ecmp( p, w ) >= 0 )
			{
			emul( r, w, w, ldp );
			emul( r, t, t, ldp );
			expon += k;
			}
		k /= 2;
		if( k == 0 )
			break;
		p += NE;
		r += NE;
		}
	ediv( t, eone, t, ldp );
	}
isone:
/* Find the first (leading) digit. */
emovi( t, w );
emovz( w, t );
emovi( y, w );
emovz( w, y );
eiremain( t, y, ldp );
digit = equot[NI-1];
while( (digit == 0) && (ecmp(y,ezero) != 0) )
	{
	eshup1( y );
	emovz( y, u );
	eshup1( u );
	eshup1( u );
	eaddm( u, y );
	eiremain( t, y, ldp );
	digit = equot[NI-1];
	expon -= 1;
	}
s = string;
if( sign )
	*s++ = '-';
else
	*s++ = ' ';
/* Examine number of digits requested by caller. */
if( outformat == 3 )
        ndigs += expon;
/*
else if( ndigs < 0 )
        ndigs = 0;
*/
if( ndigs > NDEC )
	ndigs = NDEC;
if( digit == 10 )
	{
	*s++ = '1';
	*s++ = '.';
	if( ndigs > 0 )
		{
		*s++ = '0';
		ndigs -= 1;
		}
	expon += 1;
	if( ndigs < 0 )
	        {
	        ss = s;
	        goto doexp;
	        }
	}
else
	{
	*s++ = (char )digit + '0';
	*s++ = '.';
	}
/* Generate digits after the decimal point. */
for( k=0; k<=ndigs; k++ )
	{
/* multiply current number by 10, without normalizing */
	eshup1( y );
	emovz( y, u );
	eshup1( u );
	eshup1( u );
	eaddm( u, y );
	eiremain( t, y, ldp );
	*s++ = (char )equot[NI-1] + '0';
	}
digit = equot[NI-1];
--s;
ss = s;
/* round off the ASCII string */
if( digit > 4 )
	{
/* Test for critical rounding case in ASCII output. */
	if( digit == 5 )
		{
		emovo( y, t, ldp );
		if( ecmp(t,ezero) != 0 )
			goto roun;	/* round to nearest */
		if( (*(s-1) & 1) == 0 )
			goto doexp;	/* round to even */
		}
/* Round up and propagate carry-outs */
roun:
	--s;
	k = *s & 0x7f;
/* Carry out to most significant digit? */
	if( ndigs < 0 )
		{
	        /* This will print like "1E-6". */
		*s = '1';
		expon += 1;
		goto doexp;
		}
	else if( k == '.' )
		{
		--s;
		k = *s;
		k += 1;
		*s = (char )k;
/* Most significant digit carries to 10? */
		if( k > '9' )
			{
			expon += 1;
			*s = '1';
			}
		goto doexp;
		}
/* Round up and carry out from less significant digits */
	k += 1;
	*s = (char )k;
	if( k > '9' )
		{
		*s = '0';
		goto roun;
		}
	}
doexp:
#ifdef __GO32__
if( expon >= 0 )
	sprintf( ss, "e+%02d", expon );
else
	sprintf( ss, "e-%02d", -expon );
#else
	sprintf( ss, "E%d", expon );
#endif
bxit:
ldp->rndprc = rndsav;
ldp->outexpon =  expon;
}




/*
;								ASCTOQ
;		ASCTOQ.MAC		LATEST REV: 11 JAN 84
;					SLM, 3 JAN 78
;
;	Convert ASCII string to quadruple precision floating point
;
;		Numeric input is free field decimal number
;		with max of 15 digits with or without 
;		decimal point entered as ASCII from teletype.
;	Entering E after the number followed by a second
;	number causes the second number to be interpreted
;	as a power of 10 to be multiplied by the first number
;	(i.e., "scientific" notation).
;
;	Usage:
;		asctoq( string, q );
*/

void _simdstrtold (char *s, char **se, LONG_DOUBLE_UNION *x)
{
  LDPARMS rnd;
  LDPARMS *ldp = &rnd;
  int lenldstr;

  rnd.rlast = -1;
  rnd.rndprc = NBITS;

  lenldstr = asctoeg( s, (unsigned short *)x, SIMD_LDBL_MANT_DIG, ldp );
  if (se)
    *se = s + lenldstr;
}

#define REASONABLE_LEN 200

static int
asctoeg(char *ss, short unsigned int *y, int oprec, LDPARMS *ldp)
{
unsigned short yy[NI], xt[NI], tt[NI];
int esign, decflg, sgnflg, nexp, exp, prec, lost;
int k, trail, c, rndsav;
long lexp;
unsigned short nsign, *p;
char *sp, *s, *lstr;
int lenldstr;
int mflag = 0;
char tmpstr[REASONABLE_LEN];

/* Copy the input string. */
c = strlen (ss) + 2;
if (c <= REASONABLE_LEN)
  lstr = tmpstr;
else
  {
    lstr = (char *) calloc (c, 1);
    mflag = 1;
  }
s = ss;
lenldstr = 0;
while( *s == ' ' ) /* skip leading spaces */
  {
    ++s;
    ++lenldstr;
  }
sp = lstr;
for( k=0; k<c; k++ )
	{
	if( (*sp++ = *s++) == '\0' )
		break;
	}
*sp = '\0';
s = lstr;

rndsav = ldp->rndprc;
ldp->rndprc = NBITS; /* Set to full precision */
lost = 0;
nsign = 0;
decflg = 0;
sgnflg = 0;
nexp = 0;
exp = 0;
prec = 0;
ecleaz( yy );
trail = 0;

nxtcom:
k = *s - '0';
if( (k >= 0) && (k <= 9) )
	{
/* Ignore leading zeros */
	if( (prec == 0) && (decflg == 0) && (k == 0) )
		goto donchr;
/* Identify and strip trailing zeros after the decimal point. */
	if( (trail == 0) && (decflg != 0) )
		{
		sp = s;
		while( (*sp >= '0') && (*sp <= '9') )
			++sp;
/* Check for syntax error */
		c = *sp & 0x7f;
		if( (c != 'e') && (c != 'E') && (c != '\0')
			&& (c != '\n') && (c != '\r') && (c != ' ')
			&& (c != ',') )
			goto error;
		--sp;
		while( *sp == '0' )
			*sp-- = 'z';
		trail = 1;
		if( *s == 'z' )
			goto donchr;
		}
/* If enough digits were given to more than fill up the yy register,
 * continuing until overflow into the high guard word yy[2]
 * guarantees that there will be a roundoff bit at the top
 * of the low guard word after normalization.
 */
	if( yy[2] == 0 )
		{
		if( decflg )
			nexp += 1; /* count digits after decimal point */
		eshup1( yy );	/* multiply current number by 10 */
		emovz( yy, xt );
		eshup1( xt );
		eshup1( xt );
		eaddm( xt, yy );
		ecleaz( xt );
		xt[NI-2] = (unsigned short )k;
		eaddm( xt, yy );
		}
	else
		{
		/* Mark any lost non-zero digit.  */
		lost |= k;
		/* Count lost digits before the decimal point.  */
		if (decflg == 0)
		        nexp -= 1;
		}
	prec += 1;
	goto donchr;
	}

switch( *s )
	{
	case 'z':
		break;
	case 'E':
	case 'e':
		goto expnt;
	case '.':	/* decimal point */
		if( decflg )
			goto error;
		++decflg;
		break;
	case '-':
		nsign = 0xffff;
		if( sgnflg )
			goto error;
		++sgnflg;
		break;
	case '+':
		if( sgnflg )
			goto error;
		++sgnflg;
		break;
	case ',':
	case ' ':
	case '\0':
	case '\n':
	case '\r':
		goto daldone;
	case 'i':
	case 'I':
		goto infinite;
	default:
	error:
#ifdef NANS
		enan( yy, NI*16 );
#else
		mtherr( "asctoe", DOMAIN );
		ecleaz(yy);
#endif
		goto aexit;
	}
donchr:
++s;
goto nxtcom;

/* Exponent interpretation */
expnt:

esign = 1;
exp = 0;
++s;
/* check for + or - */
if( *s == '-' )
	{
	esign = -1;
	++s;
	}
if( *s == '+' )
	++s;
while( (*s >= '0') && (*s <= '9') )
	{
	exp *= 10;
	exp += *s++ - '0';
	if (exp > 4977)
		{
		if (esign < 0)
			goto zero;
		else
			goto infinite;
		}
	}
if( esign < 0 )
	exp = -exp;
if( exp > 4932 )
	{
infinite:
	ecleaz(yy);
	yy[E] = 0x7fff;  /* infinity */
	goto aexit;
	}
if( exp < -4977 )
	{
zero:
	ecleaz(yy);
	goto aexit;
	}

daldone:
nexp = exp - nexp;
/* Pad trailing zeros to minimize power of 10, per IEEE spec. */
while( (nexp > 0) && (yy[2] == 0) )
	{
	emovz( yy, xt );
	eshup1( xt );
	eshup1( xt );
	eaddm( yy, xt );
	eshup1( xt );
	if( xt[2] != 0 )
		break;
	nexp -= 1;
	emovz( xt, yy );
	}
if( (k = enormlz(yy)) > NBITS )
	{
	ecleaz(yy);
	goto aexit;
	}
lexp = (EXONE - 1 + NBITS) - k;
emdnorm( yy, lost, 0, lexp, 64, ldp );
/* convert to external format */


/* Multiply by 10**nexp.  If precision is 64 bits,
 * the maximum relative error incurred in forming 10**n
 * for 0 <= n <= 324 is 8.2e-20, at 10**180.
 * For 0 <= n <= 999, the peak relative error is 1.4e-19 at 10**947.
 * For 0 >= n >= -999, it is -1.55e-19 at 10**-435.
 */
lexp = yy[E];
if( nexp == 0 )
	{
	k = 0;
	goto expdon;
	}
esign = 1;
if( nexp < 0 )
	{
	nexp = -nexp;
	esign = -1;
	if( nexp > 4096 )
		{ /* Punt.  Can't handle this without 2 divides. */
		emovi( etens[0], tt );
		lexp -= tt[E];
		k = edivm( tt, yy, ldp );
		lexp += EXONE;
		nexp -= 4096;
		}
	}
p = &etens[NTEN][0];
emov( eone, xt );
exp = 1;
do
	{
	if( exp & nexp )
		emul( p, xt, xt, ldp );
	p -= NE;
	exp = exp + exp;
	}
while( exp <= MAXP );

emovi( xt, tt );
if( esign < 0 )
	{
	lexp -= tt[E];
	k = edivm( tt, yy, ldp );
	lexp += EXONE;
	}
else
	{
	lexp += tt[E];
	k = emulm( tt, yy, ldp );
	lexp -= EXONE - 1;
	}

expdon:

/* Round and convert directly to the destination type */
if( oprec == 53 )
	lexp -= EXONE - 0x3ff;
else if( oprec == 24 )
	lexp -= EXONE - 0177;
#ifdef DEC
else if( oprec == 56 )
	lexp -= EXONE - 0201;
#endif
ldp->rndprc = oprec;
emdnorm( yy, k, 0, lexp, 64, ldp );

aexit:

ldp->rndprc = rndsav;
yy[0] = nsign;
switch( oprec )
	{
#ifdef DEC
	case 56:
		todec( yy, y ); /* see etodec.c */
		break;
#endif
#if SIMD_LDBL_MANT_DIG == 53
	case 53:
		toe53( yy, y );
		break;
#elif SIMD_LDBL_MANT_DIG == 24
	case 24:
		toe24( yy, y );
		break;
#elif SIMD_LDBL_MANT_DIG == 64
	case 64:
		toe64( yy, y );
		break;
#elif SIMD_LDBL_MANT_DIG == 113
	case 113:
		toe113( yy, y );
		break;
#else
	case NBITS:
		emovo( yy, y, ldp );
		break;
#endif
	}
lenldstr += s - lstr;
if (mflag)
  free (lstr);
return lenldstr;
}


 
/* y = largest integer not greater than x
 * (truncated toward minus infinity)
 *
 * unsigned short x[NE], y[NE]
 * LDPARMS *ldp
 *
 * efloor( x, y, ldp );
 */
static unsigned short bmask[] = {
0xffff,
0xfffe,
0xfffc,
0xfff8,
0xfff0,
0xffe0,
0xffc0,
0xff80,
0xff00,
0xfe00,
0xfc00,
0xf800,
0xf000,
0xe000,
0xc000,
0x8000,
0x0000,
};

static void efloor(short unsigned int *x, short unsigned int *y, LDPARMS *ldp)
{
register unsigned short *p;
int e, expon, i;
unsigned short f[NE];

emov( x, f ); /* leave in external format */
expon = (int )f[NE-1];
e = (expon & 0x7fff) - (EXONE - 1);
if( e <= 0 )
	{
	eclear(y);
	goto isitneg;
	}
/* number of bits to clear out */
e = NBITS - e;
emov( f, y );
if( e <= 0 )
	return;

p = &y[0];
while( e >= 16 )
	{
	*p++ = 0;
	e -= 16;
	}
/* clear the remaining bits */
*p &= bmask[e];
/* truncate negatives toward minus infinity */
isitneg:

if( (unsigned short )expon & (unsigned short )0x8000 )
	{
	for( i=0; i<NE-1; i++ )
		{
		if( f[i] != y[i] )
			{
			esub( eone, y, y, ldp );
			break;
			}
		}
	}
}



static void eiremain(short unsigned int *den, short unsigned int *num, LDPARMS *ldp)
{
long ld, ln;
unsigned short j;
 unsigned short *equot = ldp->equot;

ld = den[E];
ld -= enormlz( den );
ln = num[E];
ln -= enormlz( num );
ecleaz( equot );
while( ln >= ld )
	{
	if( ecmpm(den,num) <= 0 )
		{
		esubm(den, num);
		j = 1;
		}
	else
		{
		j = 0;
		}
	eshup1(equot);
	equot[NI-1] |= j;
	eshup1(num);
	ln -= 1;
	}
emdnorm( num, 0, 0, ln, 0, ldp );
}

/* NaN bit patterns
 */
#ifdef MIEEE
static unsigned short nan113[8] = {
  0x7fff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff};
static unsigned short nan64[6] = {0x7fff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff};
static unsigned short nan53[4] = {0x7fff, 0xffff, 0xffff, 0xffff};
static unsigned short nan24[2] = {0x7fff, 0xffff};
#else /* !MIEEE */
static unsigned short nan113[8] = {0, 0, 0, 0, 0, 0, 0x8000, 0x7fff};
static unsigned short nan64[6] = {0, 0, 0, 0, 0xc000, 0x7fff};
static unsigned short nan53[4] = {0, 0, 0, 0x7ff8};
static unsigned short nan24[2] = {0, 0x7fc0};
#endif /* !MIEEE */


static void enan (short unsigned int *nan, int size)
{
int i, n;
unsigned short *p;

switch( size )
	{
#ifndef DEC
	case 113:
	n = 8;
	p = nan113;
	break;

	case 64:
	n = 6;
	p = nan64;
	break;

	case 53:
	n = 4;
	p = nan53;
	break;

	case 24:
	n = 2;
	p = nan24;
	break;

	case NBITS:
	for( i=0; i<NE-2; i++ )
		*nan++ = 0;
	*nan++ = 0xc000;
	*nan++ = 0x7fff;
	return;

	case NI*16:
	*nan++ = 0;
	*nan++ = 0x7fff;
	*nan++ = 0;
	*nan++ = 0xc000;
	for( i=4; i<NI; i++ )
		*nan++ = 0;
	return;
#endif
	default:
	mtherr( "enan", DOMAIN );
	return;
	}
for (i=0; i < n; i++)
	*nan++ = *p++;
}

#endif /* __SPE__ */
