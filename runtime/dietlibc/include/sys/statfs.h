#ifndef _SYS_STATFS_H
#define _SYS_STATFS_H

#include <sys/cdefs.h>
#include <endian.h>
#include <sys/types.h>

__BEGIN_DECLS

typedef struct {
  int32_t __val[2];
} __kernel_fsid_t;

#if defined(__mips64__)

struct statfs {
  int64_t		f_type;
#define f_fstyp f_type
  int64_t		f_bsize;
  int64_t		f_frsize;	/* Fragment size - unsupported */
  int64_t		f_blocks;
  int64_t		f_bfree;
  int64_t		f_files;
  int64_t		f_ffree;
  int64_t		f_bavail;

  /* Linux specials */
  __kernel_fsid_t	f_fsid;
  int64_t		f_namelen;
  int64_t		f_spare[6];
};

struct statfs64 {			/* Same as struct statfs */
  int64_t		f_type;
  int64_t		f_bsize;
  int64_t		f_frsize;	/* Fragment size - unsupported */
  int64_t		f_blocks;
  int64_t		f_bfree;
  int64_t		f_files;
  int64_t		f_ffree;
  int64_t		f_bavail;

  /* Linux specials */
  __kernel_fsid_t	f_fsid;
  int64_t		f_namelen;
  int64_t		f_spare[6];
};

#elif defined(__mips__)

struct statfs {
  int32_t		f_type;
#define f_fstyp f_type
  int32_t		f_bsize;
  int32_t		f_frsize;	/* Fragment size - unsupported */
  int32_t		f_blocks;
  int32_t		f_bfree;
  int32_t		f_files;
  int32_t		f_ffree;
  int32_t		f_bavail;

  /* Linux specials */
  __kernel_fsid_t	f_fsid;
  int32_t		f_namelen;
  int32_t		f_spare[6];
};

struct statfs64 {
  uint32_t	f_type;
  uint32_t	f_bsize;
  uint32_t	f_frsize;	/* Fragment size - unsupported */
  uint32_t	__pad;
  uint64_t	f_blocks;
  uint64_t	f_bfree;
  uint64_t	f_files;
  uint64_t	f_ffree;
  uint64_t	f_bavail;
  __kernel_fsid_t f_fsid;
  uint32_t	f_namelen;
  uint32_t	f_spare[6];
};

#elif defined(__s390x__)

/* S/390 64-bit mode */

struct statfs {
  int32_t  f_type;
  int32_t  f_bsize;
  int64_t f_blocks;
  int64_t f_bfree;
  int64_t f_bavail;
  int64_t f_files;
  int64_t f_ffree;
  __kernel_fsid_t f_fsid;
  int32_t  f_namelen;
  int32_t  f_frsize;
  int32_t  f_spare[5];
};

struct statfs64 {
  int32_t  f_type;
  int32_t  f_bsize;
  int64_t f_blocks;
  int64_t f_bfree;
  int64_t f_bavail;
  int64_t f_files;
  int64_t f_ffree;
  __kernel_fsid_t f_fsid;
  int32_t  f_namelen;
  int32_t  f_frsize;
  int32_t  f_spare[5];
};

#elif __WORDSIZE == 64

/* generic 64-bit */

struct statfs {
  int64_t f_type;
  int64_t f_bsize;
  int64_t f_blocks;
  int64_t f_bfree;
  int64_t f_bavail;
  int64_t f_files;
  int64_t f_ffree;
  __kernel_fsid_t f_fsid;
  int64_t f_namelen;
  int64_t f_frsize;
  int64_t f_spare[5];
};

struct statfs64 {
  int64_t f_type;
  int64_t f_bsize;
  int64_t f_blocks;
  int64_t f_bfree;
  int64_t f_bavail;
  int64_t f_files;
  int64_t f_ffree;
  __kernel_fsid_t f_fsid;
  int64_t f_namelen;
  int64_t f_frsize;
  int64_t f_spare[5];
};

#else

/* generic 32-bit */

struct statfs {
  uint32_t f_type;
  uint32_t f_bsize;
  uint32_t f_blocks;
  uint32_t f_bfree;
  uint32_t f_bavail;
  uint32_t f_files;
  uint32_t f_ffree;
  __kernel_fsid_t f_fsid;
  uint32_t f_namelen;
  uint32_t f_frsize;
  uint32_t f_spare[5];
};

struct statfs64 {
  uint32_t f_type;
  uint32_t f_bsize;
  uint64_t f_blocks;
  uint64_t f_bfree;
  uint64_t f_bavail;
  uint64_t f_files;
  uint64_t f_ffree;
  __kernel_fsid_t f_fsid;
  uint32_t f_namelen;
  uint32_t f_frsize;
  uint32_t f_spare[5];
};

#endif

int statfs(const char *path, struct statfs *buf) __THROW;
int fstatfs(int fd, struct statfs *buf) __THROW;

#if __WORDSIZE == 32
int statfs64(const char *path, struct statfs64 *buf) __THROW;
int fstatfs64(int fd, struct statfs64 *buf) __THROW;

#if defined _FILE_OFFSET_BITS && _FILE_OFFSET_BITS == 64
#define statfs statfs64
#define fstatfs fstatfs64
#endif
#endif

__END_DECLS

#endif
