/* Support for syscalls for cris*-axis-linux-gnu and simulators
   Copyright (C) 1998-2005 Axis Communications.
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

/* Derived from asm-etrax100/unistd.h with minor modifications to fit as
   LOSS for newlib.  */

#ifndef _ASM_ELINUX_UNISTD_H_
#define _ASM_ELINUX_UNISTD_H_

/* Our callers might want to use link_warning, so provide it from here.  */
#include "../libnosys/config.h"
#include "libnosys/warning.h"

#include <errno.h>

/*
 * This file contains the system call numbers, and stub macros for libc.
 */

#define __NR_setup		  0	/* used only by init, to get system going */
#define __NR_exit		  1
#define __NR_fork		  2
#define __NR_read		  3
#define __NR_write		  4
#define __NR_open		  5
#define __NR_close		  6
#define __NR_waitpid		  7
#define __NR_creat		  8
#define __NR_link		  9
#define __NR_unlink		 10
#define __NR_execve		 11
#define __NR_chdir		 12
#define __NR_time		 13
#define __NR_mknod		 14
#define __NR_chmod		 15
#define __NR_chown		 16
#define __NR_break		 17
#define __NR_oldstat		 18
#define __NR_lseek		 19
#define __NR_getpid		 20
#define __NR_mount		 21
#define __NR_umount		 22
#define __NR_setuid		 23
#define __NR_getuid		 24
#define __NR_stime		 25
#define __NR_ptrace		 26
#define __NR_alarm		 27
#define __NR_oldfstat		 28
#define __NR_pause		 29
#define __NR_utime		 30
#define __NR_stty		 31
#define __NR_gtty		 32
#define __NR_access		 33
#define __NR_nice		 34
#define __NR_ftime		 35
#define __NR_sync		 36
#define __NR_kill		 37
#define __NR_rename		 38
#define __NR_mkdir		 39
#define __NR_rmdir		 40
#define __NR_dup		 41
#define __NR_pipe		 42
#define __NR_times		 43
#define __NR_prof		 44
#define __NR_brk		 45
#define __NR_setgid		 46
#define __NR_getgid		 47
#define __NR_signal		 48
#define __NR_geteuid		 49
#define __NR_getegid		 50
#define __NR_acct		 51
#define __NR_phys		 52
#define __NR_lock		 53
#define __NR_ioctl		 54
#define __NR_fcntl		 55
#define __NR_mpx		 56
#define __NR_setpgid		 57
#define __NR_ulimit		 58
#define __NR_oldolduname	 59
#define __NR_umask		 60
#define __NR_chroot		 61
#define __NR_ustat		 62
#define __NR_dup2		 63
#define __NR_getppid		 64
#define __NR_getpgrp		 65
#define __NR_setsid		 66
#define __NR_sigaction		 67
#define __NR_sgetmask		 68
#define __NR_ssetmask		 69
#define __NR_setreuid		 70
#define __NR_setregid		 71
#define __NR_sigsuspend		 72
#define __NR_sigpending		 73
#define __NR_sethostname	 74
#define __NR_setrlimit		 75
#define __NR_getrlimit		 76
#define __NR_getrusage		 77
#define __NR_gettimeofday	 78
#define __NR_settimeofday	 79
#define __NR_getgroups		 80
#define __NR_setgroups		 81
#define __NR_select		 82
#define __NR_symlink		 83
#define __NR_oldlstat		 84
#define __NR_readlink		 85
#define __NR_uselib		 86
#define __NR_swapon		 87
#define __NR_reboot		 88
#define __NR_readdir		 89
#define __NR_mmap		 90
#define __NR_munmap		 91
#define __NR_truncate		 92
#define __NR_ftruncate		 93
#define __NR_fchmod		 94
#define __NR_fchown		 95
#define __NR_getpriority	 96
#define __NR_setpriority	 97
#define __NR_profil		 98
#define __NR_statfs		 99
#define __NR_fstatfs		100
#define __NR_ioperm		101
#define __NR_socketcall		102
#define __NR_syslog		103
#define __NR_setitimer		104
#define __NR_getitimer		105
#define __NR_stat		106
#define __NR_lstat		107
#define __NR_fstat		108
#define __NR_olduname		109
#define __NR_iopl		110
#define __NR_vhangup		111
#define __NR_idle		112
#define __NR_vm86		113
#define __NR_wait4		114
#define __NR_swapoff		115
#define __NR_sysinfo		116
#define __NR_ipc		117
#define __NR_fsync		118
#define __NR_sigreturn		119
#define __NR_clone		120
#define __NR_setdomainname	121
#define __NR_uname		122
#define __NR_modify_ldt		123
#define __NR_adjtimex		124
#define __NR_mprotect		125
#define __NR_sigprocmask	126
#define __NR_create_module	127
#define __NR_init_module	128
#define __NR_delete_module	129
#define __NR_get_kernel_syms	130
#define __NR_quotactl		131
#define __NR_getpgid		132
#define __NR_fchdir		133
#define __NR_bdflush		134
#define __NR_sysfs		135
#define __NR_personality	136
#define __NR_afs_syscall	137 /* Syscall for Andrew File System */
#define __NR_setfsuid		138
#define __NR_setfsgid		139
#define __NR__llseek		140
#define __NR_getdents		141
#define __NR__newselect		142
#define __NR_flock		143
#define __NR_msync		144
#define __NR_readv		145
#define __NR_writev		146
#define __NR_getsid		147
#define __NR_fdatasync		148
#define __NR__sysctl		149
#define __NR_mlock		150
#define __NR_munlock		151
#define __NR_mlockall		152
#define __NR_munlockall		153
#define __NR_sched_setparam		154
#define __NR_sched_getparam		155
#define __NR_sched_setscheduler		156
#define __NR_sched_getscheduler		157
#define __NR_sched_yield		158
#define __NR_sched_get_priority_max	159
#define __NR_sched_get_priority_min	160
#define __NR_sched_rr_get_interval	161
#define __NR_nanosleep		162
#define __NR_mremap		163

