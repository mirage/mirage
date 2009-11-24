/* Assembler macros for i386.
   Copyright (C) 1991, 92, 93, 95, 96, 98 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#define NO_UNDERSCORES

#include <generic-sysdep.h>

#ifdef	__ASSEMBLER__

/* Syntactic details of assembler.  */

#ifdef HAVE_ELF

/* ELF uses byte-counts for .align, most others use log2 of count of bytes.  */
#define ALIGNARG(log2) 1<<log2
/* For ELF we need the `.type' directive to make shared libs work right.  */
#define ASM_TYPE_DIRECTIVE(name,typearg) .type name,typearg;
#define ASM_SIZE_DIRECTIVE(name) .size name,.-name;

/* In ELF C symbols are asm symbols.  */
#undef	NO_UNDERSCORES
#define NO_UNDERSCORES

#else

#define ALIGNARG(log2) log2
#define ASM_TYPE_DIRECTIVE(name,type)	/* Nothing is specified.  */
#define ASM_SIZE_DIRECTIVE(name)	/* Nothing is specified.  */

#endif


/* Define an entry point visible from C.

   There is currently a bug in gdb which prevents us from specifying
   incomplete stabs information.  Fake some entries here which specify
   the current source file.  */
#define	ENTRY(name)							      \
  STABS_CURRENT_FILE1("")						      \
  STABS_CURRENT_FILE(name)						      \
  ASM_GLOBAL_DIRECTIVE C_SYMBOL_NAME(name);				      \
  ASM_TYPE_DIRECTIVE (C_SYMBOL_NAME(name),@function)			      \
  .align ALIGNARG(4);							      \
  STABS_FUN(name)							      \
  C_LABEL(name)								      \
  CALL_MCOUNT

#undef	END
#define END(name)							      \
  ASM_SIZE_DIRECTIVE(name)						      \
  STABS_FUN_END(name)

/* Remove the following two lines once the gdb bug is fixed.  */
#define STABS_CURRENT_FILE(name)					      \
  STABS_CURRENT_FILE1 (#name)
#define STABS_CURRENT_FILE1(name)					      \
  1: .stabs name,100,0,0,1b;
/* Emit stabs definition lines.  We use F(0,1) and define t(0,1) as `int',
   the same way gcc does it.  */
#define STABS_FUN(name) STABS_FUN2(name, name##:F(0,1))
#define STABS_FUN2(name, namestr)					      \
  .stabs "int:t(0,1)=r(0,1);-2147483648;2147483647;",128,0,0,0;		      \
  .stabs #namestr,36,0,0,name;
#define STABS_FUN_END(name)						      \
  1: .stabs "",36,0,0,1b-name;

/* If compiled for profiling, call `mcount' at the start of each function.  */
#ifdef	PROF
/* The mcount code relies on a normal frame pointer being on the stack
   to locate our caller, so push one just for its benefit.  */
#define CALL_MCOUNT \
  pushl %ebp; movl %esp, %ebp; call JUMPTARGET(mcount); popl %ebp;
#else
#define CALL_MCOUNT		/* Do nothing.  */
#endif

#ifdef	NO_UNDERSCORES
/* Since C identifiers are not normally prefixed with an underscore
   on this system, the asm identifier `syscall_error' intrudes on the
   C name space.  Make sure we use an innocuous name.  */
#define	syscall_error	__syscall_error
#define mcount		_mcount
#endif

#define	PSEUDO(name, syscall_name, args)				      \
lose: SYSCALL_PIC_SETUP							      \
  jmp JUMPTARGET(syscall_error)						      \
  .globl syscall_error;							      \
  ENTRY (name)								      \
  DO_CALL (syscall_name, args);						      \
  jb lose

#undef	PSEUDO_END
#define	PSEUDO_END(name)						      \
  END (name)

#ifdef PIC
#define JUMPTARGET(name)	name##@PLT
#define SYSCALL_PIC_SETUP \
    pushl %ebx;								      \
    call 0f;								      \
0:  popl %ebx;								      \
    addl $_GLOBAL_OFFSET_TABLE+[.-0b], %ebx;
#else
#define JUMPTARGET(name)	name
#define SYSCALL_PIC_SETUP	/* Nothing.  */
#endif

/* Local label name for asm code. */
#ifndef L
#define L(name)		name
#endif

#endif	/* __ASSEMBLER__ */
