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

#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include "jsre.h"

#define ALLOC_BASE  64
#define ALLOC_INCR  64

typedef struct
{
  unsigned int buf;
  unsigned int pad0[3];
  unsigned int size;
  unsigned int pad1[3];
} syscall_getcwd_t;

char *
getcwd (char *buf, size_t size)
{
  syscall_getcwd_t sys;
  int retry_alloc, local_alloc;
  char *newbuf;
  char *res;

  /*
   * Do not let the ppu side allocate memory, since it has to be used on
   * the SPU (must be in LS), and it can't easily be freed on the spu
   * side. So check for NULL buf, handle allocations here, and only call
   * the assist call with a non-NULL buf.
   */
  retry_alloc = 0;
  local_alloc = 0;
  if (!buf) {
    local_alloc = 1;
    if (size == 0) {
      retry_alloc = 1;
      size = ALLOC_BASE;
    }
    buf = malloc (size);
    if (!buf) {
      /*
       * Leave errno as set by malloc.
       */
      return NULL;
    }
  }

  /*
   * Let the assist call check for error cases, specifically let it handle
   * non-NULL buf and size of zero.
   */

  sys.buf = (unsigned int) buf;
  sys.size = (unsigned int) size;
  res = (char*) __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_GETCWD, &sys);

  while (!res && retry_alloc && errno == ERANGE) {
    size += ALLOC_INCR;
    newbuf = realloc (buf, size);
    if (!newbuf) {
      free (buf);
      return NULL;
    }
    buf = newbuf;

    sys.buf = (unsigned int) buf;
    sys.size = (unsigned int) size;
    res = (char*) __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_GETCWD, &sys);
  }

  if (!res && local_alloc) {
    free (buf);
  }

  return res;
}
