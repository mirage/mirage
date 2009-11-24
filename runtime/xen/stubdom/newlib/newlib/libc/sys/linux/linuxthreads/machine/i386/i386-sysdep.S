/* Copyright (C) 1991, 92, 93, 94, 95, 96, 97, 2000 Free Software Foundation, Inc.
   This file has been modified from the GNU C Library.

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

#include <sysdep.h>
#define _ERRNO_H
#include <bits/errno.h>
#include <bp-asm.h>
#include <bp-sym.h>

.globl __syscall_error

__syscall_error:
#if defined (EWOULDBLOCK_sys) && EWOULDBLOCK_sys != EAGAIN
	/* We translate the system's EWOULDBLOCK error into EAGAIN.
	   The GNU C library always defines EWOULDBLOCK==EAGAIN.
	   EWOULDBLOCK_sys is the original number.  */
	cmpl $EWOULDBLOCK_sys, %eax /* Is it the old EWOULDBLOCK?  */
	jne notb		/* Branch if not.  */
	movl $EAGAIN, %eax	/* Yes; translate it to EAGAIN.  */
notb:
#endif
#ifndef	PIC
	pushl %eax
	PUSH_ERRNO_LOCATION_RETURN
	call BP_SYM (__errno)
	POP_ERRNO_LOCATION_RETURN
	popl %ecx
	movl %ecx, (%eax)
#else
	/* The caller has pushed %ebx and then set it up to
	   point to the GOT before calling us through the PLT.  */
	pushl %eax
	PUSH_ERRNO_LOCATION_RETURN
	call C_SYMBOL_NAME (BP_SYM (__errno)@PLT)
	POP_ERRNO_LOCATION_RETURN
	popl %ecx
	/* Pop %ebx value saved before jumping here.  */
	popl %ebx
	movl %ecx, (%eax)
#endif
	movl $-1, %eax
	ret

#undef	__syscall_error
END (__syscall_error)
