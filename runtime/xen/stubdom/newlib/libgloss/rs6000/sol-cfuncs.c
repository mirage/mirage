/*
 * solaris-cfuncs.S -- C functions for Solaris.
 *
 * Copyright (c) 1996 Cygnus Support
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

#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/unistd.h>

#ifndef __STDC__
#define const
#endif

/* Solaris stat packet */
typedef	long		solaris_off_t;
typedef	long		solaris_uid_t;
typedef	long		solaris_gid_t;
typedef	long unsigned	solaris_mode_t;
typedef	long unsigned	solaris_nlink_t;
typedef long unsigned	solaris_dev_t;
typedef long unsigned	solaris_ino_t;
typedef long		solaris_time_t;

typedef struct {
  solaris_time_t	tv_sec;
  long			tv_nsec;
} solaris_timestruc_t;

#define	_ST_FSTYPSZ 16

struct solaris_stat {
  solaris_dev_t		st_dev;
  long			st_pad1[3];
  solaris_ino_t		st_ino;
  solaris_mode_t	st_mode;
  solaris_nlink_t	st_nlink;
  solaris_uid_t 	st_uid;
  solaris_gid_t 	st_gid;
  solaris_dev_t		st_rdev;
  long			st_pad2[2];
  solaris_off_t		st_size;
  long			st_pad3;
  solaris_timestruc_t	st_atim;
  solaris_timestruc_t	st_mtim;
  solaris_timestruc_t	st_ctim;
  long			st_blksize;
  long			st_blocks;
  char			st_fstype[_ST_FSTYPSZ];
  long			st_pad4[8];
};

/* Solaris termios packet */
#define	SOLARIS_NCCS	19
typedef unsigned long solaris_tcflag_t;
typedef unsigned char solaris_cc_t;
typedef unsigned long solaris_speed_t;

struct solaris_termios {
  solaris_tcflag_t	c_iflag;
  solaris_tcflag_t	c_oflag;
  solaris_tcflag_t	c_cflag;
  solaris_tcflag_t	c_lflag;
  solaris_cc_t		c_cc[SOLARIS_NCCS];
};

#define	SOLARIS_TIOC	('T'<<8)
#define	SOLARIS_TCGETS	(SOLARIS_TIOC|13)



/* Debug support */
#ifdef DEBUG
#define TRACE(msg) trace (msg)
#define TRACE1(msg,num) trace1 (msg,(unsigned)num)

static void
trace (msg)
     const char *msg;
{
  const char *p;

  for (p = msg; *p != '\0'; p++)
    ;

  (void) write (2, msg, p-msg);
}

static void
trace1 (msg, num)
     const char *msg;
     unsigned int num;
{
  char buffer[16];
  char *p = &buffer[ sizeof(buffer) ];

  trace (msg);
  *--p = '\0';
  *--p = '\n';
  do {
    *--p = '0' + (num % 10);
    num /= 10;
  } while (num != 0); 
  trace (p);  
}

#else
#define TRACE(msg)
#define TRACE1(msg,num)
#endif


/* Errno support */

int errno;

int *
__errno ()
{
  return &errno;
}

/* syscall handler branches here to set errno.  Error codes
   that are common between newlib and Solaris are the same.  */

int
_cerror (e)
     int e;
{
  TRACE1("got to _cerror ",e);
  errno = e;
  return -1;
}


/* Sbrk support */

extern char _end[];
static char *curbrk = _end;

void *
sbrk (incr)
     size_t incr;
{
  char *oldbrk = curbrk;
  TRACE("got to sbrk\n");
  curbrk += incr;
  if (brk (curbrk) == -1)
    return (char *) -1;

  return (void *)oldbrk;
}


/* Isatty support */

int
isatty (fd)
     int fd;
{
  struct solaris_termios t;
  int ret;

  ret = (ioctl (fd, SOLARIS_TCGETS, &t) == 0);

  TRACE1("got to isatty, returned ", ret);
  return ret;
}


/* Convert Solaris {,f}stat to newlib.
   Fortunately, the st_mode bits are the same.  */

static void
solaris_to_newlib_stat (solaris, newlib)
     struct solaris_stat *solaris;
     struct stat *newlib;
{
  static struct stat zero_stat;

  *newlib = zero_stat;
  newlib->st_dev     = solaris->st_dev;
  newlib->st_ino     = solaris->st_ino;
  newlib->st_mode    = solaris->st_mode;
  newlib->st_nlink   = solaris->st_nlink;
  newlib->st_uid     = solaris->st_uid;
  newlib->st_gid     = solaris->st_gid;
  newlib->st_rdev    = solaris->st_rdev;
  newlib->st_size    = solaris->st_size;
  newlib->st_blksize = solaris->st_blksize;
  newlib->st_blocks  = solaris->st_blocks;
  newlib->st_atime   = solaris->st_atim.tv_sec;
  newlib->st_mtime   = solaris->st_mtim.tv_sec;
  newlib->st_ctime   = solaris->st_ctim.tv_sec;
}

int
stat (file, newlib_stat)
     const char *file;
     struct stat *newlib_stat;
{
  int ret;
  struct solaris_stat st;

  TRACE("got to stat\n");
  ret = _stat (file, &st);
  if (ret >= 0)
    solaris_to_newlib_stat (&st, newlib_stat);

  return ret;
}

int
lstat (file, newlib_stat)
     const char *file;
     struct stat *newlib_stat;
{
  int ret;
  struct solaris_stat st;

  TRACE("got to lstat\n");
  ret = _lstat (file, &st);
  if (ret >= 0)
    solaris_to_newlib_stat (&st, newlib_stat);

  return ret;
}

int
fstat (fd, newlib_stat)
     int fd;
     struct stat *newlib_stat;
{
  int ret;
  struct solaris_stat st;

  TRACE("got to fstat\n");
  ret = _fstat (fd, &st);
  if (ret >= 0)
    solaris_to_newlib_stat (&st, newlib_stat);

  return ret;
}


/* Nops */

int
getrusage ()
{
  _cerror (EINVAL);
  return -1;
}

char *
getcwd(buf, size)
     char *buf;
     size_t size;
{
  if (!buf || size < 2)
    return ".";

  buf[0] = '.';
  buf[1] = '\0';
  return buf;
}
