/*
   Copyright (C) 2002 Luc Van Oostenryck

   This is free software. You can redistribute and
   modify it under the terms of the GNU General Public
   Public License.
*/

#include <stdlib.h>
#include <stdint.h>

/* Knuth's TAOCP section 3.6 */
#define	M	((1U<<31) -1)
#define	A	48271
#define	Q	44488		// M/A
#define	R	3399		// M%A; R < Q !!!

// FIXME: ISO C/SuS want a longer period

int rand_r(unsigned int* seed)
{   int32_t X;

    X = *seed;
    X = A*(X%Q) - R * (int32_t) (X/Q);
    if (X < 0)
	X += M;

    *seed = X;
    return X;
}
