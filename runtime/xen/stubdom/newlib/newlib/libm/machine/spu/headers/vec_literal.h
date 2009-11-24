/*
  (C) Copyright 2001,2006,
  International Business Machines Corporation,
  Sony Computer Entertainment, Incorporated,
  Toshiba Corporation,

  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
    * Neither the names of the copyright holders nor the names of their
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
  OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef _VEC_LITERAL_H_
#define _VEC_LITERAL_H_

/* This header files provides an abstraction for the various implementations
 * of vector literal construction. The two formats are:
 *
 * 1) Altivec styled using parenthesis
 * 2) C grammer friendly styled using curly braces
 *
 * The macro, VEC_LITERAL has been developed to provide some portability
 * in these two styles. To achieve true portability, user must specify all
 * elements of the vector being initialized. A single element can be provided
 * but only the first element guarenteed across both construction styles.
 *
 * The VEC_SPLAT_* macros have been provided for portability of vector literal
 * construction when all the elements of the vector contain the same value.
 */

#include <spu_intrinsics.h>

#ifdef __ALTIVEC_LITERAL_STYLE__
/* Use altivec style.
 */
#define VEC_LITERAL(_type, ...)	((_type)(__VA_ARGS__))

#define VEC_SPLAT_U8(_val)	((vector unsigned char)(_val))
#define VEC_SPLAT_S8(_val)	((vector signed char)(_val))

#define VEC_SPLAT_U16(_val)	((vector unsigned short)(_val))
#define VEC_SPLAT_S16(_val)	((vector signed short)(_val))

#define VEC_SPLAT_U32(_val)	((vector unsigned int)(_val))
#define VEC_SPLAT_S32(_val)	((vector signed int)(_val))
#define VEC_SPLAT_F32(_val)	((vector float)(_val))

#define VEC_SPLAT_U64(_val)	((vector unsigned long long)(_val))
#define VEC_SPLAT_S64(_val)	((vector signed long long)(_val))
#define VEC_SPLAT_F64(_val)	((vector double)(_val))

#else
/* Use curly brace style.
 */
#define VEC_LITERAL(_type, ...)	((_type){__VA_ARGS__})

#define VEC_SPLAT_U8(_val)	((vector unsigned char){_val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val})
#define VEC_SPLAT_S8(_val)	((vector signed char){_val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val, _val})

#define VEC_SPLAT_U16(_val)	((vector unsigned short){_val, _val, _val, _val, _val, _val, _val, _val})
#define VEC_SPLAT_S16(_val)	((vector signed short){_val, _val, _val, _val, _val, _val, _val, _val})

#define VEC_SPLAT_U32(_val)	((vector unsigned int){_val, _val, _val, _val})
#define VEC_SPLAT_S32(_val)	((vector signed int){_val, _val, _val, _val})
#define VEC_SPLAT_F32(_val)	((vector float){_val, _val, _val, _val})

#define VEC_SPLAT_U64(_val)	((vector unsigned long long){_val, _val})
#define VEC_SPLAT_S64(_val)	((vector signed long long){_val, _val})
#define VEC_SPLAT_F64(_val)	((vector double){_val, _val})

#endif

#endif /* _VEC_LITERAL_H_ */
