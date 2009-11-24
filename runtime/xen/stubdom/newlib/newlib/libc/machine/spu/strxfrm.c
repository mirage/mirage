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
#include <spu_intrinsics.h>
#include <stddef.h>
#include <string.h>

#define min(a, b)  (a) < (b) ? (a) : (b)

/* The strxfrm() function transforms the src string into a form such that
 * the result of strcmp() on two strings that have been transformed with
 * strxfrm() is the same as the result of strcoll() on the two strings
 * before their transformation. The first n characters of the transformed
 * string are placed in dest.
 *
 * The strxfrm() function returns the number of bytes required to store
 * the transformed string in dest excluding the terminating character
 * If the value returned is n or more, the contents of dest are indeterminate.
 *
 * Note: Since this library/function only supports a single locale, no
 * transformation is performed.
 */

size_t strxfrm(char * __restrict__ dest, const char * __restrict__ src, size_t n)
{
  size_t len;

  len = strlen(src);
  (void)memcpy((void *)dest, (void *)src, min(n,len + 1));

  return len;
}
