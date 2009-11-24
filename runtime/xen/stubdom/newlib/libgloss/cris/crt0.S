/* Generic simplistic start-up-stub for CRIS/CRISv32.
   Copyright (C) 1993-2005, 2007 Axis Communications.
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

#undef cris
#undef L
#ifdef __NO_UNDERSCORES__
#define L(x) x
#else
#define L(x) _ ## x
#endif

; Rudimentary v0..v32-compatible startup stub.

#ifdef __ELF__
 .section .startup,"ax"
#endif
 .global __start
 nop
__start:
 move.d 0f,$r9
 jump $r9
 setf

#ifndef __ELF__

; For a.out, everything read-only and code-wise goes into a
; single section, so we can't separate the interrupt table from
; the startup code if we want to have files in-between.
#define IN_CRT0
#include "irqtable.S"

#else

; The interrupt table (at offset 12, irq #3) is expected here.
; The simplest way to make sure we link it in, is to sacrifice
; some memory and refer to it with a relocation.
 .text
 .dword __irqtable_at_irq3

#endif /* __ELF__ */

0:
 move.d __setup,$r9
 jsr $r9
 nop
#ifdef __ELF__
 jsr L(_init)
 nop
 move.d L(_fini),$r10
 jsr L(atexit)
 nop
#endif
 jsr L(main)
 nop
 jsr L(exit)
 nop
0:
 nop
 ba 0b
 nop
