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
#ifndef _TANHD2_H_
#define _TANHD2_H_ 1

#include <spu_intrinsics.h>

#include "expd2.h"
#include "divd2.h"


/*
 * Taylor coefficients for tanh
 */
#define TANH_TAY01   1.000000000000000000000000000000E0
#define TANH_TAY02  -3.333333333333333333333333333333E-1
#define TANH_TAY03   1.333333333333333333333333333333E-1
#define TANH_TAY04  -5.396825396825396825396825396825E-2
#define TANH_TAY05   2.186948853615520282186948853616E-2
#define TANH_TAY06  -8.863235529902196568863235529902E-3
#define TANH_TAY07   3.592128036572481016925461369906E-3
#define TANH_TAY08  -1.455834387051318268249485180702E-3
#define TANH_TAY09   5.900274409455859813780759937000E-4
#define TANH_TAY10  -2.391291142435524814857314588851E-4
#define TANH_TAY11   9.691537956929450325595875000389E-5
#define TANH_TAY12  -3.927832388331683405337080809312E-5
#define TANH_TAY13   1.591890506932896474074427981657E-5
#define TANH_TAY14  -6.451689215655430763190842315303E-6
#define TANH_TAY15   2.614771151290754554263594256410E-6
#define TANH_TAY16  -1.059726832010465435091355394125E-6
#define TANH_TAY17   4.294911078273805854820351280397E-7


/*
 * FUNCTION
 *	vector double _tanhd2(vector double x)
 *
 * DESCRIPTION
 *	The _tanhd2 function computes the hyperbolic tangent for each
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
 *  - tanh(NaN) = NaN
 *
 */

static __inline vector double _tanhd2(vector double x)
{
    vector double signbit = spu_splats(-0.0);
    vector double oned    = spu_splats(1.0);
    vector double twod    = spu_splats(2.0);
    vector double infd  = (vector double)spu_splats(0x7FF0000000000000ull);
    vector double xabs;
    vector double x2;
    vector unsigned long long gttaylor;
    vector double e;
    vector double tresult;
    vector double eresult;
    vector double result;

    xabs = spu_andc(x, signbit);

    /*
     * This is where we switch from Taylor Series
     * to exponential formula.
     */
    gttaylor = spu_cmpgt(xabs, spu_splats(0.25));


    /*
     * Taylor Series Approximation
     */
    x2 = spu_mul(x,x);
    tresult = spu_madd(x2, spu_splats(TANH_TAY11), spu_splats(TANH_TAY10));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY09));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY08));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY07));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY06));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY05));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY04));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY03));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY02));
    tresult = spu_madd(x2, tresult, spu_splats(TANH_TAY01));
    tresult = spu_mul(xabs, tresult);


    /*
     * Exponential Formula
     * Our expd2 function gives a more accurate result in general 
     * with xabs instead of x for x<0. We correct for sign later.
     */
    e = _expd2(spu_mul(xabs, twod));
    eresult = _divd2(spu_sub(e, oned), spu_add(e, oned));


    /*
     * Select Taylor or exp result.
     */
    result = spu_sel(tresult, eresult, gttaylor);

    /*
     * Inf and NaN special cases. NaN is already in result
     * for x = NaN.
     */
    result = spu_sel(result, oned, spu_cmpeq(xabs, infd));

    /*
     * Antisymmetric function - preserve sign bit of x
     * in the result.
     */
    result = spu_sel(result, x, (vec_ullong2)signbit);

    return result;
}

#endif /* _TANHD2_H_ */
#endif /* __SPU__ */
