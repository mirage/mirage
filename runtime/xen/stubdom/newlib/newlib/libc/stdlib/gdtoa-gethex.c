/****************************************************************

The author of this software is David M. Gay.

Copyright (C) 1998 by Lucent Technologies
All Rights Reserved

Permission to use, copy, modify, and distribute this software and
its documentation for any purpose and without fee is hereby
granted, provided that the above copyright notice appear in all
copies and that both that the copyright notice and this
permission notice and warranty disclaimer appear in supporting
documentation, and that the name of Lucent or any of its entities
not be used in advertising or publicity pertaining to
distribution of the software without specific, written prior
permission.

LUCENT DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
IN NO EVENT SHALL LUCENT OR ANY OF ITS ENTITIES BE LIABLE FOR ANY
SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER
IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.

****************************************************************/

/* Please send bug reports to David M. Gay (dmg at acm dot org,
 * with " at " changed at "@" and " dot " changed to ".").	*/

#include <_ansi.h>
#include <reent.h>
#include <string.h>
#include "mprec.h"
#include "gdtoa.h"
#include "gd_qnan.h"

#ifdef USE_LOCALE
#include "locale.h"
#endif

unsigned char hexdig[256];

static void
_DEFUN (htinit, (h, s, inc),
	unsigned char *h _AND
	unsigned char *s _AND
	int inc)
{
	int i, j;
	for(i = 0; (j = s[i]) !=0; i++)
		h[j] = i + inc;
}

void
_DEFUN_VOID (hexdig_init)
{
#define USC (unsigned char *)
	htinit(hexdig, USC "0123456789", 0x10);
	htinit(hexdig, USC "abcdef", 0x10 + 10);
	htinit(hexdig, USC "ABCDEF", 0x10 + 10);
}

static void
_DEFUN(rshift, (b, k),
	_Bigint *b _AND
	int k)
{
	__ULong *x, *x1, *xe, y;
	int n;

	x = x1 = b->_x;
	n = k >> kshift;
	if (n < b->_wds) {
		xe = x + b->_wds;
		x += n;
		if (k &= kmask) {
			n = ULbits - k;
			y = *x++ >> k;
			while(x < xe) {
				*x1++ = (y | (*x << n)) & ALL_ON;
				y = *x++ >> k;
				}
			if ((*x1 = y) !=0)
				x1++;
			}
		else
			while(x < xe)
				*x1++ = *x++;
		}
	if ((b->_wds = x1 - b->_x) == 0)
		b->_x[0] = 0;
}

static _Bigint *
_DEFUN (increment, (ptr, b),
	struct _reent *ptr _AND
	_Bigint *b)
{
	__ULong *x, *xe;
	_Bigint *b1;
#ifdef Pack_16
	__ULong carry = 1, y;
#endif

	x = b->_x;
	xe = x + b->_wds;
#ifdef Pack_32
	do {
		if (*x < (__ULong)0xffffffffL) {
			++*x;
			return b;
			}
		*x++ = 0;
		} while(x < xe);
#else
	do {
		y = *x + carry;
		carry = y >> 16;
		*x++ = y & 0xffff;
		if (!carry)
			return b;
		} while(x < xe);
	if (carry)
#endif
	{
		if (b->_wds >= b->_maxwds) {
			b1 = Balloc(ptr, b->_k+1);
			Bcopy(b1, b);
			Bfree(ptr, b);
			b = b1;
			}
		b->_x[b->_wds++] = 1;
		}
	return b;
}


