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
#ifndef _NEXTAFTERF4_H_
#define _NEXTAFTERF4_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *  vector float _nextafterf4(vector float x, vector float y)
 *
 * DESCRIPTION
 *  The nextafterf4 function returns a vector containing the next representable
 *  floating-point number after the element of x, in the direction of the
 *  corresponding element y. 
 *
 *  Special Cases:
 *	- Infinity and NaN are not supported in single-precision on SPU. They are treated
 *	  as normal numbers.
 *	- x != y, and result = 0 is considered an underflow.
 *	  
 *
 */

static __inline vector float _nextafterf4(vector float x, vector float y)
{
    vec_float4 n1ulp = (vec_float4)spu_splats(0x80000001);
    vec_float4 zerof = spu_splats(0.0f);
    vec_int4  one    = spu_splats(1);
    vec_uint4 xlt0, xgty, xeqy, xeq0;
    vec_int4  xint;
    vec_int4  delta, deltap1;
    vec_float4 result;

    /*
     * The idea here is to treat x as a signed int value, which allows us to
     * add or subtact one to/from it to get the next representable value.
     */

    xeq0 = spu_cmpeq(x, zerof);
    xlt0 = spu_cmpgt(zerof, x);
    xeqy = spu_cmpeq(x, y);
    xgty = spu_cmpgt(x, y);

    /* If x = -0.0, set x = 0.0 */
    x = spu_andc(x, (vec_float4)xeq0);

    xint = (vec_int4)x;

    /* Determine value to add to x */
    delta = (vec_int4)spu_xor(xgty, xlt0);
    deltap1 = delta + one;
    delta = spu_sel(deltap1, delta, (vec_uint4)delta);

    xint = xint + delta;

    /* Fix the case of x = 0, and answer should be -1 ulp */
    result = spu_sel((vec_float4)xint, n1ulp, spu_and((vec_uint4)delta, xeq0));

    /* 
     * Special Cases
     */

    /* x = y */
    result = spu_sel(result, y, xeqy);

    return result;

}

#endif /* _NEXTAFTERF4_H_ */
#endif /* __SPU__ */
