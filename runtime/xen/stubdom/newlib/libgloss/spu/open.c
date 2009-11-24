/*
(C) Copyright IBM Corp. 2005, 2006

All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
notice, this list of conditions and the following disclaimer in the 
documentation and/or other materials provided with the distribution.
    * Neither the name of IBM nor the names of its contributors may be 
used to endorse or promote products derived from this software without 
specific prior written permission.

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

Author: Andreas Neukoetter (ti95neuk@de.ibm.com)
*/

#include <stdarg.h>
#include <fcntl.h>
#include "jsre.h"

#define JSRE_O_RDONLY 0
#define JSRE_O_WRONLY 1
#define JSRE_O_RDWR 2

#define JSRE_O_CREAT 64
#define JSRE_O_EXCL 128
#define JSRE_O_NOCTTY 256
#define JSRE_O_TRUNC 512
#define JSRE_O_APPEND 1024
#define JSRE_O_NDELAY 2048
#define JSRE_O_SYNC 4096
#define JSRE_O_ASYNC 8192

typedef struct
{
        unsigned int pathname;
        unsigned int pad0[3];
        unsigned int flags;
        unsigned int pad1[3];
        unsigned int mode;
        unsigned int pad2[3];
} syscall_open_t;

int
open (const char *filename, int flags, ...)
{
        syscall_open_t sys;
        va_list ap;

        sys.pathname = ( unsigned int )filename;

	sys.flags = 0;

	sys.flags |= ( ( flags & O_CREAT ) ? JSRE_O_CREAT : 0 );
	sys.flags |= ( ( flags & O_EXCL ) ? JSRE_O_EXCL : 0 );
	sys.flags |= ( ( flags & O_NOCTTY ) ? JSRE_O_NOCTTY : 0 );
	sys.flags |= ( ( flags & O_TRUNC ) ? JSRE_O_TRUNC : 0 );
	sys.flags |= ( ( flags & O_APPEND ) ? JSRE_O_APPEND : 0 );
//	sys.flags |= ( ( flags & O_NOBLOCK ) ? JSRE_O_NOBLOCK : 0 );
//	sys.flags |= ( ( flags & O_NDELAY ) ? JSRE_O_NDELAY : 0 );
	sys.flags |= ( ( flags & O_SYNC ) ? JSRE_O_SYNC : 0 );
//	sys.flags |= ( ( flags & O_NOFOLLOW ) ? JSRE_O_NOFOLLOW : 0 );
//	sys.flags |= ( ( flags & O_DIRECTORY ) ? JSRE_O_DIRECTORY : 0 );
//	sys.flags |= ( ( flags & O_DIRECT ) ? JSRE_O_DIRECT : 0 );
//	sys.flags |= ( ( flags & O_ASYNC ) ? JSRE_O_ASYNC : 0 );
//	sys.flags |= ( ( flags & O_LARGEFILE ) ? JSRE_O_LARGEFILE : 0 );


	sys.flags |= ( ( flags & O_RDONLY ) ? JSRE_O_RDONLY : 0 );
	sys.flags |= ( ( flags & O_WRONLY ) ? JSRE_O_WRONLY : 0 );
	sys.flags |= ( ( flags & O_RDWR )  ? JSRE_O_RDWR  : 0 );

	/* FIXME: we have to check/map all flags */

        va_start (ap, flags);
        sys.mode = va_arg (ap, int);
        va_end (ap);

        return __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_OPEN, &sys);
}
