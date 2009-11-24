/*
 * hosted & unhosted io support.
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

#if HOSTED
#include <stdint.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>

#define HOSTED_EXIT  0
#define HOSTED_INIT_SIM 1
#define HOSTED_OPEN 2
#define HOSTED_CLOSE 3
#define HOSTED_READ 4
#define HOSTED_WRITE 5
#define HOSTED_LSEEK 6
#define HOSTED_RENAME 7
#define HOSTED_UNLINK 8
#define HOSTED_STAT 9
#define HOSTED_FSTAT 10
#define HOSTED_GETTIMEOFDAY 11
#define HOSTED_ISATTY 12
#define HOSTED_SYSTEM 13

/* This function is provided by the board's BSP, because the precise
   mechanism of informing gdb is board specific.  */
extern int __io_hosted (int func, void *args);

/* Protocol specific representation of datatypes, as specified in D.9.11
 * of the GDB manual.
 * Note that since the m68k is big-endian, we can use native
 * representations of integer datatypes in structured datatypes. */

typedef uint32_t gdb_mode_t;
typedef uint32_t gdb_time_t;

struct gdb_stat {
  uint32_t    st_dev;     /* device */
  uint32_t    st_ino;     /* inode */
  gdb_mode_t  st_mode;    /* protection */
  uint32_t    st_nlink;   /* number of hard links */
  uint32_t    st_uid;     /* user ID of owner */
  uint32_t    st_gid;     /* group ID of owner */
  uint32_t    st_rdev;    /* device type (if inode device) */
  uint64_t    st_size;    /* total size, in bytes */
  uint64_t    st_blksize; /* blocksize for filesystem I/O */
  uint64_t    st_blocks;  /* number of blocks allocated */
  gdb_time_t  st_atime;   /* time of last access */
  gdb_time_t  st_mtime;   /* time of last modification */
  gdb_time_t  st_ctime;   /* time of last change */
};

struct gdb_timeval {
  gdb_time_t tv_sec;  /* second */
  uint64_t tv_usec;   /* microsecond */
};


/* Parameters are passed between the library and the debugging stub
 * in a fixed-size buffer.
 */

typedef uint32_t gdb_parambuf_t[4];

/* open flags */

#define GDB_O_RDONLY   0x0
#define GDB_O_WRONLY   0x1
#define GDB_O_RDWR     0x2
#define GDB_O_APPEND   0x8
#define GDB_O_CREAT  0x200
#define GDB_O_TRUNC  0x400
#define GDB_O_EXCL   0x800

/* mode_t values */

#define GDB_S_IFREG 0100000
#define GDB_S_IFDIR  040000
#define GDB_S_IRUSR    0400
#define GDB_S_IWUSR    0200
#define GDB_S_IXUSR    0100
#define GDB_S_IRGRP     040
#define GDB_S_IWGRP     020
#define GDB_S_IXGRP     010
#define GDB_S_IROTH      04
#define GDB_S_IWOTH      02
#define GDB_S_IXOTH      01

/* errno values */

#define GDB_EPERM         1
#define GDB_ENOENT        2
#define GDB_EINTR         4
#define GDB_EBADF         9
#define GDB_EACCES       13
#define GDB_EFAULT       14
#define GDB_EBUSY        16
#define GDB_EEXIST       17
#define GDB_ENODEV       19
#define GDB_ENOTDIR      20
#define GDB_EISDIR       21
#define GDB_EINVAL       22
#define GDB_ENFILE       23
#define GDB_EMFILE       24
#define GDB_EFBIG        27
#define GDB_ENOSPC       28
#define GDB_ESPIPE       29
#define GDB_EROFS        30
#define GDB_ENAMETOOLONG 91
#define GDB_EUNKNOWN     9999

/* lseek flags */

#define GDB_SEEK_SET 0
#define GDB_SEEK_CUR 1
#define GDB_SEEK_END 2


/* conversion functions */

extern gdb_mode_t __hosted_to_gdb_mode_t (mode_t m);
extern int32_t __hosted_to_gdb_open_flags (int f);
extern int32_t __hosted_to_gdb_lseek_flags (int f);

extern void __hosted_from_gdb_stat (const struct gdb_stat *gs,
				    struct stat *s);
extern void __hosted_from_gdb_timeval (const struct gdb_timeval *gt,
				       struct timeval *t);
extern int __hosted_from_gdb_errno (int32_t err);

#else
#ifdef IO
#define IO_NAME_(IO) __hosted_##IO
#define IO_NAME(IO) IO_NAME_(IO)
#define IO_STRING_(IO) #IO
#define IO_STRING(IO) IO_STRING_(IO)
/* Emit an object that causes a gnu linker warning.  */
static const char IO_NAME (IO) []
__attribute__ ((section (".gnu.warning"), used)) =
"IO function '" IO_STRING (IO) "' used";
#endif
#endif
