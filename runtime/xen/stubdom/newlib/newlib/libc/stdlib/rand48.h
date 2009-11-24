/*
 * Copyright (c) 1993 Martin Birgmeier
 * All rights reserved.
 *
 * You may redistribute unmodified or modified versions of this source
 * code provided that the above copyright notice and this and the
 * following conditions are retained.
 *
 * This software is provided ``as is'', and comes with no warranties
 * of any kind. I shall in no event be liable for anything that happens
 * to anyone/anything when using this software.
 */

#ifndef _RAND48_H_
#define _RAND48_H_

#include <math.h>
#include <stdlib.h>

extern void _EXFUN(__dorand48,(struct _reent *r, unsigned short[3]));
#define __rand48_seed	_REENT_RAND48_SEED(r)
#define __rand48_mult	_REENT_RAND48_MULT(r)
#define __rand48_add	_REENT_RAND48_ADD(r)

#if 0
/* following values are defined in <sys/reent.h> */
#define        RAND48_SEED_0   (0x330e)
#define        RAND48_SEED_1   (0xabcd)
#define        RAND48_SEED_2   (0x1234)
#define        RAND48_MULT_0   (0xe66d)
#define        RAND48_MULT_1   (0xdeec)
#define        RAND48_MULT_2   (0x0005)
#define        RAND48_ADD      (0x000b)
#endif

#endif /* _RAND48_H_ */
