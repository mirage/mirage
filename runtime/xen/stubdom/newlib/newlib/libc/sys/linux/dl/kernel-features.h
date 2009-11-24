/* Set flags signalling availability of kernel features based on given
   kernel version number.
   Copyright (C) 1999, 2000, 2001 Free Software Foundation, Inc.
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

/* This file must not contain any C code.  At least it must be protected
   to allow using the file also in assembler files.  */

#ifndef __LINUX_KERNEL_VERSION
/* We assume the worst; all kernels should be supported.  */
# define __LINUX_KERNEL_VERSION	0
#endif

/* We assume for __LINUX_KERNEL_VERSION the same encoding used in
   linux/version.h.  I.e., the major, minor, and subminor all get a
   byte with the major number being in the highest byte.  This means
   we can do numeric comparisons.

   In the following we will define certain symbols depending on
   whether the describes kernel feature is available in the kernel
   version given by __LINUX_KERNEL_VERSION.  We are not always exactly
   recording the correct versions in which the features were
   introduced.  If somebody cares these values can afterwards be
   corrected.  Most of the numbers here are set corresponding to
   2.2.0.  */

/* `getcwd' system call.  */
#if __LINUX_KERNEL_VERSION >= 131584
# define __ASSUME_GETCWD_SYSCALL	1
#endif

/* Real-time signal became usable in 2.1.70.  */
#if __LINUX_KERNEL_VERSION >= 131398
# define __ASSUME_REALTIME_SIGNALS	1
#endif

/* When were the `pread'/`pwrite' syscalls introduced?  */
#if __LINUX_KERNEL_VERSION >= 131584
# define __ASSUME_PREAD_SYSCALL		1
# define __ASSUME_PWRITE_SYSCALL	1
#endif

/* When was `poll' introduced?  */
#if __LINUX_KERNEL_VERSION >= 131584
# define __ASSUME_POLL_SYSCALL		1
#endif

/* The `lchown' syscall was introduced in 2.1.80.  */
#if __LINUX_KERNEL_VERSION >= 131408
# define __ASSUME_LCHOWN_SYSCALL	1
#endif

/* When did the `setresuid' sysall became available?  */
#if __LINUX_KERNEL_VERSION >= 131584 && !defined __sparc__
# define __ASSUME_SETRESUID_SYSCALL	1
#endif

/* The SIOCGIFNAME ioctl is available starting with 2.1.50.  */
#if __LINUX_KERNEL_VERSION >= 131408
# define __ASSUME_SIOCGIFNAME		1
#endif

/* On x86 another `getrlimit' syscall was added in 2.3.25.  */
#if __LINUX_KERNEL_VERSION >= 131865 && defined __i386__
# define __ASSUME_NEW_GETRLIMIT_SYSCALL	1
#endif

/* On x86 the truncate64/ftruncate64 syscalls were introduced in 2.3.31.  */
#if __LINUX_KERNEL_VERSION >= 131871 && defined __i386__
# define __ASSUME_TRUNCATE64_SYSCALL	1
#endif

/* On x86 the mmap2 syscall was introduced in 2.3.31.  */
#if __LINUX_KERNEL_VERSION >= 131871 && defined __i386__
# define __ASSUME_MMAP2_SYSCALL	1
#endif

/* On x86 the stat64/lstat64/fstat64 syscalls were introduced in 2.3.34.  */
#if __LINUX_KERNEL_VERSION >= 131874 && defined __i386__
# define __ASSUME_STAT64_SYSCALL	1
#endif

/* On sparc and ARM the truncate64/ftruncate64/mmap2/stat64/lstat64/fstat64
   syscalls were introduced in 2.3.35.  */
#if __LINUX_KERNEL_VERSION >= 131875 && (defined __sparc__ || defined __arm__)
# define __ASSUME_TRUNCATE64_SYSCALL	1
# define __ASSUME_MMAP2_SYSCALL		1
# define __ASSUME_STAT64_SYSCALL	1
#endif

