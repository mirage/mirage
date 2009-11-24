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
#ifndef _ATAN2D2_H_
#define _ATAN2D2_H_	1

#include <spu_intrinsics.h>

#include "divd2.h"
#include "atand2.h"

/*
 * FUNCTION
 *  vector double _atan2d2(vector double y, vector double x)
 *
 * DESCRIPTION
 *  The atan2d2 function returns a vector containing the angles
 *  whose tangets are y/x for the corresponding elements of the
 *  input vectors.
 *
 *  The reason this function exists is to use the signs of the
 *  arguments to determine the quadrant of the result. Consider
 *  sin(x)/cos(x) on the domain (-pi, pi]. Four quadrants are
 *  defined by the signs of sin and cos on this domain.
 *
 *  Special Cases:
 *	- If the corresponding elements of x and y are zero, the 
 *    resulting element is undefined.
 *
 */

static __inline vector double _atan2d2(vector double y, vector double x)
{
    vec_uchar16 dup_even  = ((vec_uchar16) { 0,1,2,3,  0,1,2,3, 8,9,10,11, 8,9,10,11 });
    vector double pi   = spu_splats(SM_PI);
    vector unsigned long long ones = spu_splats(0xFFFFFFFFFFFFFFFFull);
    vector unsigned long long quad1;
    vector unsigned long long quad4;
    vector double result;

    vector unsigned long long xlt0;
    vector unsigned long long yge0;
    vector unsigned long long ylt0;

    xlt0 = (vec_ullong2)spu_rlmaska((vec_int4)spu_shuffle(x,x,dup_even), 31);
    ylt0 = (vec_ullong2)spu_rlmaska((vec_int4)spu_shuffle(y,y,dup_even), 31);
    yge0 = spu_xor(ylt0, ones);

    quad1 = spu_and(ylt0, xlt0);
    quad4 = spu_and(yge0, xlt0);

    result = _atand2(_divd2(y,x));

    result = spu_sel(result, spu_sub(result, pi), quad1);
    result = spu_sel(result, spu_add(result, pi), quad4);

    return result;
}

#endif /* _ATAN2D2_H_ */
#endif /* __SPU__ */
