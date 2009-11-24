/* --------------------------------------------------------------  */
/* (C)Copyright 2006,2007,                                         */
/* International Business Machines Corporation                     */
/* All Rights Reserved.                                            */
/*                                                                 */
/* Redistribution and use in source and binary forms, with or      */
/* without modification, are permitted provided that the           */
/* following conditions are met:                                   */
/*                                                                 */
/* - Redistributions of source code must retain the above copyright*/
/*   notice, this list of conditions and the following disclaimer. */
/*                                                                 */
/* - Redistributions in binary form must reproduce the above       */
/*   copyright notice, this list of conditions and the following   */
/*   disclaimer in the documentation and/or other materials        */
/*   provided with the distribution.                               */
/*                                                                 */
/* - Neither the name of IBM Corporation nor the names of its      */
/*   contributors may be used to endorse or promote products       */
/*   derived from this software without specific prior written     */
/*   permission.                                                   */
/* Redistributions of source code must retain the above copyright  */
/* notice, this list of conditions and the following disclaimer.   */
/*                                                                 */
/* Redistributions in binary form must reproduce the above         */
/* copyright notice, this list of conditions and the following     */
/* disclaimer in the documentation and/or other materials          */
/* provided with the distribution.                                 */
/*                                                                 */
/* Neither the name of IBM Corporation nor the names of its        */
/* contributors may be used to endorse or promote products         */
/* derived from this software without specific prior written       */
/* permission.                                                     */
/*                                                                 */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND          */
/* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,     */
/* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF        */
/* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE        */
/* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR            */
/* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT    */
/* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;    */
/* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)        */
/* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN       */
/* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR    */
/* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  */
/* EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.              */
/* --------------------------------------------------------------  */
/* PROLOG END TAG zYx                                              */
#ifdef __SPU__

#ifndef _HYPOTD2_H_
#define _HYPOTD2_H_	1

#include <spu_intrinsics.h>
#include "sqrtd2.h"

/*
 * FUNCTION
 *       vector double hypotd2(vector double x, vector double y)
 *
 * DESCRIPTION
 *     The function hypotd2 returns a double vector in which each element is 
 *     the square root of the sum of the squares of the corresponding 
 *     elements of x and y. 
 *  
 *     The purpose of this function is to avoid overflow during
 *     intermediate calculations, and therefore it is slower than 
 *     simply calcualting sqrt(x^2 + y^2).
 *  
 *     This function is performed by factoring out the larger of the 2
 *     input exponents and moving this factor outside of the sqrt calculation.
 *     This will minimize the possibility of over/underflow when the square
 *     of the values are calculated. Think of it as normalizing the larger
 *     input to the range [1,2).
 *
 *  Special Cases:
 *	- hypot(x, +/-0)              returns |x|
 *	- hypot(+/- infinity, y)      returns +infinity
 *	- hypot(+/- infinity, NaN)    returns +infinity
 *
 */
static __inline vector double _hypotd2(vector double x, vector double y)
{
    vector unsigned long long emask = spu_splats(0x7FF0000000000000ull);
    vector unsigned long long mmask = spu_splats(0x000FFFFFFFFFFFFFull);
    vector signed   long long bias  = spu_splats(0x3FF0000000000000ll);
    vector double oned = spu_splats(1.0);
    vector double sbit = spu_splats(-0.0);
    vector double inf  = (vector double)spu_splats(0x7FF0000000000000ull);
    vector double max, max_e, max_m;
    vector double min, min_e, min_m;
    vector unsigned long long xgty;
    vector double sum;
    vector double result;

    /* Only need absolute values for this function */
    x = spu_andc(x, sbit);
    y = spu_andc(y, sbit);
    xgty = spu_cmpgt(x,y);

    max  = spu_sel(y,x,xgty);
    min  = spu_sel(x,y,xgty);

    /* Extract the exponents and mantissas */
    max_e = (vec_double2)spu_and((vec_ullong2)max, emask);
    max_m = (vec_double2)spu_and((vec_ullong2)max, mmask);
    min_e = (vec_double2)spu_and((vec_ullong2)min, emask);
    min_m = (vec_double2)spu_and((vec_ullong2)min, mmask);

    /* Factor-out max exponent here by subtracting from min exponent */
    vec_llong2 min_e_int = (vec_llong2)spu_sub((vec_int4)min_e, (vec_int4)max_e);
    min_e = (vec_double2)spu_add((vec_int4)min_e_int, (vec_int4)bias);

    /* If the new min exponent is too small, just set it to 0. It
     * wouldn't contribute to the final result in either case.
     */
    min_e = spu_sel(min_e, sbit, spu_cmpgt(sbit, min_e));

    /* Combine new exponents with original mantissas */
    max = spu_or(oned, max_m);
    min = spu_or(min_e, min_m);

    sum = _sqrtd2(spu_madd(max, max, spu_mul(min, min)));
    sum = spu_mul(max_e, sum);

    /* Special case: x = +/- infinity */
    result = spu_sel(sum, inf, spu_cmpeq(x, inf));

    return result;
}

#endif /* _HYPOTD2_H_ */
#endif /* __SPU__ */
