/*
  (C) Copyright 2006, 2007
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

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef _SYS_FENV_H
#define _SYS_FENV_H

/*
 * The exception macros are such that the functions to pack/unpack them
 * will map a 32 bit fenv_t from/to the 128 bit fpscr.
 *
 * Suffixes:
 * _SNGL: single precision
 * _DBL:  double precision
 * _N:    element number, no suffix for element 0.
 */

#define FE_OVERFLOW_SNGL	0x08000000
#define FE_UNDERFLOW_SNGL	0x04000000
#define FE_DIFF_SNGL		0x02000000
#define FE_DIVBYZERO_SNGL	0x00000040

#define FE_OVERFLOW_SNGL_1	0x00040000
#define FE_UNDERFLOW_SNGL_1	0x00020000
#define FE_DIFF_SNGL_1		0x00010000
#define FE_DIVBYZERO_SNGL_1	0x00000020

#define FE_OVERFLOW_SNGL_2	0x00000200
#define FE_UNDERFLOW_SNGL_2	0x00000100
#define FE_DIFF_SNGL_2		0x00000080
#define FE_DIVBYZERO_SNGL_2	0x00000010

#define FE_OVERFLOW_SNGL_3	0x00000004
#define FE_UNDERFLOW_SNGL_3	0x00000002
#define FE_DIFF_SNGL_3		0x00000001
#define FE_DIVBYZERO_SNGL_3	0x00000008

#define FE_ALL_EXCEPT_SNGL	(FE_OVERFLOW_SNGL | FE_UNDERFLOW_SNGL \
				| FE_DIFF_SNGL | FE_DIVBYZERO_SNGL)
#define FE_ALL_EXCEPT_SNGL_1	(FE_OVERFLOW_SNGL_1 | FE_UNDERFLOW_SNGL_1 \
				| FE_DIFF_SNGL_1 | FE_DIVBYZERO_SNGL_1)
#define FE_ALL_EXCEPT_SNGL_2	(FE_OVERFLOW_SNGL_2 | FE_UNDERFLOW_SNGL_2 \
				| FE_DIFF_SNGL_2 | FE_DIVBYZERO_SNGL_2)
#define FE_ALL_EXCEPT_SNGL_3	(FE_OVERFLOW_SNGL_3 | FE_UNDERFLOW_SNGL_3 \
				| FE_DIFF_SNGL_3 | FE_DIVBYZERO_SNGL_3)

#define FE_OVERFLOW_DBL		0x01000000
#define FE_UNDERFLOW_DBL	0x00800000
#define FE_INEXACT_DBL		0x00400000
#define FE_INVALID_DBL		0x00200000
#define FE_NC_NAN_DBL 		0x00100000
#define FE_NC_DENORM_DBL	0x00080000

#define FE_OVERFLOW_DBL_1	0x00008000
#define FE_UNDERFLOW_DBL_1	0x00004000
#define FE_INEXACT_DBL_1	0x00002000
#define FE_INVALID_DBL_1	0x00001000
#define FE_NC_NAN_DBL_1 	0x00000800
#define FE_NC_DENORM_DBL_1 	0x00000400

#define FE_ALL_EXCEPT_DBL	(FE_OVERFLOW_DBL | FE_UNDERFLOW_DBL | \
				FE_INEXACT_DBL | FE_INVALID_DBL | \
				FE_NC_NAN_DBL | FE_NC_DENORM_DBL)
#define FE_ALL_EXCEPT_DBL_1	(FE_OVERFLOW_DBL_1 | FE_UNDERFLOW_DBL_1 | \
				FE_INEXACT_DBL_1 | FE_INVALID_DBL_1 | \
				FE_NC_NAN_DBL_1 | FE_NC_DENORM_DBL_1)

#define FE_ALL_EXCEPT	        (FE_ALL_EXCEPT_SNGL | FE_ALL_EXCEPT_SNGL_1 | \
				FE_ALL_EXCEPT_SNGL_2 | FE_ALL_EXCEPT_SNGL_3 | \
				FE_ALL_EXCEPT_DBL | FE_ALL_EXCEPT_DBL_1)

/*
 * Warning: some of these are single and some double precision only,
 * because of the hardware implementation.
 */
#define FE_DIVBYZERO		(FE_DIVBYZERO_SNGL | FE_DIVBYZERO_SNGL_1 | \
				FE_DIVBYZERO_SNGL_2 | FE_DIVBYZERO_SNGL_3)
#define FE_INEXACT		(FE_INEXACT_DBL | FE_INEXACT_DBL_1)
#define FE_INVALID		(FE_INVALID_DBL | FE_INVALID_DBL_1)
#define FE_NC_NAN		(FE_NC_NAN_DBL | FE_NC_NAN_DBL_1)
#define FE_NC_DENORM		(FE_NC_DENORM_DBL | FE_NC_DENORM_DBL_1)

/*
 * __FE_ROUND_ELE_n values are set so that they can easily be used as a
 * mask when setting the fpscr. These tell us whether we are setting the
 * round mode for a specific element (double precision floating point
 * only, so there are only two elements).
 */
#define __FE_ROUND_ELE_0	0xc00
#define __FE_ROUND_ELE_1	0x300

/*
 * The following map directly to round values in the fpscr.
 */
#define __FE_SPU_TONEAREST	0
#define __FE_SPU_TOWARDZERO	1
#define __FE_SPU_UPWARD		2
#define __FE_SPU_DOWNWARD	3

#define FE_TONEAREST	(__FE_ROUND_ELE_0 | (__FE_SPU_TONEAREST << 2))
#define FE_TOWARDZERO	(__FE_ROUND_ELE_0 | (__FE_SPU_TOWARDZERO << 2))
#define FE_UPWARD	(__FE_ROUND_ELE_0 | (__FE_SPU_UPWARD << 2))
#define FE_DOWNWARD	(__FE_ROUND_ELE_0 | (__FE_SPU_DOWNWARD << 2))

#define FE_TONEAREST_1	(__FE_ROUND_ELE_1 | __FE_SPU_TONEAREST)
#define FE_TOWARDZERO_1	(__FE_ROUND_ELE_1 | __FE_SPU_TOWARDZERO)
#define FE_UPWARD_1	(__FE_ROUND_ELE_1 | __FE_SPU_UPWARD)
#define FE_DOWNWARD_1	(__FE_ROUND_ELE_1 | __FE_SPU_DOWNWARD)

typedef unsigned int fexcept_t;
typedef unsigned int fenv_t;

extern const fenv_t __fe_dfl_env;
#define FE_DFL_ENV	(&__fe_dfl_env)

#endif /* fenv.h */
