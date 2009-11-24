/* Support for cris*-axis-linux-gnu and src/sim/cris simulator.
   Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 Axis Communications.
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

#include "linunistd.h"

extern void exit (int) __attribute ((__noreturn__));

__asm__ (".syntax no_register_prefix");

#ifdef __ELF__
/* This simulator magic for an earlier simulator was supposed to be
   found two bytes before _start.  Let's keep it for sake of
   compatibility.  Trying to emit them with an ordinary const char[]
   and attribute section makes gcc barf; it doesn't like having the
   same section attribute for both code and data.
   The code is supposed to cause a crash if someone jumps to 0.  */
__asm__
 (
  " .section .startup,\"ax\",@progbits\n"
  " .byte 55,55\n"
  " move.d 0xbadacce5,r9\n"
  " clear.d [r9]\n"
  " setf\n"
  " setf\n"
  " .previous");
#endif

__asm__
 (
#ifdef __AOUT__
  " .text\n\t"
#elif defined (__ELF__)
  " .section .startup,\"ax\",@progbits\n"
#endif
  " .global __start\n"
  "__start:\n"
  /* SP must be set up by the simulator or the system.  */

  /* Find ARGC, ARGV and ENV.  */
  /* ARGC.  */
  " move.d [sp],r10\n"

  /* ARGV.  */
  " move.d sp,r11\n"
  " addq 4,r11\n"

  /* ENVP.  */
  " move.d sp,r12\n"
  " addi r10.d,r12\n"
  " addq 8,r12\n"

  /* Terminate R9 and R6; we don't have a "console_print_etrax" or system
     call function.  */
  " clear.d r9\n"
  " clear.d r6\n"
  " move.d __start1,r13\n"
  " jump r13\n"
  " setf\n"
#ifndef __AOUT__
  /* We rely on a.out not being in .data here.  Quite fragile, but
     covered by e.g. running the GCC test-suite for cris-unknown-aout. */
  " .previous"
#endif
  );

extern void _Libctors (void);
extern void _Libdtors (void);

extern void __init__start (void) __attribute ((weak));
extern void __aout__ctors (void) __attribute ((weak));

static void start1 () __asm__ ("__start1") __attribute ((__used__));
static void
start1 (int argc, char **argv, char **env)
{
#ifdef __ELF__
  /* For ELF systems, we call _init and register _fini with atexit.  */
  {
    extern void _init (void);
    extern void _fini (void);
    _init ();
    if (atexit (_fini) != 0)
      exit (-1);
  }
#else
  /* Constructors which may get here through the ELF .init section, when
     linking ELF and producing a.out.  */
  if (__init__start)
    __init__start ();

  if (__aout__ctors)
    __aout__ctors ();

  /* Call constructors in shared libraries. */
  _Libctors ();

  if (atexit (_Libdtors) != 0)
    exit (-1);
#endif

  /* Call the user program.  */
  exit (main (argc, argv, env));
}
