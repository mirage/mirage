/*
  Copyright 2007
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
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

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

#include <errno.h>

/*
 * dom_chkf_negone_one: "domain check float negative-one and one":
 *
 * Set errno to EDOM if |x| > 1.0.
 *
 * This is for scalar use only, the input is a vector float, but all
 * values in the vector must be the same.
 *
 * We *only* set errno, and do not bother setting the actual return value
 * of any functions to a NAN. That way, we have the same method for float
 * and single precision (there are no float nans for single precision so
 * those can't return a nan).
 *
 * Note that for newlib, errno is/was a function call, so not so obviously
 * we are not branchless here. Unknown if adding a branch (and avoiding a
 * call to __errno) is faster than this current code.
 */

static __inline void dom_chkf_negone_one (vector float vx)
{
  vector unsigned int domain;
  vector signed int verrno;
  vector float ones = { 1.0, 1.0, 1.0, 1.0 };
  vector signed int fail = { EDOM, EDOM, EDOM, EDOM };

  domain = spu_cmpabsgt(vx, ones);
  verrno = spu_splats(errno);
  /*
   * domain is 4 ints, but they have the same value, even so no special
   * code is needed to extract the scalar errno (we have all ones or all
   * zeroes for the preferred scalar slot).
   */
  errno = spu_extract(spu_sel(verrno, fail, (vector unsigned int) domain), 0);
}