#define __NR_mmap2		192

#define PASTE(x,y) x##y
#define XSTR(x) # x
#define STR(x) XSTR (x)

#ifdef __elinux__
# define CRIS_SYSCALL "jir .$System.call"
# define CALLNO_REG r1
# define ARG5_REG r0
# define MOVE_ARG5 "move.d"
# define COLON_ARG5_CLOBBER : "r0"
#else
# define CRIS_SYSCALL "break 13"
# define CALLNO_REG r9
# define ARG5_REG srp
# define MOVE_ARG5 "move"
# define COLON_ARG5_CLOBBER
#endif

/* XXX - _foo needs to be __foo, while __NR_bar could be _NR_bar. */
#define _syscall0(type,name) \
type PASTE(_Sys_,name) (void) \
{ \
  register long __a __asm__ ("r10"); \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_)); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define _syscall1(type,name,type1,arg1) \
type PASTE(_Sys_,name) (type1 arg1) \
{ \
  register long __a __asm__ ("r10") = (long) arg1; \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_), "0" (__a)); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define _syscall2(type,name,type1,arg1,type2,arg2) \
type PASTE(_Sys_,name) (type1 arg1,type2 arg2) \
{ \
  register long __a __asm__ ("r10") = (long) arg1; \
  register long __b __asm__ ("r11") = (long) arg2; \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_), "0" (__a), "r" (__b)); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define _syscall3(type,name,type1,arg1,type2,arg2,type3,arg3) \
type PASTE(_Sys_,name) (type1 arg1,type2 arg2,type3 arg3) \
{ \
  register long __a __asm__ ("r10") = (long) arg1; \
  register long __b __asm__ ("r11") = (long) arg2; \
  register long __c __asm__ ("r12") = (long) arg3; \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_), "0" (__a), "r" (__b), "r" (__c)); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define _syscall4(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4) \
type PASTE(_Sys_,name) (type1 arg1, type2 arg2, type3 arg3, type4 arg4) \
{ \
  register long __a __asm__ ("r10") = (long) arg1; \
  register long __b __asm__ ("r11") = (long) arg2; \
  register long __c __asm__ ("r12") = (long) arg3; \
  register long __d __asm__ ("r13") = (long) arg4; \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_), "0" (__a), "r" (__b), \
			  "r" (__c), "r" (__d)); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define _syscall5(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4, \
	  type5,arg5) \
type PASTE(_Sys_,name) (type1 arg1,type2 arg2,type3 arg3,type4 arg4,type5 arg5) \
{ \
  register long __a __asm__ ("r10") = (long) arg1; \
  register long __b __asm__ ("r11") = (long) arg2; \
  register long __c __asm__ ("r12") = (long) arg3; \
  register long __d __asm__ ("r13") = (long) arg4; \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (MOVE_ARG5 " %6,$" STR (ARG5_REG) "\n\t" \
			CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_), "0" (__a), "r" (__b), \
			  "r" (__c), "r" (__d), "g" (arg5) \
			COLON_ARG5_CLOBBER); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define _syscall6(type,name,type1,arg1,type2,arg2,type3,arg3,type4,arg4, \
	  type5,arg5,type6,arg6) \
