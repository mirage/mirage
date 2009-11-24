/* Executable and DSO init/fini end for cris*-axis-linux-gnu and simulators
   Copyright (C) 2000, 2001, 2004, 2005, 2007 Axis Communications.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Neither the name of Axis Communications nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY AXIS COMMUNICATIONS AND ITS CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL AXIS
   COMMUNICATIONS OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
   IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.  */

#ifdef __ELF__

__asm__ (".syntax no_register_prefix");

__asm__ (".section .init\n"
#ifdef __PIC__
	 "\tmove.d [sp+],r0\n"
#endif
         "\tmove.d [sp+],r9\n"
         "\tjump r9\n"
         "\tsetf\n"

         "\t.section .fini\n"
#ifdef __PIC__
	 "\tmove.d [sp+],r0\n"
#endif
         "\tmove.d [sp+],r9\n"
         "\tjump r9\n"
         "\tsetf\n");

#else
extern int Dummy;
#endif
