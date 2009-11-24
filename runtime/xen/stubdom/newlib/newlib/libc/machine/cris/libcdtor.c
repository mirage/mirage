/* Call ctors and dtors from elinux a.out shared libraries.
   Copyright (C) 1999, 2000, 2003, 2004, 2005 Axis Communications.
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

typedef void (*vfnp) (void);

/* The guts of the _Libctors and _Libdtors is "optimized" away into
   empty functions when the definition is visible as well.  Simplest
   solution is to emit the definitions as asm.  We have no .previous
   directive in a.out, so we rely on the fact that everything in this
   file goes into the .text section.  */
__asm__
(
 ".text\n\t.global .$global.lib.ctors\n.$global.lib.ctors:\n\t.dword 0"
);
__asm__
(
 ".text\n\t.global .$global.lib.dtors\n.$global.lib.dtors:\n\t.dword 0"
);

extern vfnp * const _Ctors asm(".$global.lib.ctors");
extern vfnp * const _Dtors asm(".$global.lib.dtors");

/* We better provide weak empty ctor and dtor lists, since they are
   not created if the main program does not have ctor/dtors.  Because
   it's otherwise not used, GCC trunk "Mon Jul 25 22:33:14 UTC 2005"
   thinks it can remove defaultors, so we need to artificially mark it
   as used.  FIXME: Perhaps a GCC bug.  */

static vfnp const defaultors[] __attribute__ ((__used__)) = {0, 0};

extern vfnp * __CTOR_LIST__ __attribute__ ((weak, alias ("defaultors")));
extern vfnp * __DTOR_LIST__ __attribute__ ((weak, alias ("defaultors")));

void
_Libctors (void)
{
  const vfnp *firstor = _Ctors;
  const vfnp *ctors;

  /* Have to find the last ctor; they will run in opposite order as in
     the table. */
  if (firstor != 0 && *firstor != 0)
    {
      for (ctors = firstor; *ctors != 0; ctors++)
	;

      while (--ctors != firstor)
	{
	  (**ctors)();
	}

      (**ctors)();
    }
}

void
_Libdtors(void)
{
  const vfnp *dtors = _Dtors;

  if (dtors)
    while (*dtors != 0)
      {
	(**dtors++) ();
      }
}
