/*
 * Copyright (c) 2003  Red Hat, Inc. All rights reserved.
 *
 * This copyrighted material is made available to anyone wishing to use, modify,
 * copy, or redistribute it subject to the terms and conditions of the BSD 
 * License.  This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY expressed or implied, including the implied 
 * warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy 
 * of this license is available at http://www.opensource.org/licenses. Any 
 * Red Hat trademarks that are incorporated in the source code or documentation
 * are not subject to the BSD License and may only be used or replicated with 
 * the express permission of Red Hat, Inc.
 */
#include "syscall.h"

/* Return ABI: $1 is errno, $0 is return value. */

#define S(n) \
	.global n ; .weak n ; n: ; \
	.2byte 0x7800 | ((SYS_##n & 0xe) << 7) | ((SYS_##n & 1) << 4) ; bra sysret

	.text

#define SYS___mep_write SYS_write
#define SYS___mep_read SYS_read
#define SYS__Sid_config SYS_reconfig

S(open)
S(close)
S(__mep_read)
S(__mep_write)
S(lseek)
S(unlink)
S(getpid)
S(kill)
S(fstat)

/* ARGV support.  */
S(argvlen)
S(argv)

/* These are extras added for one reason or another.  */
S(chdir)
S(stat)
S(chmod)
S(utime)
S(time)
S(gettimeofday)
S(times)
S(link)
S(_Sid_config)

sysret:
	add3	$sp, $sp, -12
	sw	$0, 0($sp)
	sw	$1, 4($sp)
	ldc	$2, $lp
	sw	$2, 8($sp)
	bsr	__errno
	lw	$1, 4($sp)
	sw	$1, ($0)
	lw	$0, 0($sp)
	lw	$2, 8($sp)
	stc	$2, $lp
	add3	$sp, $sp, 12
	ret
