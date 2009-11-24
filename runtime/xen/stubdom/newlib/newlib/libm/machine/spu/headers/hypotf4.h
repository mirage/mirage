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
#ifndef _HYPOTF4_H_
#define _HYPOTF4_H_	1

#include <spu_intrinsics.h>

#include "sqrtf4.h"

/*
 * FUNCTION
 *  vector float _hypotf4(vector float x, vector float y)
 *
 * DESCRIPTION
 *     The function hypotf4 returns a float vector in which each element is 
 *     the square root of the sum of the squares of the corresponding 
 *     elements of x and y. In other words, each element is sqrt(x^2 + y^2).
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
 *
 *  Special Cases:
 *	- hypot(x, +/-0)              returns |x|
 *	- hypot(+/- infinity, y)      returns +infinity
 *	- hypot(+/- infinity, NaN)    returns +infinity
 *
 */


static __inline vector float _hypotf4(vector float x, vector float y)
{
    vector unsigned int emask = spu_splats(0x7F800000u);
    vector unsigned int mmask = spu_splats(0x007FFFFFu);
    vector signed int bias  = spu_splats(0x3F800000);
    vector float inf  = (vec_float4)spu_splats(0x7F800000);
    vector float onef = spu_splats(1.0f);
    vector float sbit = spu_splats(-0.0f);
    vector float max, max_e, max_m;
    vector float min, min_e, min_m;
    vector unsigned int xgty;
    vector float sum;
    vector float result;

    /* Only need absolute values for this function */
    x = spu_andc(x, sbit);
    y = spu_andc(y, sbit);
    xgty = spu_cmpgt(x,y);

    max  = spu_sel(y,x,xgty);
    min  = spu_sel(x,y,xgty);

    /* Extract exponents and mantissas */
    max_e = (vec_float4)spu_and((vec_uint4)max, emask);
    max_m = (vec_float4)spu_and((vec_uint4)max, mmask);
    min_e = (vec_float4)spu_and((vec_uint4)min, emask);
    min_m = (vec_float4)spu_and((vec_uint4)min, mmask);

    /* Adjust the exponent of the smaller of the 2 input values by
     * subtracting max_exp from min_exp. 
     */
    vec_int4 min_e_int = spu_sub((vec_int4)min_e, (vec_int4)max_e);
    min_e = (vec_float4)spu_add(min_e_int, bias);

    /* If the new min exponent is too small, just set it to 0. It
     * wouldn't contribute to the final result in either case.
     */
    min_e = spu_sel(min_e, sbit, spu_cmpgt(sbit, min_e));

    /* Combine new exponents with original mantissas */
    max = spu_or(onef, max_m);
    min = spu_or(min_e, min_m);

    sum = _sqrtf4(spu_madd(max, max, spu_mul(min, min)));
    sum = spu_mul(max_e, sum);

    /* Special case: x = +/- infinity */
    result = spu_sel(sum, inf, spu_cmpeq(x, inf));

    return result;
}

#endif /* _HYPOTF4_H_ */
#endif /* __SPU__ */
