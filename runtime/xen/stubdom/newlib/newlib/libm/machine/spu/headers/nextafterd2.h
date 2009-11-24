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
#ifndef _NEXTAFTERD2_H_
#define _NEXTAFTERD2_H_	1

#include <spu_intrinsics.h>

/*
 * FUNCTION
 *  vector double _nextafterd2(vector double x, vector double y)
 *
 * DESCRIPTION
 *  The nextafterf4 function returns a vector containing the next representable
 *  floating-point number after the element of x, in the direction of the
 *  corresponding element y. 
 *
 *  Special Cases:
 *	- nextafter(NaN, y) = NaN
 *	- nextafter(x, NaN) = NaN
 *	- x = largest finite value, y = infinity, result is undefined
 *	- x = largest finite negative value, y = -infinity, result is undefined
 *	- x != y, and result = 0, considered an underflow
 *
 */

static __inline vector double _nextafterd2(vector double x, vector double y)
{
    vec_double2 n1ulp = (vec_double2)spu_splats(0x8000000000000001ull);
    vec_double2 zerod = spu_splats(0.0);
    vec_llong2  one   = spu_splats(1ll);
    vec_ullong2 xlt0, xgty, xeqy, xeq0;
    vec_llong2  xllong;
    vec_llong2  delta, deltap1;
    vec_double2 result;

    /* Compiler Bug. Replace xtmp/ytmp with x/y when spu_cmpgt(x,y) doesn't change x/y!*/
    volatile vec_double2 xtmp = x;
    volatile vec_double2 ytmp = y;

    /*
     * The idea here is to treat x as a signed long long value, which allows us to
     * add or subtact one to/from it to get the next representable value.
     */

    xeq0 = spu_cmpeq(xtmp, zerod);
    xlt0 = spu_cmpgt(zerod, xtmp);
    xeqy = spu_cmpeq(xtmp, ytmp);
    xgty = spu_cmpgt(xtmp, ytmp);

    /* If x = -0.0, set x = 0.0 */
    x = spu_andc(x, (vec_double2)xeq0);

    xllong = (vec_llong2)x;

    /* Determine value to add to x */
    delta = (vec_llong2)spu_xor(xgty, xlt0);
    deltap1 = delta + one;
    delta = spu_sel(deltap1, delta, (vec_ullong2)delta);

    xllong = xllong + delta;

    /* Fix the case of x = 0, and answer should be -1 ulp */
    result = spu_sel((vec_double2)xllong, n1ulp, spu_and((vec_ullong2)delta, xeq0));

    /* 
     * Special Cases
     */

    /* x = y */
    result = spu_sel(result, y, xeqy);

    return result;
}

#endif /* _NEXTAFTERD2_H_ */
#endif /* __SPU__ */
