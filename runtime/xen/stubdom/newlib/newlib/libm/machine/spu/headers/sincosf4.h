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
#ifndef _SINCOSF4_H_
#define _SINCOSF4_H_	1

#include <spu_intrinsics.h>

#include "cos_sin.h"

/*
 * FUNCTION
 *  vector void _sincosf4(vector float angle, vector float *sx, vector float *cx)
 *
 * DESCRIPTION
 *  The _sincosf4 function computes the sine and cosine of a vector of 
 *	angles (expressed in radians) to an accuracy of a single precision
 *	floating point.
 *
 */

static __inline void _sincosf4(vector float angle, 
                               vector float *sinx, 
                               vector float *cosx)
{

    vec_int4   octant;
    vec_uint4  select;
    vec_float4 cos, sin;
    vec_float4 toggle_sign;

    /* Range reduce the input angle x into the range -PI/4 to PI/4
     * by performing simple modulus.
     */
    MOD_PI_OVER_FOUR_F(angle, octant);

    /* Compute the cosine and sine of the range reduced input.
     */
    COMPUTE_COS_SIN_F(angle, cos, sin);

    select = spu_cmpeq(spu_and(octant, 2), 0);

    toggle_sign = (vec_float4)spu_sl(spu_and(octant, 4), 29);
    *sinx = spu_xor(spu_sel(cos, sin, select), toggle_sign);

    toggle_sign = (vec_float4)spu_sl(spu_and(spu_add(octant, 2), 4), 29);
    *cosx = spu_xor(spu_sel(sin, cos, select), toggle_sign);

    return;
}

#endif /* _SINCOSF4_H_ */
#endif /* __SPU__ */
