/* profile.h

   Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 
   Permission to use, copy, modify, and distribute this software
   is freely granted, provided that this notice is preserved.  */

#ifndef __XSCALE_PROFILE_H__
#define __XSCALE_PROFILE_H__

/* FIXME:
   We need to create a string version of the CPP predefined
   __USER_LABEL_PREFIX__ macro.  Ideally we would like to
   so do something like:

     #if  __USER_LABEL_PREFIX__ == _

   but this fails for arm-elf targets because although
   __USER_LABEL__PREFIX__ is defined, it is not defined to
   a specific value (even 0) and so the above test fails
   with:
   
      operator '==' has no left operand

  Instead we have to test the CPP predefined __ELF__ and
  rely upon the *assumption* that ELF targets will not use
  an underscore prefix and that COFF targets will.  */

#ifdef __ELF__
#define FOO ""
#else
#define FOO "_"
#endif

#define _MCOUNT_DECL(frompc, selfpc) \
void __attribute__ ((no_instrument_function)) \
mcount_internal (frompc, selfpc)

/* mcount_internal expects two arguments
   r0 frompc (return address for function that call function that calls mcount)
   r1 selfpc (return address for function that called mcount)

   The frompc is extracted from the stack frames. If the code does not
   generate stack frames, then mcount cannot extract this
   information. Thus, the -fomit-frame-pointer optimization cannot be
   used if a call graph information is required.

   Due to optimizations mcount doesn't set up a new fp. mcount has the fp
   of the calling function.

   r0 frompc is from the current frame
   r1 selfpc can be obtained directly from lr.  */

#ifdef __thumb__
#define MCOUNT					\
void __attribute__ ((naked))			\
     __attribute__ ((no_instrument_function))	\
mcount (void)					\
{						\
  __asm__("push {r0, r1, r2, r3, lr};"		\
	  "add r0, r7, #0;"			\
	  "beq 1f;"				\
	  "sub r0, r0, #4;"			\
	  "ldr r0, [r0];"			\
	  "1: mov r1, lr;"			\
	  "bl " FOO "mcount_internal ;"		\
	  "pop {r0, r1, r2, r3, pc};"		\
	);					\
}
#else
#define MCOUNT					\
void __attribute__ ((naked))			\
     __attribute__ ((no_instrument_function))	\
mcount (void)					\
{						\
  __asm__("stmdb sp!, {r0, r1, r2, r3, lr};"	\
	  "movs r0, fp;"			\
	  "ldrne r0, [r0, #-4];"		\
	  "mov r1, lr;"				\
	  "bl " FOO "mcount_internal ;" 	\
          "ldmia sp!, {r0, r1, r2, r3, pc};"	\
	);					\
}
#endif

#define FUNCTION_ALIGNMENT 2

#endif /* !__XSCALE_PROFILE_H__ */
