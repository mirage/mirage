/*
 * syscalls.c -- provide system call support via trap 31
 *
 * Copyright (c) 1997 Cygnus Support
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
 *
 * Read bytes, using simulator trap 31.
 */

#include <stdlib.h>
#include <time.h>
#include "syscall.h"

extern int *__errno(), errno;

__asm__ (
"	.globl	__syscall					\n\
	.type	__syscall,@function				\n\
__syscall:							\n\
	trap	31		|| nop				\n\
	cmpge	f0,r2,0		-> jmp/tx	link		\n\
	bra	__set_errno					\n\
	.size	__syscall,.-__syscall				\n\
");

int
__set_errno (int new_errno)
{
  errno = new_errno;
  *(__errno)() = errno;
  return -1;
}

void
_exit (int status)
{
  __syscall (status, 0, 0, 0, SYS_exit);
}

int
open (const char *filename, int flags, int mode)
{
  return __syscall (filename, flags, mode, 0, SYS_open);
}

int
close (int filedes)
{
  return __syscall (filedes, 0, 0, 0, SYS_close);
}

int
read (int filedes, void *buffer, size_t length)
{
  return __syscall (filedes, buffer, length, 0, SYS_read);
}

int
write (int filedes, void *buffer, size_t length)
{
  return __syscall (filedes, buffer, length, 0, SYS_write);
}

long
lseek (int filedes, long offset, int whence)
{
  return __syscall (filedes, offset, whence, 0, SYS_lseek);
}

int
unlink (const char *filename)
{
  return __syscall (filename, 0, 0, 0, SYS_unlink);
}

int
getpid (void)
{
  return __syscall (0, 0, 0, 0, SYS_getpid);
}

int
kill (int signal, int pid)
{
  return __syscall (signal, pid, 0, 0, SYS_kill);
}

int
fstat (int filedes, void *info)
{
  return __syscall (filedes, info, 0, 0, SYS_fstat);
}

int
__argvlen (void)
{
  return __syscall (0, 0, 0, 0, SYS_argvlen);
}

int
__argv (void)
{
  return __syscall (0, 0, 0, 0, SYS_argv);
}

int
chdir (char *dir)
{
  return __syscall (dir, 0, 0, 0, SYS_chdir);
}

int
stat (const char *filename, void *info)
{
  return __syscall (filename, info, 0, 0, SYS_stat);
}

int
chmod (const char *filename, int mode)
{
  return __syscall (filename, mode, 0, 0, SYS_chmod);
}

int
utime (const char *filename, void *packet)
{
  return __syscall (filename, packet, 0, 0, SYS_utime);
}

time_t
time (time_t *time_ptr)
{
  time_t result;	
  result = (time_t) __syscall (time_ptr, 0, 0, 0, SYS_time);
  if (time_ptr != NULL)
    *time_ptr = result;
  return result;
}