int
_DEFUN(gethex, (ptr, sp, fpi, exp, bp, sign),
	struct _reent *ptr _AND
	_CONST char **sp _AND
	FPI *fpi _AND
	Long *exp _AND
	_Bigint **bp _AND
	int sign)
{
	_Bigint *b;
	_CONST unsigned char *decpt, *s0, *s, *s1;
	int esign, havedig, irv, k, n, nbits, up, zret;
	__ULong L, lostbits, *x;
	Long e, e1;
#ifdef USE_LOCALE
	unsigned char decimalpoint = *localeconv()->decimal_point;
#else
#define decimalpoint '.'
#endif

	if (!hexdig['0'])
		hexdig_init();
	havedig = 0;
	s0 = *(_CONST unsigned char **)sp + 2;
	while(s0[havedig] == '0')
		havedig++;
	s0 += havedig;
	s = s0;
	decpt = 0;
	zret = 0;
	e = 0;
	if (!hexdig[*s]) {
		zret = 1;
		if (*s != decimalpoint)
			goto pcheck;
		decpt = ++s;
		if (!hexdig[*s])
			goto pcheck;
		while(*s == '0')
			s++;
		if (hexdig[*s])
			zret = 0;
		havedig = 1;
		s0 = s;
		}
	while(hexdig[*s])
		s++;
	if (*s == decimalpoint && !decpt) {
		decpt = ++s;
		while(hexdig[*s])
			s++;
		}
	if (decpt)
		e = -(((Long)(s-decpt)) << 2);
 pcheck:
	s1 = s;
	switch(*s) {
	  case 'p':
	  case 'P':
		esign = 0;
		switch(*++s) {
		  case '-':
			esign = 1;
			/* no break */
		  case '+':
			s++;
		  }
		if ((n = hexdig[*s]) == 0 || n > 0x19) {
			s = s1;
			break;
			}
		e1 = n - 0x10;
		while((n = hexdig[*++s]) !=0 && n <= 0x19)
			e1 = 10*e1 + n - 0x10;
		if (esign)
			e1 = -e1;
		e += e1;
	  }
	*sp = (char*)s;
	if (zret)
		return havedig ? STRTOG_Zero : STRTOG_NoNumber;
	n = s1 - s0 - 1;
	for(k = 0; n > 7; n >>= 1)
		k++;
	b = Balloc(ptr, k);
	x = b->_x;
	n = 0;
	L = 0;
	while(s1 > s0) {
		if (*--s1 == decimalpoint)
			continue;
		if (n == 32) {
			*x++ = L;
			L = 0;
			n = 0;
			}
		L |= (hexdig[*s1] & 0x0f) << n;
		n += 4;
		}
	*x++ = L;
	b->_wds = n = x - b->_x;
	n = 32*n - hi0bits(L);
	nbits = fpi->nbits;
	lostbits = 0;
	x = b->_x;
	if (n > nbits) {
		n -= nbits;
		if (any_on(b,n)) {
			lostbits = 1;
			k = n - 1;
			if (x[k>>kshift] & 1 << (k & kmask)) {
				lostbits = 2;
				if (k > 1 && any_on(b,k-1))
					lostbits = 3;
				}
			}
		rshift(b, n);
		e += n;
		}
	else if (n < nbits) {
		n = nbits - n;
		b = lshift(ptr, b, n);
		e -= n;
		x = b->_x;
		}
	if (e > fpi->emax) {
 ovfl:
		Bfree(ptr, b);
		*bp = 0;
		return STRTOG_Infinite | STRTOG_Overflow | STRTOG_Inexhi;
		}
	irv = STRTOG_Normal;
	if (e < fpi->emin) {
		irv = STRTOG_Denormal;
		n = fpi->emin - e;
		if (n >= nbits) {
			switch (fpi->rounding) {
			  case FPI_Round_near:
				if (n == nbits && (n < 2 || any_on(b,n-1)))
					goto one_bit;
				break;
			  case FPI_Round_up:
				if (!sign)
					goto one_bit;
				break;
			  case FPI_Round_down:
				if (sign) {
 one_bit:
					*exp = fpi->emin;
					x[0] = b->_wds = 1;
					*bp = b;
					return STRTOG_Denormal | STRTOG_Inexhi
						| STRTOG_Underflow;
					}
			  }
			Bfree(ptr, b);
			*bp = 0;
			return STRTOG_Zero | STRTOG_Inexlo | STRTOG_Underflow;
			}
		k = n - 1;
		if (lostbits)
			lostbits = 1;
		else if (k > 0)
			lostbits = any_on(b,k);
		if (x[k>>kshift] & 1 << (k & kmask))
			lostbits |= 2;
		nbits -= n;
		rshift(b,n);
		e = fpi->emin;
		}
	if (lostbits) {
		up = 0;
		switch(fpi->rounding) {
		  case FPI_Round_zero:
			break;
		  case FPI_Round_near:
		    if ((lostbits & 2)
			    && ((lostbits & 1) | (x[0] & 1)))
				up = 1;
			break;
		  case FPI_Round_up:
			up = 1 - sign;
			break;
		  case FPI_Round_down:
			up = sign;
		  }
		if (up) {
			k = b->_wds;
			b = increment(ptr, b);
			x = b->_x;
			if (irv == STRTOG_Denormal) {
				if (nbits == fpi->nbits - 1
				 && x[nbits >> kshift] & 1 << (nbits & kmask))
					irv =  STRTOG_Normal;
				}
			else if ((b->_wds > k)
			 || ((n = nbits & kmask) !=0
			     && (hi0bits(x[k-1]) < 32-n))) {
				rshift(b,1);
				if (++e > fpi->emax)
					goto ovfl;
				}
			irv |= STRTOG_Inexhi;
			}
		else
			irv |= STRTOG_Inexlo;
		}
	*bp = b;
	*exp = e;
	return irv;
}