/* I know for sure that these are in 2.3.35 on powerpc.  */
#if __LINUX_KERNEL_VERSION >= 131875 && defined __powerpc__
# define __ASSUME_TRUNCATE64_SYSCALL	1
# define __ASSUME_STAT64_SYSCALL	1
# define __ASSUME_NEW_GETRLIMIT_SYSCALL	1
#endif

/* Linux 2.3.39 introduced 32bit UID/GIDs and IPC64.  Some platforms had 32
   bit type all along.  */
#if __LINUX_KERNEL_VERSION >= 131879 || defined __powerpc__ || defined __mips__
# define __ASSUME_32BITUIDS		1
# ifndef __powerpc__
#  define __ASSUME_IPC64		1
# endif
# ifdef __sparc__
#  define __ASSUME_SETRESUID_SYSCALL	1
# endif
#endif

/* Linux 2.4.0 on PPC introduced a correct IPC64.  */
#if __LINUX_KERNEL_VERSION >= 132096 && defined __powerpc__
# define __ASSUME_IPC64			1
#endif

/* We can use the LDTs for threading with Linux 2.3.99 and newer.  */
#if __LINUX_KERNEL_VERSION >= 131939
# define __ASSUME_LDT_WORKS		1
#endif

/* The changed st_ino field appeared in 2.4.0-test6.  But we cannot
   distinguish this version from other 2.4.0 releases.  Therefore play
   save and assume it available is for 2.4.1 and up.  */
#if __LINUX_KERNEL_VERSION >= 132097
# define __ASSUME_ST_INO_64_BIT		1
#endif

/* To support locking of large files a new fcntl() syscall was introduced
   in 2.4.0-test7.  We test for 2.4.1 for the earliest version we know
   the syscall is available.  */
#if __LINUX_KERNEL_VERSION >= 132097 && (defined __i386__ || defined __sparc__)
# define __ASSUME_FCNTL64		1
#endif

/* Arm got fcntl64 in 2.4.4, PowerPC and SH have it also in 2.4.4 (I
   don't know when it got introduced).  */
#if __LINUX_KERNEL_VERSION >= 132100 \
    && (defined __arm__ || defined __powerpc__ || defined __sh__)
# define __ASSUME_FCNTL64		1
#endif

/* The getdents64 syscall was introduced in 2.4.0-test7.  We test for
   2.4.1 for the earliest version we know the syscall is available.  */
#if __LINUX_KERNEL_VERSION >= 132097
# define __ASSUME_GETDENTS64_SYSCALL	1
#endif

/* When did O_DIRECTORY became available?  Early in 2.3 but when?
   Be safe, use 2.3.99.  */
#if __LINUX_KERNEL_VERSION >= 131939
# define __ASSUME_O_DIRECTORY		1
#endif

/* Starting with one of the 2.4.0 pre-releases the Linux kernel passes
   up the page size information.  */
#if __LINUX_KERNEL_VERSION >= 132097
# define __ASSUME_AT_PAGESIZE		1
#endif

/* Starting with 2.4.5 kernels PPC passes the AUXV in the standard way
   and the mmap2 syscall made it into the official kernel.  */
#if __LINUX_KERNEL_VERSION >= (132096+5) && defined __powerpc__
# define __ASSUME_STD_AUXV		1
# define __ASSUME_MMAP2_SYSCALL		1
#endif

/* There are an infinite number of PA-RISC kernel versions numbered
   2.4.0.  But they've not really been released as such.  We require
   and expect the final version here.  */
#ifdef __hppa__
# define __ASSUME_32BITUIDS		1
# define __ASSUME_TRUNCATE64_SYSCALL	1
# define __ASSUME_MMAP2_SYSCALL		1
# define __ASSUME_STAT64_SYSCALL	1
# define __ASSUME_IPC64			1
# define __ASSUME_ST_INO_64_BIT		1
# define __ASSUME_FCNTL64		1
# define __ASSUME_GETDENTS64_SYSCALL	1
#endif
