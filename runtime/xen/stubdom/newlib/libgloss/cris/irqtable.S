/* Default interrupt table for CRIS/CRISv32.
   Copyright (C) 2007 Axis Communications.
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
 .section .startup,"ax"
#else
 .text
#endif

#if defined (__ELF__) || defined (IN_CRT0)
; This is included from crt0.S for a.out, as we can't have it as
; a separate object file in a library due to the lack of named
; section support and the required placement at address 3*4.

; We define an interrupt table with references to the symbols
; _.irq_XX where XX are hex numbers 3..ff (lower-case).  They
; are satisfied by weak aliases to the _.irq stub function in
; this file.  When overridden, the overriding function must be
; in code explicitly linked in, i.e. *not* in a library.

 .global __irqtable_at_irq3
__irqtable_at_irq3:

 .irpc irqno,3456789abcdef
 .weak _.irq_0\irqno
 .set _.irq_0\irqno,_.irq
 .dword _.irq_0\irqno
 .endr

 .irpc irqhd,123456789abcdef
 .irpc irqld,0123456789abcdef
 .weak _.irq_\irqhd\irqld
 .set _.irq_\irqhd\irqld,_.irq
 .dword _.irq_\irqhd\irqld
 .endr
 .endr

; No use having a separate file with default _.irq_[0-f][0-f]
; definitions; just provide a single stub with a weak definition
; and make it up to the user to provide a strong definition that
; they force to be linked in (i.e. not in a library or at least
; together with another symbol they know is linked in).
 .text

_.irq:
#ifdef __arch_common_v10_v32
 ; This is just to allow the multilib to compile without
 ; hackery: the "common" subset doesn't recognize
 ; interrupt-return insns.
#elif __CRIS_arch_version >= 32
 rete
 rfe
#else
 reti
 nop
#endif
#endif /* __ELF__ || IN_CRT0 */
