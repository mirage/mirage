/* Executable and DSO init/fini start for cris*-axis-linux-gnu and simulators
   Copyright (C) 2000, 2001, 2004, 2005 Axis Communications.
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
#ifdef __NO_UNDERSCORES__
         " .globl _init\n"
         "_init:\n"
#else /* not __NO_UNDERSCORES__ */
         " .globl __init\n"
         "__init:\n"
#endif /* not __NO_UNDERSCORES__ */
         "\tsubq 4,sp\n"
	 "\tmove srp,[sp]\n"
#ifdef __PIC__
         "\tsubq 4,sp\n"
	 "\tmove.d r0,[sp]\n"
#if __CRIS_arch_version >= 32
	 "\tlapc _GLOBAL_OFFSET_TABLE_,$r0\n"
#else /* not __CRIS_arch_version >= 32 */
	 "\tmove.d $pc,$r0\n"
	 "\tsub.d .:GOTOFF,$r0\n"
#endif /* not __CRIS_arch_version >= 32 */
#endif /* __PIC__ */

         "\t.section .fini\n"
#ifdef __NO_UNDERSCORES__
         " .globl _fini\n"
         "_fini:\n"
#else /* not __NO_UNDERSCORES__ */
         " .globl __fini\n"
         "__fini:\n"
#endif /* not __NO_UNDERSCORES__ */
         "\tsubq 4,sp\n"
	 "\tmove srp,[sp]\n"
#ifdef __PIC__
         "\tsubq 4,sp\n"
	 "\tmove.d r0,[sp]\n"
#if __CRIS_arch_version >= 32
	 "\tlapc _GLOBAL_OFFSET_TABLE_,$r0\n"
#else /* not __CRIS_arch_version >= 32 */
	 "\tmove.d $pc,$r0\n"
	 "\tsub.d .:GOTOFF,$r0\n"
#endif /* not __CRIS_arch_version >= 32 */
#endif /* __PIC__ */
);

#else /* not __ELF__ */
extern int Dummy;
#endif /* not __ELF__ */
