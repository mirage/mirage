/*
 * redboot-syscalls.c -- provide system call support for RedBoot
 *
 * Copyright (c) 1997, 2001, 2002 Red Hat, Inc.
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
 */

#include <stdlib.h>
#include <sys/stat.h>
#include <sys/times.h>
#include <errno.h>
#include "syscall.h"

// Use "naked" attribute to suppress C prologue/epilogue
static int __attribute__ ((naked)) __syscall(int func_no, ...)
{
    asm ("mov	r12, lr\n");
#ifdef __thumb__
    asm ("swi 0x18\n");
#else
    asm ("swi 0x180001\n");
#endif
    asm ("mov	pc, r12\n");
}

int
_close(int fd)
{
    int  err;
    err = __syscall(SYS_close, fd);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}


void
_exit(int stat)
{
    while (1)
        __syscall(SYS_exit, stat);
}


int
_stat (const char *filename, struct stat *st)
{
    int err;
    err = __syscall(SYS_stat, filename, st);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}

int
_fstat (int file, struct stat *st)
{
    int err;
    err = __syscall(SYS_fstat, file, st);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}

int
_getpid(void)
{
    return 1;
}


int
_gettimeofday (void * tp, void * tzp)
{
    int err;
    err = __syscall(SYS_gettimeofday, tp, tzp);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}


int
isatty(int fd)
{
    int err;
    err = __syscall(SYS_isatty, fd);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}


int
_kill(int pid, int sig)
{
  if(pid == 1)
    _exit(sig);
  return 0;
}


off_t
_lseek(int fd, off_t offset, int whence)
{
    int err;
    err = __syscall(SYS_lseek, fd, offset, whence);
    if (err<0)
      {
        errno = -err;
        return (off_t)-1;
      }
    return err;
}


int
_open(const char *buf, int flags, int mode)
{
    int err ;
    err = __syscall(SYS_open, buf, flags, mode);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}


int
_write(int fd, const char *buf, int nbytes)
{
    int err;

    err = __syscall(SYS_write, fd, buf, nbytes);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}


void
print(char *ptr)
{
  char *p = ptr;

  while (*p != '\0')
    p++;

  _write (1, ptr, p-ptr);
}

void
_raise (void)
{
    return;
}


int
_read(int fd, char *buf, int nbytes)
{
    int err;
    err = __syscall(SYS_read, fd, buf, nbytes);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}


extern char end[];                /* end is set in the linker command file */

char *heap_ptr;

char *
_sbrk (int nbytes)
{
    char        *base;

    if (!heap_ptr)
	heap_ptr = (char *)&end;
    base = heap_ptr;
    heap_ptr += nbytes;

    return base;
}


clock_t
_times(struct tms * tp)
{
    clock_t utime;
    int err;
    err = __syscall(SYS_times, &utime);
    if (err)
	utime = 0;

    if (tp) {
	tp->tms_utime = utime;
	tp->tms_stime = 0;
	tp->tms_cutime = 0;
	tp->tms_cstime = 0;
    }

    return utime;
}

int
_rename (const char *oldpath, const char *newpath)
{
    int err ;
    err = __syscall(SYS_rename, oldpath, newpath);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}

int
_unlink (const char *pathname)
{
    int err ;
    err = __syscall(SYS_unlink, pathname);
    if (err<0)
      {
        errno = -err;
        return -1;
      }
    return err;
}

int
_system (const char *command)
{
    int err ;
    err = __syscall(SYS_system, command);
    return err;
}

#define SYS_meminfo     1001

void *
__get_memtop(void)
{
  unsigned long totmem = 0, topmem = 0;
  int numbanks;

  __syscall(SYS_meminfo, (unsigned long)&totmem, (unsigned long)&topmem, 0);
  return (void*)topmem;
}
