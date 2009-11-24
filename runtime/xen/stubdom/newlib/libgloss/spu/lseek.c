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

#include <unistd.h>
#include "jsre.h"

#define JSRE_SEEK_SET 0
#define JSRE_SEEK_CUR 1
#define JSRE_SEEK_END 2

typedef struct
{
        unsigned int file;
        unsigned int pad0[3];
        unsigned int offset;
        unsigned int pad1[3];
        unsigned int whence;
        unsigned int pad2[3];
} syscall_lseek_t;

off_t
lseek (int file, off_t offset, int whence)
{
        syscall_lseek_t sys;

	sys.file = file;
	sys.offset = offset;

	switch( whence ){
		case SEEK_SET:
			sys.whence = JSRE_SEEK_SET;
			break;
		case SEEK_CUR:
			sys.whence = JSRE_SEEK_CUR;
			break;
		case SEEK_END:
			sys.whence = JSRE_SEEK_END;
			break;
	}

	return __send_to_ppe (JSRE_POSIX1_SIGNALCODE, JSRE_LSEEK, &sys);
}
