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

#include <unistd.h>
#include "jsre.h"

typedef struct
{
  unsigned int path;
  unsigned int pad0[3];
  unsigned int buf;
  unsigned int pad1[3];
  unsigned int bufsiz;
  unsigned int pad2[3];
} syscall_readlink_t;

/*
 * POSIX says readlink returns ssize_t, and has an size_t bufsiz, but
 * newlib has it prototyped as returning int, and int bufsiz. ssize_t,
 * size_t and int are ally currently 4 bytes for SPU, so just leave them
 * as ints for now.
 */
int
readlink (const char *path, char *buf, int bufsiz)
{
  syscall_readlink_t sys;

  sys.path = (unsigned int) path;
  sys.buf = (unsigned int) buf;
  sys.bufsiz = (unsigned int) bufsiz;
  return __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_READLINK, &sys);
}
