#ifndef _SYSCALLASM_H_
#define _SYSCALLASM_H_

/*
 * This file defines the system calls for SPARC for the assembler.
 * Anything C-ish is not allowed in this file.
 * C files should include syscall.h.
 */

#include <sys/syscall.h>

/* Some macros for writing assember syscall stubs.  */

#ifdef __svr4__
#define TEXT_SECTION	.section ".text"
#define DATA_SECTION	.section ".data"
#define ALIGN(x)	.align x
#define GLOBAL(sym)	.global sym
#define WORD(x)		.long x
#define ASM_SYMBOL(name) name
#define ASM_PRIVATE_SYMBOL(name) _##name
#define SYSCALL_TRAP	8
#else
#define TEXT_SECTION	.text
#define DATA_SECTION	.data
#define ALIGN(x)	.align x
#define GLOBAL(sym)	.global sym
#define WORD(x)		.word x
#define ASM_SYMBOL(name) _##name
#define ASM_PRIVATE_SYMBOL(name) name
#define SYSCALL_TRAP	0
#endif

#define defsyscall(name, n) \
	TEXT_SECTION ;			\
	ALIGN (4) ;			\
	GLOBAL (ASM_SYMBOL (name)) ;	\
ASM_SYMBOL (name):			\
	mov	n,%g1 ;			\
	ta	%icc,SYSCALL_TRAP ;	\
	bcc	noerr ;			\
	sethi	%hi (ASM_PRIVATE_SYMBOL (cerror)),%g1 ;		\
	or	%g1,%lo (ASM_PRIVATE_SYMBOL (cerror)),%g1 ;	\
	jmpl	%g1+%g0,%g0 ;		\
	nop ;				\
noerr:					\
	jmpl	%o7+8,%g0 ;		\
	nop

/* Support for reentrant syscalls.  The "struct _reent *" arg is always the
   the first one.  After that we allow up to four additional args.  We could
   allow more, but that's all we need for now.

   It may seem inefficient to have the reent arg be the first one as it means
   copying all the other args into place (as opposed to making the reent arg
   the last one in which case there wouldn't be any copying).  I chose a clean
   design over an extra four instructions in a system call.  All other
   reentrant functions use the first arg this way.  */

#define defsyscall_r(name, n) \
	TEXT_SECTION ;			\
	ALIGN (4) ;			\
	GLOBAL (ASM_SYMBOL (name)) ;	\
ASM_SYMBOL (name):			\
	mov	n,%g1 ;			\
	mov	%o0,%o5 ;		\
	mov	%o1,%o0 ;		\
	mov	%o2,%o1 ;		\
	mov	%o3,%o2 ;		\
	mov	%o4,%o3 ;		\
	ta	%icc,SYSCALL_TRAP ;	\
	bcc	noerr ;			\
	sethi	%hi (ASM_PRIVATE_SYMBOL (cerror_r)),%g1 ;	\
	or	%g1,%lo (ASM_PRIVATE_SYMBOL (cerror_r)),%g1 ;	\
	jmpl	%g1+%g0,%g0 ;		\
	mov	%o5,%o1 ;		\
noerr:					\
	jmpl	%o7+8,%g0 ;		\
	nop

#define seterrno() \
	sethi	%hi (ASM_PRIVATE_SYMBOL (cerror)),%g1 ;		\
	or	%g1,%lo (ASM_PRIVATE_SYMBOL (cerror)),%g1 ;	\
	jmpl	%g1+%g0,%g0 ;		\
	nop

#endif /* _SYSCALLASM_H_ */
