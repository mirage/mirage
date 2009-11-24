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
#ifndef _ATAN2F4_H_
#define _ATAN2F4_H_	1

#include <spu_intrinsics.h>

#include "divf4.h"
#include "atanf4.h"

/*
 * FUNCTION
 *  vector float _atan2f4(vector float y, vector float x)
 *
 * DESCRIPTION
 *  The atan2f4 function returns a vector containing the angles
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

static __inline vector float _atan2f4(vector float y, vector float x)
{
    vector float pi   = spu_splats((float)SM_PI);
    vector float zero = spu_splats(0.0f);
    vector unsigned int quad1;
    vector unsigned int quad4;
    vector float result;

    vector unsigned int xlt0;
    vector unsigned int yge0;
    vector unsigned int ylt0;

    xlt0 = (vec_uint4)spu_rlmaska((vec_int4)x, 31);
    ylt0 = (vec_uint4)spu_rlmaska((vec_int4)y, 31);
    yge0 = spu_cmpeq(ylt0, (vec_uint4)zero);

    quad1 = spu_and(ylt0, xlt0);
    quad4 = spu_and(yge0, xlt0);

    result = _atanf4(_divf4(y,x));
    result = spu_sel(result, spu_sub(result, pi), quad1);
    result = spu_sel(result, spu_add(result, pi), quad4);

    return result;
}

#endif /* _ATAN2F4_H_ */
#endif /* __SPU__ */
