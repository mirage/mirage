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

/*
 * Put all of the dir functions in one file here, since it is not useful
 * to use opendir without readdir, and then we can put the handling of the
 * struct dirent here too.
 */

#include <stdint.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include "jsre.h"

/*
 * The SPU DIR includes space for one dirent, and is 256 + 4 bytes in
 * size, so keep this small.
 */
#define SPE_OPENDIR_MAX 4

static DIR spe_dir[SPE_OPENDIR_MAX]; /* zero by default */

typedef struct {
  unsigned int name;
  unsigned int pad0[3];
} syscall_opendir_t;

DIR *
opendir (const char *name)
{
  DIR *dir;
  int ppc_dir, i;
  syscall_opendir_t sys;

  sys.name = (unsigned int) name;
  for (i = 0; i < SPE_OPENDIR_MAX; i++) {
    if (!spe_dir[i].ppc_dir) {
      dir = &spe_dir[i];
      __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_OPENDIR, &sys);
      /*
       * Pull 64 bits out of the result.
       */
      dir->ppc_dir = ((uint64_t*)&sys)[0];
      if (!dir->ppc_dir) {
        dir = NULL;
      }
      return dir;
    }
  }

  errno = EMFILE;
  return NULL;
}

int
closedir (DIR *dir)
{
  int rc, i;
  uint64_t ppc_dir;

  if (dir) {
    /*
     * Don't pass &dir->ppc_dir to __send_to_ppe, since it would be
     * overwritten by the assist call.
     */
    ppc_dir = dir->ppc_dir;
    rc = __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_CLOSEDIR, &ppc_dir);

    /*
     * Try to release the dir even if the closedir failed.
     */
    for (i = 0; i < SPE_OPENDIR_MAX; i++) {
      if (spe_dir[i].ppc_dir == dir->ppc_dir) {
        spe_dir[i].ppc_dir = 0;
      }
    }
  } else {
    /*
     * Gracefully handle NULL, but not other invalid dir values.
     */
    rc = -1;
    errno = EBADF;
  }
  return rc;
}

typedef struct {
  uint64_t ppc_dir;
  unsigned int pad0[2];
  unsigned int dirent;
  unsigned int pad1[3];
} syscall_readdir_t;

struct dirent *
readdir (DIR *dir)
{
  syscall_readdir_t sys;

  sys.ppc_dir = dir->ppc_dir;
  sys.dirent = (unsigned int) &dir->dirent;
  return (struct dirent *) __send_to_ppe (JSRE_POSIX1_SIGNALCODE,
                                         JSRE_READDIR, &sys);
}

void
rewinddir (DIR *dir)
{
  uint64_t ppc_dir = dir->ppc_dir;

  __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_REWINDDIR, &ppc_dir);
}

typedef struct {
  uint64_t ppc_dir;
  unsigned int pad0[2];
  unsigned int offset;
  unsigned int pad1[3];
} syscall_seekdir_t;

void
seekdir (DIR *dir, off_t offset)
{
  syscall_seekdir_t sys;

  sys.ppc_dir = dir->ppc_dir;
  sys.offset = offset;
  __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_SEEKDIR, &sys);
}

off_t
telldir (DIR *dir)
{
  uint64_t ppc_dir = dir->ppc_dir;

  __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_TELLDIR, &ppc_dir);
}
