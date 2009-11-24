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

#ifndef _ATAND2_H_
#define _ATAND2_H_	1

#include <spu_intrinsics.h>

#include "simdmath.h"
#include "recipd2.h"
#include "logd2.h"
#include "acosd2.h"
#include "asind2.h"
#include "sqrtd2.h"

/*
 * FUNCTION
 *	vector double _atand2(vector double x)
 *
 * DESCRIPTION
 *	The _atand2 function computes the arc tangent of a vector of values x.
 *
 *	The arc tangent function is computed using the following relations:
 *	[0, 1]          :  arcsin(x1/sqrt(spu_add(x1squ + 1 )));
 *	(1, infinity]   :  PI/2 + atanf(-1/x)
 *	[-infinity, 0)  :  -arcsin(|x|)
 *
 */

static __inline vector double _atand2(vector double x)
{
    vector double signbit = spu_splats(-0.0);
    vector double oned    = spu_splats(1.0);
    vector double pi2     = spu_splats(SM_PI_2);
    vector double xabs, x1;
    vector double result;
    vector unsigned long long gt1;

    xabs = spu_andc(x, signbit);
    gt1  = spu_cmpgt(xabs, oned);

    /*
     * For x > 1, use the relation:
     * atan(x) = pi/2 - atan(1/x), x>1
     */
    x1 = spu_sel(xabs, _recipd2(xabs), gt1);

    vector double x1squ = spu_mul(x1, x1);

    result = _asind2(_divd2(x1, _sqrtd2(spu_add(x1squ, oned))));

    /*
     * For x > 1, use the relation: atan(x) = pi/2 - atan(1/x), x>1
     */
    result = spu_sel(result, spu_sub(pi2, result), gt1);

    /*
     * Antisymmetric function - preserve sign of x in result.
     */
    result = spu_sel(result, x, (vec_ullong2)signbit);

    return (result);
}

#endif /* _ATAND2_H_ */
#endif /* __SPU__ */
