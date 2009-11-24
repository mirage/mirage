/*
 * Standard x86 syscalls for user programs running under Cygmon
 *
 * Copyright (c) 1998 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

#ifndef CYGMON_SYSCALL_H
#define CYGMON_SYSCALL_H

#define __MAX_ERRNO 4096

#define _syscall0(type,name) \
type name(void) \
{ \
long __res; \
__asm__ __volatile__ ("int $0x80" \
	: "=a" (__res) \
	: "0" (SYS_##name)); \
	return (type) __res; \
}

#define _syscall1(type,name,atype,a) \
type name(atype a) \
{ \
long __res, dummy; \
__asm__ __volatile__ ("int $0x80" \
	: "=a" (__res), "=&b" (dummy) \
	: "0" (SYS_##name),"1" ((long)(a))); \
	return (type) __res; \
}

#define _syscall2(type,name,atype,a,btype,b) \
type name(atype a,btype b) \
{ \
long __res, dummy; \
__asm__ __volatile__ ("int $0x80" \
	: "=a" (__res), "=&b" (dummy) \
	: "0" (SYS_##name),"1" ((long)(a)),"c" ((long)(b))); \
	return (type) __res; \
}

#define _syscall3(type,name,atype,a,btype,b,ctype,c) \
type name(atype a,btype b,ctype c) \
{ \
long __res, dummy; \
__asm__ __volatile__ ("int $0x80" \
	: "=a" (__res), "=&b" (dummy) \
	: "0" (SYS_##name),"1" ((long)(a)),"c" ((long)(b)),"d" ((long)(c))); \
	return (type) __res; \
}

#define _syscall4(type,name,atype,a,btype,b,ctype,c,dtype,d) \
type name (atype a, btype b, ctype c, dtype d) \
{ \
long __res; \
__asm__ __volatile__ ("int $0x80" \
	: "=a" (__res) \
	: "0" (SYS_##name),"b" ((long)(a)),"c" ((long)(b)), \
	  "d" ((long)(c)),"S" ((long)(d))); \
	return (type) __res; \
}

#define _syscall5(type,name,atype,a,btype,b,ctype,c,dtype,d,etype,e) \
type name (atype a,btype b,ctype c,dtype d,etype e) \
{ \
long __res; \
__asm__ __volatile__ ("int $0x80" \
	: "=a" (__res) \
	: "0" (SYS_##name),"b" ((long)(a)),"c" ((long)(b)), \
	  "d" ((long)(c)),"S" ((long)(d)),"D" ((long)(e))); \
	return (type) __res; \
}

#define SYS_putTtyChar 2
#define SYS___sys_exit 1
#define SYS_read 3
#define SYS_write 4
#define SYS___open 5
#define SYS_close 6
#define SYS_kill 37
#define SYS_time 13
#define SYS_gettimeofday 156
#define SYS___install_signal_handler 48
#define SYS_profil 98
#define SYS___get_program_arguments 184
#endif /* SYSCALL_H */
