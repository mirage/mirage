/* Bounded-pointer definitions for x86 assembler.
   Copyright (C) 2000 Free Software Foundation, Inc.
   Contributed by Greg McGary <greg@mcgary.org>
   This file is part of the GNU C Library.  Its master source is NOT part of
   the C library, however.  The master source lives in the GNU MP Library.

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

#ifndef _bp_asm_h_
# define _bp_asm_h_ 1

# if __ASSEMBLER__

#  if __BOUNDED_POINTERS__

/* Bounded pointers occupy three words.  */
#   define PTR_SIZE 12
/* Bounded pointer return values are passed back through a hidden
   argument that points to caller-allocate space.  The hidden arg
   occupies one word on the stack.  */
#   define RTN_SIZE 4
/* Although the caller pushes the hidden arg, the callee is
   responsible for popping it.  */
#   define RET_PTR ret $RTN_SIZE
/* Maintain frame pointer chain in leaf assembler functions for the benefit
   of debugging stack traces when bounds violations occur.  */
#   define ENTER pushl %ebp; movl %esp, %ebp
#   define LEAVE movl %ebp, %esp; popl %ebp
/* Stack space overhead of procedure-call linkage: return address and
   frame pointer.  */
#   define LINKAGE 8
/* Stack offset of return address after calling ENTER.  */
#   define PCOFF 4

/* Int 5 is the "bound range" exception also raised by the "bound"
   instruction.  */
#   define BOUNDS_VIOLATED int $5

#   define CHECK_BOUNDS_LOW(VAL_REG, BP_MEM)	\
	cmpl 4+BP_MEM, VAL_REG;			\
	jae 0f; /* continue if value >= low */	\
	BOUNDS_VIOLATED;			\
    0:

#   define CHECK_BOUNDS_HIGH(VAL_REG, BP_MEM, Jcc)	\
	cmpl 8+BP_MEM, VAL_REG;				\
	Jcc 0f; /* continue if value < high */		\
	BOUNDS_VIOLATED;				\
    0:

#   define CHECK_BOUNDS_BOTH(VAL_REG, BP_MEM)	\
	cmpl 4+BP_MEM, VAL_REG;			\
	jb 1f; /* die if value < low */		\
    	cmpl 8+BP_MEM, VAL_REG;			\
	jb 0f; /* continue if value < high */	\
    1:	BOUNDS_VIOLATED;			\
    0:

#   define CHECK_BOUNDS_BOTH_WIDE(VAL_REG, BP_MEM, LENGTH)	\
	CHECK_BOUNDS_LOW(VAL_REG, BP_MEM);			\
	addl LENGTH, VAL_REG;					\
    	cmpl 8+BP_MEM, VAL_REG;					\
	jbe 0f; /* continue if value <= high */			\
	BOUNDS_VIOLATED;					\
    0:	subl LENGTH, VAL_REG /* restore value */

/* Take bounds from BP_MEM and affix them to the pointer
   value in %eax, stuffing all into memory at RTN(%esp).
   Use %edx as a scratch register.  */

#   define RETURN_BOUNDED_POINTER(BP_MEM)	\
	movl RTN(%esp), %edx;			\
	movl %eax, 0(%edx);			\
	movl 4+BP_MEM, %eax;			\
	movl %eax, 4(%edx);			\
	movl 8+BP_MEM, %eax;			\
	movl %eax, 8(%edx)

#   define RETURN_NULL_BOUNDED_POINTER		\
	movl RTN(%esp), %edx;			\
	movl %eax, 0(%edx);			\
	movl %eax, 4(%edx);			\
	movl %eax, 8(%edx)

/* The caller of __errno_location is responsible for allocating space
   for the three-word BP return-value and passing pushing its address
   as an implicit first argument.  */
#   define PUSH_ERRNO_LOCATION_RETURN		\
	subl $8, %esp;				\
	subl $4, %esp;				\
	pushl %esp

/* __errno_location is responsible for popping the implicit first
   argument, but we must pop the space for the BP itself.  We also
   dereference the return value in order to dig out the pointer value.  */
#   define POP_ERRNO_LOCATION_RETURN		\
	popl %eax;				\
	addl $8, %esp

#  else /* !__BOUNDED_POINTERS__ */

/* Unbounded pointers occupy one word.  */
#   define PTR_SIZE 4
/* Unbounded pointer return values are passed back in the register %eax.  */
#   define RTN_SIZE 0
/* Use simple return instruction for unbounded pointer values.  */
#   define RET_PTR ret
/* Don't maintain frame pointer chain for leaf assembler functions.  */
#   define ENTER
#   define LEAVE
/* Stack space overhead of procedure-call linkage: return address only.  */
#   define LINKAGE 4
/* Stack offset of return address after calling ENTER.  */
#   define PCOFF 0

#   define CHECK_BOUNDS_LOW(VAL_REG, BP_MEM)
#   define CHECK_BOUNDS_HIGH(VAL_REG, BP_MEM, Jcc)
#   define CHECK_BOUNDS_BOTH(VAL_REG, BP_MEM)
#   define CHECK_BOUNDS_BOTH_WIDE(VAL_REG, BP_MEM, LENGTH)
#   define RETURN_BOUNDED_POINTER(BP_MEM)

#   define RETURN_NULL_BOUNDED_POINTER

#   define PUSH_ERRNO_LOCATION_RETURN
#   define POP_ERRNO_LOCATION_RETURN

#  endif /* !__BOUNDED_POINTERS__ */

# endif /* __ASSEMBLER__ */

#endif /* _bp_asm_h_ */