type PASTE(_Sys_,name) (type1 arg1,type2 arg2,type3 arg3,type4 arg4,type5 arg5, type6 arg6) \
{ \
  register long __a __asm__ ("r10") = (long) arg1; \
  register long __b __asm__ ("r11") = (long) arg2; \
  register long __c __asm__ ("r12") = (long) arg3; \
  register long __d __asm__ ("r13") = (long) arg4; \
  register long __n_ __asm__ (STR (CALLNO_REG)) = (__NR_##name); \
  __asm__ __volatile__ (MOVE_ARG5 " %6,$" STR (ARG5_REG) "\n\t" \
			"move %7,$mof\n\t" \
			CRIS_SYSCALL \
			: "=r" (__a) \
			: "r" (__n_), "0" (__a), "r" (__b), \
			  "r" (__c), "r" (__d), "g" (arg5), "g" (arg6) \
			COLON_ARG5_CLOBBER); \
  if (__a >= 0) \
     return (type) __a; \
  errno = -__a; \
  return -1; \
}

#define __NR__exit __NR_exit
static inline _syscall0(int,idle)
static inline _syscall0(int,fork)
static inline _syscall2(int,clone,unsigned long,flags,char *,esp)
static inline _syscall0(int,pause)
static inline _syscall0(int,setup)
static inline _syscall0(int,sync)
static inline _syscall3(int,write,int,fd,const char *,buf,unsigned,count)
static inline _syscall1(int,dup,int,fd)
static inline _syscall3(int,execve,const char *,file,char **,argv,char **,envp)
static inline _syscall3(int,open,const char *,file,int,flag,int,mode)
static inline _syscall1(int,close,int,fd)
static inline _syscall1(int,_exit,int,exitcode)
static inline _syscall1(int,exit,int,exitcode)
static inline _syscall3(int,waitpid,int,pid,int *,wait_stat,int,options)
static inline _syscall3(int,read,int,fd,char *,buf,unsigned,count)
static inline _syscall2(int,socketcall,int,call,unsigned long *,args)
static inline _syscall3(int,ioctl,unsigned int,fd,unsigned int,cmd,unsigned long,arg)
static inline _syscall3(int,fcntl,unsigned int,fd,unsigned int,cmd,unsigned long,arg)
static inline _syscall5(int,mount,const char *,a,const char *,b,const char *,c,unsigned long,rwflag,const void *,data)
static inline _syscall2(int,rename,const char *,a,const char*,b)

#ifndef __elinux__
/* Make sure these are only used where they are supported.  */
static inline _syscall6(int,mmap2,unsigned long, addr, unsigned long, len,
			unsigned long, prot, unsigned long, flags,
			unsigned long, fd, unsigned long, pgoff)
static inline _syscall1(long,brk,long,addr)
#endif

/* This structure is ripped from asm-etrax100/stat.h: beware of updates.  */
struct new_stat {
	unsigned short st_dev;
	unsigned short __pad1;
	unsigned long st_ino;
	unsigned short st_mode;
	unsigned short st_nlink;
	unsigned short st_uid;
	unsigned short st_gid;
	unsigned short st_rdev;
	unsigned short __pad2;
	unsigned long  st_size;
	unsigned long  st_blksize;
	unsigned long  st_blocks;
	unsigned long  st_atime;
	unsigned long  __unused1;
	unsigned long  st_mtime;
	unsigned long  __unused2;
	unsigned long  st_ctime;
	unsigned long  __unused3;
	unsigned long  __unused4;
	unsigned long  __unused5;
};

static inline _syscall2(int,stat,const char *,path,struct new_stat *,statbuf)
static inline _syscall2(int,fstat,int,fd,struct new_stat *,statbuf)
static inline _syscall0(int,getpid)
static inline _syscall2(int,kill,int,pid,int,sig)
static inline _syscall3(int,lseek,int,fd,int,offset,int,whence)
struct tms;
static inline _syscall1(long,times,struct tms *,tbuf)
static inline _syscall1(long,mmap,long *, buf)
struct timeval;
struct timezone;
static inline _syscall2(int,gettimeofday,struct timeval *,tp,
                        void *, tzp)
static inline _syscall2(int,link,const char *,old,const char *,new)
static inline _syscall1(int,unlink,const char *, f)
struct rusage;
static inline _syscall4(int,wait4,int,pid,int *,sa,int,op,struct rusage *,ru)
#endif /* _ASM_ELINUX_UNISTD_H_ */
