/* libc/sys/linux/sys/types.h - The usual type zoo */

/* Written 2000 by Werner Almesberger */

/*-
 * Copyright (c) 1982, 1986, 1991, 1993, 1994
 *	The Regents of the University of California.  All rights reserved.
 * (c) UNIX System Laboratories, Inc.
 * All or some portions of this file are derived from material licensed
 * to the University of California by American Telephone and Telegraph
 * Co. or Unix System Laboratories, Inc. and are reproduced herein with
 * the permission of UNIX System Laboratories, Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	@(#)types.h	8.6 (Berkeley) 2/19/95
 * $FreeBSD: src/sys/sys/types.h,v 1.60 2002/04/10 15:58:13 mike Exp $
 */

#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H

/* Newlib has it's own time_t and clock_t definitions in 
 * libc/include/sys/types.h.  Repeat those here and
 * skip the kernel's definitions. */

#include <sys/config.h>
#include <features.h>
#include <machine/types.h>
#include <sys/_types.h>

#if !defined(__time_t_defined) && !defined(_TIME_T)
#define _TIME_T
#define __time_t_defined
typedef _TIME_T_ time_t;
#endif

#if !defined(__clock_t_defined) && !defined(_CLOCK_T)
#define _CLOCK_T
#define __clock_t_defined
typedef _CLOCK_T_ clock_t;
#endif

#ifndef _SSIZE_T
#define _SSIZE_T
typedef _ssize_t ssize_t;
#endif

#ifndef __u_char_defined
#ifdef __GNUC__
__extension__ typedef long long quad_t;
__extension__ typedef unsigned long long u_quad_t;
#else
typedef struct
  {
    long int __val[2];
  } quad_t;
typedef struct
  {
    unsigned long __val[2];
  } u_quad_t;
#endif
typedef struct
  {
    int __val[2];
  } fsid_t;
#define __u_char_defined
#endif

typedef int clockid_t;

#  define _SYS_TYPES_FD_SET
#  define	NBBY	8		/* number of bits in a byte */
/*
 * Select uses bit masks of file descriptors in longs.
 * These macros manipulate such bit fields (the filesystem macros use chars).
 * FD_SETSIZE may be defined by the user, but the default here
 * should be >= NOFILE (param.h).
 */
#  ifndef	FD_SETSIZE
#	define	FD_SETSIZE	64
#  endif

typedef	long	fd_mask;
#  define	NFDBITS	(sizeof (fd_mask) * NBBY)	/* bits per mask */
#  ifndef	howmany
#	define	howmany(x,y)	(((x)+((y)-1))/(y))
#  endif

typedef struct {
        unsigned long fds_bits [(1024/(8 * sizeof(unsigned long)))];
} __fd_set;

#  define	FD_SET(n, p)	((p)->fds_bits[(n)/NFDBITS] |= (1L << ((n) % NFDBITS)))
#  define	FD_CLR(n, p)	((p)->fds_bits[(n)/NFDBITS] &= ~(1L << ((n) % NFDBITS)))
#  define	FD_ISSET(n, p)	((p)->fds_bits[(n)/NFDBITS] & (1L << ((n) % NFDBITS)))
#  define	FD_ZERO(p)	(__extension__ (void)({ \
     size_t __i; \
     char *__tmp = (char *)p; \
     for (__i = 0; __i < sizeof (*(p)); ++__i) \
       *__tmp++ = 0; \
}))

#include <linux/types.h>
#include <bits/types.h>
#define __mode_t_defined
#define __gid_t_defined
#define __uid_t_defined
#define __pid_t_defined
#define __ssize_t_defined
#define __key_t_defined
#define __off_t_defined
#define __off64_t_defined

typedef __ino_t ino_t;
typedef __ino64_t ino64_t;
typedef __uint32_t uintptr_t;
typedef __int32_t intptr_t;
typedef __off64_t off64_t;
typedef __off_t off_t;
typedef __loff_t loff_t;
typedef __mode_t mode_t;
typedef __pid_t pid_t;
typedef __uid_t uid_t;
typedef __gid_t gid_t;
typedef __key_t key_t;
typedef __suseconds_t suseconds_t;
typedef __useconds_t useconds_t;
typedef __daddr_t daddr_t;
typedef __caddr_t caddr_t;
typedef __dev_t dev_t;
typedef __fd_set fd_set;
typedef __nlink_t nlink_t;

typedef __u_char u_char;
typedef __u_short u_short;
typedef __u_int u_int;
typedef __u_long u_long;
typedef __uint8_t u_int8_t;
typedef __uint16_t u_int16_t;
typedef __uint32_t u_int32_t;
typedef __uint64_t u_int64_t;
typedef __int8_t int8_t;
typedef __int16_t int16_t;
typedef __int32_t int32_t;
typedef __int64_t int64_t;

#ifndef _UINT8_T_DECLARED
typedef __uint8_t               uint8_t; 
#define _UINT8_T_DECLARED
#endif

#ifndef _UINT16_T_DECLARED
typedef __uint16_t              uint16_t; 
#define _UINT16_T_DECLARED
#endif

#ifndef _UINT32_T_DECLARED
typedef __uint32_t              uint32_t; 
#define _UINT32_T_DECLARED
#endif

#ifndef _UINT64_T_DECLARED
typedef __uint64_t              uint64_t; 
#define _UINT64_T_DECLARED
#endif

typedef __uint64_t		u64;

#if !defined(_ANSI_SOURCE) && !defined(_POSIX_SOURCE)
typedef	struct _physadr {
	int	r[1];
} *physadr;

typedef	struct label_t {
	int	val[6];
} label_t;
#endif

typedef	unsigned int	vm_offset_t;
typedef	__int64_t	vm_ooffset_t;
typedef	unsigned int	vm_pindex_t;
typedef	unsigned int	vm_size_t;

typedef	__int32_t	register_t;
typedef	__uint32_t	u_register_t;

#ifdef _KERNEL
typedef	int		intfptr_t;
typedef	unsigned int	uintfptr_t;
#endif

/* Critical section value */
typedef	register_t	critical_t;

/* Interrupt mask (spl, xxx_imask, etc) */
typedef	__uint32_t	intrmask_t;

/* Interrupt handler function type. */
typedef	void		ointhand2_t(int _device_id);

#endif
