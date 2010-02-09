#ifndef _SYS_STATVFS_H
#define _SYS_STATVFS_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

struct statvfs {
  unsigned long  f_bsize;    /* file system block size */
  unsigned long  f_frsize;   /* fragment size */
  fsblkcnt_t     f_blocks;   /* size of fs in f_frsize units */
  fsblkcnt_t     f_bfree;    /* # free blocks */
  fsblkcnt_t     f_bavail;   /* # free blocks for non-root */
  fsfilcnt_t     f_files;    /* # inodes */
  fsfilcnt_t     f_ffree;    /* # free inodes */
  fsfilcnt_t     f_favail;   /* # free inodes for non-root */
  unsigned long  f_fsid;     /* file system ID */
  unsigned long  f_flag;     /* mount flags */
  unsigned long  f_namemax;  /* maximum filename length */
};

int statvfs(const char *path, struct statvfs *buf) __THROW;
int fstatvfs(int fd, struct statvfs *buf) __THROW;

/* Definitions for the flag in `f_flag'.  These definitions should be
   kept in sync with the definitions in <sys/mount.h>.  */
enum
{
  ST_RDONLY = 1,		/* Mount read-only.  */
#define ST_RDONLY	ST_RDONLY
  ST_NOSUID = 2			/* Ignore suid and sgid bits.  */
#define ST_NOSUID	ST_NOSUID
#ifdef __USE_GNU
  ,
  ST_NODEV = 4,			/* Disallow access to device special files.  */
# define ST_NODEV	ST_NODEV
  ST_NOEXEC = 8,		/* Disallow program execution.  */
# define ST_NOEXEC	ST_NOEXEC
  ST_SYNCHRONOUS = 16,		/* Writes are synced at once.  */
# define ST_SYNCHRONOUS	ST_SYNCHRONOUS
  ST_MANDLOCK = 64,		/* Allow mandatory locks on an FS.  */
# define ST_MANDLOCK	ST_MANDLOCK
  ST_WRITE = 128,		/* Write on file/directory/symlink.  */
# define ST_WRITE	ST_WRITE
  ST_APPEND = 256,		/* Append-only file.  */
# define ST_APPEND	ST_APPEND
  ST_IMMUTABLE = 512,		/* Immutable file.  */
# define ST_IMMUTABLE	ST_IMMUTABLE
  ST_NOATIME = 1024,		/* Do not update access times.  */
# define ST_NOATIME	ST_NOATIME
  ST_NODIRATIME = 2048,		/* Do not update directory access times.  */
# define ST_NODIRATIME	ST_NODIRATIME
  ST_RELATIME = 4096		/* Update atime relative to mtime/ctime.  */
# define ST_RELATIME	ST_RELATIME
#endif	/* Use GNU.  */
};

__END_DECLS

#endif
