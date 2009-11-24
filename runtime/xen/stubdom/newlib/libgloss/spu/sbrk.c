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

#include <sys/types.h>
#include <errno.h>
#include <spu_intrinsics.h>

extern int errno;

extern caddr_t  _end;
#define STACKSIZE 4096

void *
sbrk (ptrdiff_t increment)
{
	static caddr_t heap_ptr = NULL;
	caddr_t base;
	vector unsigned int sp_reg, sp_delta;
	vector unsigned int *sp_ptr;
	caddr_t sps;

	/* The stack pointer register.  */
	volatile register vector unsigned int sp_r1 __asm__("1");
	
	if (heap_ptr == NULL)
	  heap_ptr = (caddr_t) & _end;
	
	sps = (caddr_t) spu_extract (sp_r1, 0);
	if (((int) sps - STACKSIZE - (int) heap_ptr) >= increment)
	  {
	    base = heap_ptr;
	    heap_ptr += increment;
	    
	    sp_delta = (vector unsigned int) spu_insert (increment, spu_splats (0), 1);

	    /* Subtract sp_delta from the SP limit (word 1).  */
	    sp_r1 = spu_sub (sp_r1, sp_delta);
	    
	    /* Fix-up backchain.  */
	    sp_ptr = (vector unsigned int *) spu_extract (sp_r1, 0);
	    do
	      {
		sp_reg = *sp_ptr;
		*sp_ptr = (vector unsigned int) spu_sub (sp_reg, sp_delta);
	      }
	    while ((sp_ptr = (vector unsigned int *) spu_extract (sp_reg, 0)));

	    return (base);
	  }
	else
	  {
	    errno = ENOMEM;
	    return ((void *) -1);
	  }
}
