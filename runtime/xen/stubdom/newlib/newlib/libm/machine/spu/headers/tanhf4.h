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
#ifndef _TANHF4_H_
#define _TANHF4_H_	1

#include <spu_intrinsics.h>

#include "expf4.h"
#include "divf4.h"

#include "tanhd2.h"

/*
 * FUNCTION
 *  vector float _tanhf4(vector float x)
 *
 * DESCRIPTION
 *	The _tanhf4 function computes the hyperbolic tangent for each
 *	element of the input vector. 
 *
 *	We use the following to approximate tanh:
 *
 *	|x| <= .25:   Taylor Series
 *	|x| >  .25:   tanh(x) = (exp(2x) - 1)/(exp(2x) + 1)
 *
 *
 * SPECIAL CASES:
 *  - tanh(+/- 0) = +/-0
 *  - tanh(+/- infinity) = +/- 1
 *
 */

static __inline vector float _tanhf4(vector float x)
{
    vector float signbit = spu_splats(-0.0f);
    vector float onef    = spu_splats(1.0f);
    vector float twof    = spu_splats(2.0f);
    vector float xabs;
    vector float x2;
    vector unsigned int gttaylor;
    vector float e;
    vector float tresult;
    vector float eresult;
    vector float result;

    xabs = spu_andc(x, signbit);

    /*
     * This is where we switch from Taylor Series
     * to exponential formula.
     */
    gttaylor = spu_cmpgt(xabs, spu_splats(0.25f));


    /*
     * Taylor Series Approximation
     */
    x2 = spu_mul(x,x);
    tresult = spu_madd(x2, spu_splats((float)TANH_TAY06), spu_splats((float)TANH_TAY05));
    tresult = spu_madd(x2, tresult, spu_splats((float)TANH_TAY04));
    tresult = spu_madd(x2, tresult, spu_splats((float)TANH_TAY03));
    tresult = spu_madd(x2, tresult, spu_splats((float)TANH_TAY02));
    tresult = spu_madd(x2, tresult, spu_splats((float)TANH_TAY01));
    tresult = spu_mul(xabs, tresult);


    /*
     * Exponential Formula
     * Our expf4 function gives a more accurate result in general 
     * with xabs instead of x for x<0. We correct for sign later.
     */
    e = _expf4(spu_mul(xabs, twof));
    eresult = _divf4(spu_sub(e, onef), spu_add(e, onef));


    /*
     * Select Taylor or exp result.
     */
    result = spu_sel(tresult, eresult, gttaylor);

    /*
     * Correct for accumulated truncation error when 
     * tanh(x) should return 1.
     * Note that this also handles the special case of 
     * x = +/- infinity.
     */
    result = spu_sel(result, onef, spu_cmpgt(xabs, spu_splats(9.125f)));

    /*
     * Antisymmetric function - preserve sign bit of x
     * in the result.
     */
    result = spu_sel(result, x, (vec_uint4)signbit);

    return result;
}

#endif /* _TANHF4_H_ */
#endif /* __SPU__ */
