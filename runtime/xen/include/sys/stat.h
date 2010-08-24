#ifndef _SYS_STAT_H
#define _SYS_STAT_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <endian.h>

__BEGIN_DECLS

#if defined(__i386__)
struct stat {
	uint16_t	st_dev;
	uint16_t	__pad1;
	unsigned long	st_ino;
	uint16_t	st_mode;
	uint16_t	st_nlink;
	uint16_t	st_uid;
	uint16_t	st_gid;
	uint16_t	st_rdev;
	uint16_t	__pad2;
	unsigned long	st_size;
	unsigned long	st_blksize;
	unsigned long	st_blocks;
	time_t		st_atime;
	unsigned long	__unused1;
	time_t		st_mtime;
	unsigned long	__unused2;
	time_t		st_ctime;
	unsigned long	__unused3;
	unsigned long	__unused4;
	unsigned long	__unused5;
};

struct stat64 {
	uint16_t	st_dev;
	unsigned char	__pad0[10];

#define STAT64_HAS_BROKEN_ST_INO	1
	unsigned long	__st_ino;

	uint32_t	st_mode;
	uint32_t	st_nlink;

	unsigned long	st_uid;
	unsigned long	st_gid;

	uint16_t	st_rdev;
	unsigned char	__pad3[10];

__extension__	long long	st_size __attribute__((__packed__));
	unsigned long	st_blksize;

	unsigned long	st_blocks;	/* Number 512-byte blocks allocated. */
	unsigned long	__pad4;		/* future possible st_blocks high bits */

	time_t		st_atime;
	unsigned long	__pad5;

	time_t		st_mtime;
	unsigned long	__pad6;

	time_t		st_ctime;
	unsigned long	__pad7;		/* will be high 32 bits of ctime someday */

__extension__	unsigned long long	st_ino __attribute__((__packed__));
};
#elif defined(__sparc__) && defined(__arch64__)

struct stat {
	uint32_t  st_dev;
	unsigned long   st_ino;
	uint32_t  st_mode;
	int16_t   st_nlink;
	uint32_t   st_uid;
	uint32_t   st_gid;
	uint32_t  st_rdev;
	long   st_size;
	time_t  st_atime;
	time_t  st_mtime;
	time_t  st_ctime;
	long   st_blksize;
	long   st_blocks;
	unsigned long  __unused4[2];
};

struct stat64 {
	unsigned long long	st_dev;

	unsigned long long	st_ino;

	uint32_t	st_mode;
	uint32_t	st_nlink;

	uint32_t	st_uid;
	uint32_t	st_gid;

	unsigned long long	st_rdev;

	unsigned char	__pad3[8];

	long long	st_size;
	uint32_t	st_blksize;

	unsigned char	__pad4[8];
	uint32_t	st_blocks;

	time_t		st_atime;
	uint32_t	st_atime_nsec;

	time_t		st_mtime;
	uint32_t	st_mtime_nsec;

	time_t		st_ctime;
	uint32_t	st_ctime_nsec;

	uint32_t	__unused4;
	uint32_t	__unused5;
};

#elif defined(__sparc__)

struct stat {
	uint16_t	st_dev;
	unsigned long	st_ino;
	uint16_t	st_mode;
	int16_t		st_nlink;
	uint16_t	st_uid;
	uint16_t	st_gid;
	uint16_t	st_rdev;
	long		st_size;
	time_t		st_atime;
	unsigned long	__unused1;
	time_t		st_mtime;
	unsigned long	__unused2;
	time_t		st_ctime;
	unsigned long	__unused3;
	long		st_blksize;
	long		st_blocks;
	unsigned long	__unused4[2];
};

struct stat64 {
	unsigned char	__pad0[6];
	uint16_t	st_dev;

__extension__	unsigned long long	st_ino;

	uint32_t	st_mode;
	uint32_t	st_nlink;

	uint32_t	st_uid;
	uint32_t	st_gid;

	unsigned char	__pad2[6];
	uint16_t	st_rdev;

	unsigned char	__pad3[8];

__extension__	long long	st_size;
	uint32_t	st_blksize;

	unsigned char	__pad4[8];
	uint32_t	st_blocks;

	time_t		st_atime;
	uint32_t	__unused1;

	time_t		st_mtime;
	uint32_t	__unused2;

	time_t		st_ctime;
	uint32_t	__unused3;

	uint32_t	__unused4;
	uint32_t	__unused5;
};

#elif defined(__alpha__)

struct stat {
	uint32_t	st_dev;
	uint32_t	st_ino;
	uint32_t	st_mode;
	uint32_t	st_nlink;
	uint32_t	st_uid;
	uint32_t	st_gid;
	uint32_t	st_rdev;
	signed long	st_size;
	time_t		st_atime;
	time_t		st_mtime;
	time_t		st_ctime;
	uint32_t	st_blksize;
	int32_t		st_blocks;
	uint32_t	st_flags;
	uint32_t	st_gen;
};

#elif defined(__mips__)

struct stat {
	uint32_t	st_dev;
	long		st_pad1[3];		/* Reserved for network id */
	ino_t		st_ino;
	uint32_t	st_mode;
	int32_t		st_nlink;
	int32_t		st_uid;
	int32_t		st_gid;
	uint32_t	st_rdev;
	long		st_pad2[2];
	long		st_size;
	long		st_pad3;
	/*
	 * Actually this should be timestruc_t st_atime, st_mtime and st_ctime
	 * but we don't have it under Linux.
	 */
	time_t		st_atime;
	long		reserved0;
	time_t		st_mtime;
	long		reserved1;
	time_t		st_ctime;
	long		reserved2;
	long		st_blksize;
	long		st_blocks;
	char		st_fstype[16];	/* Filesystem type name */
	long		st_pad4[8];
	/* Linux specific fields */
	uint32_t	st_flags;
	uint32_t	st_gen;
};

struct stat64 {
	unsigned long	st_dev;
	unsigned long	st_pad0[3];	/* Reserved for st_dev expansion  */
__extension__ unsigned long long	st_ino;
	uint32_t	st_mode;
	uint32_t	st_nlink;
	uint32_t	st_uid;
	uint32_t	st_gid;
	unsigned long	st_rdev;
	unsigned long	st_pad1[3];	/* Reserved for st_rdev expansion  */
__extension__ long long	st_size;
	/*
	 * Actually this should be timestruc_t st_atime, st_mtime and st_ctime
	 * but we don't have it under Linux.
	 */
	time_t		st_atime;
	unsigned long	reserved0;	/* Reserved for st_atime expansion  */
	time_t		st_mtime;
	unsigned long	reserved1;	/* Reserved for st_atime expansion  */
	time_t		st_ctime;
	unsigned long	reserved2;	/* Reserved for st_atime expansion  */
	unsigned long	st_blksize;
	unsigned long	st_pad2;
__extension__ long long	st_blocks;
};
#elif defined(__powerpc__) || defined(__powerpc64__)

#if defined(__powerpc__) && !defined(__powerpc64__)
struct stat {
	dev_t		st_dev;
	ino_t		st_ino;
	mode_t		st_mode;
	nlink_t		st_nlink;
	uid_t		st_uid;
	gid_t		st_gid;
	dev_t		st_rdev;
	off_t		st_size;
	unsigned long	st_blksize;
	unsigned long	st_blocks;
	time_t		st_atime;
	unsigned long	__unused1;
	time_t		st_mtime;
	unsigned long	__unused2;
	time_t		st_ctime;
	unsigned long	__unused3;
	unsigned long	__unused4;
	unsigned long	__unused5;
};
#else
struct stat {
	unsigned long	st_dev;
	ino_t		st_ino;
	nlink_t		st_nlink;
	uint32_t	st_mode;
	uint32_t 	st_uid;
	uint32_t 	st_gid;
	unsigned long	st_rdev;
	off_t		st_size;
	unsigned long	st_blksize;
	unsigned long	st_blocks;
	time_t		st_atime;
	unsigned long	st_atime_nsec;
	time_t		st_mtime;
	unsigned long	st_mtime_nsec;
	time_t		st_ctime;
	unsigned long	st_ctime_nsec;
	unsigned long	__unused4;
	unsigned long	__unused5;
	unsigned long	__unused6;
};
#endif

/* This matches struct stat64 in glibc2.1.
 */
struct stat64 {
__extension__	unsigned long long st_dev; 	/* Device.  */
__extension__	unsigned long long st_ino;	/* File serial number.  */
	uint32_t st_mode;		/* File mode.  */
	uint32_t st_nlink;		/* Link count.  */
	uint32_t st_uid;		/* User ID of the file's owner.  */
	uint32_t st_gid;		/* Group ID of the file's group. */
__extension__	unsigned long long st_rdev; 	/* Device number, if device.  */
	uint16_t __pad2;
__extension__	long long st_size;		/* Size of file, in bytes.  */
	long st_blksize;		/* Optimal block size for I/O.  */

__extension__	long long st_blocks;		/* Number 512-byte blocks allocated. */
	time_t st_atime;			/* Time of last access.  */
	unsigned long int __unused1;
	time_t st_mtime;			/* Time of last modification.  */
	unsigned long int __unused2;
	time_t st_ctime;			/* Time of last status change.  */
	unsigned long int __unused3;
	unsigned long int __unused4;
	unsigned long int __unused5;
};
#elif defined(__arm__)
struct stat {
	uint16_t	st_dev;
	uint16_t	__pad1;
	unsigned long	st_ino;
	uint16_t	st_mode;
	uint16_t	st_nlink;
	uint16_t	st_uid;
	uint16_t	st_gid;
	uint16_t	st_rdev;
	uint16_t	__pad2;
	unsigned long	st_size;
	unsigned long	st_blksize;
	unsigned long	st_blocks;
	time_t		st_atime;
	unsigned long	__unused1;
	time_t		st_mtime;
	unsigned long	__unused2;
	time_t		st_ctime;
	unsigned long	__unused3;
	unsigned long	__unused4;
	unsigned long	__unused5;
};

/* This matches struct stat64 in glibc2.1, hence the absolutely
 * insane amounts of padding around dev_t's.
 */
struct stat64 {
	uint16_t	st_dev;
	unsigned char	__pad0[10];

#define STAT64_HAS_BROKEN_ST_INO	1
	unsigned long	__st_ino;
	uint32_t	st_mode;
	uint32_t	st_nlink;

	unsigned long	st_uid;
	unsigned long	st_gid;

	uint16_t	st_rdev;
	unsigned char	__pad3[10];

__extension__	long long	st_size;
	unsigned long	st_blksize;

#ifdef __ARMEB__
	unsigned long	__pad4;		/* future possible st_blocks high bits */
	unsigned long	st_blocks;	/* Number 512-byte blocks allocated. */
#else
	unsigned long	st_blocks;	/* Number 512-byte blocks allocated. */
	unsigned long	__pad4;		/* future possible st_blocks high bits */
#endif

	time_t		st_atime;
	unsigned long	__pad5;

	time_t		st_mtime;
	unsigned long	__pad6;

	time_t		st_ctime;
	unsigned long	__pad7;		/* will be high 32 bits of ctime someday */

__extension__	unsigned long long	st_ino;
};
#elif defined(__s390__)
#if defined(__s390x__)
struct stat {
        unsigned long	st_dev;
        unsigned long	st_ino;
        unsigned long	st_nlink;
        uint32_t	st_mode;
        uint32_t	st_uid;
        uint32_t	st_gid;
        uint32_t	__pad1;
        unsigned long	st_rdev;
        unsigned long	st_size;
        time_t		st_atime;
        unsigned long	__reserved0;    /* reserved for atime.nanoseconds */
        time_t		st_mtime;
        unsigned long	__reserved1;    /* reserved for mtime.nanoseconds */
        time_t		st_ctime;
        unsigned long	__reserved2;    /* reserved for ctime.nanoseconds */
        unsigned long	st_blksize;
        long		st_blocks;
        unsigned long	__unused[3];
};
#else
struct stat {
	uint16_t	st_dev;
	uint16_t	__pad1;
	unsigned long	st_ino;
	uint16_t	st_mode;
	uint16_t	st_nlink;
	uint16_t	st_uid;
	uint16_t	st_gid;
	uint16_t	st_rdev;
	uint16_t	__pad2;
	unsigned long	st_size;
	unsigned long	st_blksize;
	unsigned long	st_blocks;
	time_t		st_atime;
	unsigned long	__unused1;
	time_t		st_mtime;
	unsigned long	__unused2;
	time_t		st_ctime;
	unsigned long	__unused3;
	unsigned long	__unused4;
	unsigned long	__unused5;
};
#endif
struct stat64 {
	unsigned char	__pad0[6];
	uint16_t	st_dev;
	uint32_t	__pad1;
#define STAT64_HAS_BROKEN_ST_INO	1
	unsigned long	__st_ino;
	uint32_t	st_mode;
	uint32_t	st_nlink;
	unsigned long	st_uid;
	unsigned long	st_gid;
	unsigned char	__pad2[6];
	uint16_t	st_rdev;
	uint32_t	__pad3;
__extension__	long long	st_size;
	unsigned long	st_blksize;
	unsigned char	__pad4[4];
	unsigned long	__pad5; 	/* future possible st_blocks high bits */
	unsigned long	st_blocks;	/* Number 512-byte blocks allocated. */
	time_t		st_atime;
	unsigned long	__pad6;
	time_t		st_mtime;
	unsigned long	__pad7;
	time_t		st_ctime;
	unsigned long	__pad8; 	/* will be high 32 bits of ctime someday */
__extension__	unsigned long long	st_ino;
};

#elif defined(__hppa__)

struct stat {
       unsigned long	st_dev;         /* dev_t is 32 bits on parisc */
       unsigned long	st_ino;         /* 32 bits */
       uint16_t		st_mode;        /* 16 bits */
       uint16_t		st_nlink;       /* 16 bits */
       uint16_t		st_reserved1;   /* old st_uid */
       uint16_t		st_reserved2;   /* old st_gid */
       unsigned long	st_rdev;
       unsigned long	st_size;
       time_t		st_atime;
       unsigned long	st_spare1;
       time_t		st_mtime;
       unsigned long	st_spare2;
       time_t		st_ctime;
       unsigned long	st_spare3;
       long		st_blksize;
       long		st_blocks;
       unsigned long	__unused1;      /* ACL stuff */
       unsigned long	__unused2;      /* network */
       unsigned long	__unused3;      /* network */
       unsigned long	__unused4;      /* cnodes */
       uint16_t		__unused5;      /* netsite */
       int16_t		st_fstype;
       unsigned long	st_realdev;
       uint16_t		st_basemode;
       uint16_t		st_spareshort;
       unsigned long	st_uid;
       unsigned long	st_gid;
       unsigned long	st_spare4[3];
};

struct stat64 {
	unsigned long long st_dev;
	uint32_t	__pad1;
#define STAT64_HAS_BROKEN_ST_INO	1
	unsigned long	__st_ino;
	unsigned long	st_mode;
	unsigned long	st_nlink;
	unsigned long	st_uid;
	unsigned long	st_gid;
	unsigned long long st_rdev;
	uint32_t	__pad2;
	unsigned long long st_size;
	unsigned long	st_blksize;

	unsigned long long st_blocks;
 	time_t		st_atime;
	unsigned long	__unused1;
	time_t		st_mtime;
	unsigned long	__unused2;
	time_t		st_ctime;
	unsigned long	__unused3;
	unsigned long long st_ino;
};

#elif defined(__x86_64__)

struct stat {
	unsigned long	st_dev;
	unsigned long	st_ino;
	unsigned long	st_nlink;
	uint32_t	st_mode;
	uint32_t	st_uid;
	uint32_t	st_gid;
	uint32_t	__pad0;
	unsigned long	 st_rdev;
	unsigned long	st_size;
	unsigned long	st_blksize;
	unsigned long	st_blocks;
	time_t		st_atime;
	unsigned long	__reserved0;
	time_t		st_mtime;
	unsigned long	__reserved1;
	time_t		st_ctime;
	unsigned long	__reserved2;
	long		__unused[3];
};

#elif defined(__ia64__)

struct stat {
	unsigned long	st_dev;
	unsigned long	st_ino;
	unsigned long	st_nlink;
	uint32_t	st_mode;
	uint32_t	st_uid;
	uint32_t	st_gid;
	uint32_t	__pad;
	unsigned long	st_rdev;
	unsigned long	st_size;
	time_t		st_atime;
	unsigned long	reserved;
	time_t		st_mtime;
	unsigned long	reserved2;
	time_t		st_ctime;
	unsigned long	reserved3;
	unsigned long	st_blksize;
	long		st_blocks;
	unsigned long	pad[3];
};

#endif

#define S_IFMT	       00170000
#define S_IFSOCK	0140000
#define S_IFLNK		0120000
#define S_IFREG		0100000
#define S_IFBLK		0060000
#define S_IFDIR		0040000
#define S_IFCHR		0020000
#define S_IFIFO		0010000
#define S_ISUID		0004000
#define S_ISGID		0002000
#define S_ISVTX		0001000

#define S_ISLNK(m)	(((m) & S_IFMT) == S_IFLNK)
#define S_ISREG(m)	(((m) & S_IFMT) == S_IFREG)
#define S_ISDIR(m)	(((m) & S_IFMT) == S_IFDIR)
#define S_ISCHR(m)	(((m) & S_IFMT) == S_IFCHR)
#define S_ISBLK(m)	(((m) & S_IFMT) == S_IFBLK)
#define S_ISFIFO(m)	(((m) & S_IFMT) == S_IFIFO)
#define S_ISSOCK(m)	(((m) & S_IFMT) == S_IFSOCK)

#define S_IRWXU 00700
#define S_IRUSR 00400
#define S_IWUSR 00200
#define S_IXUSR 00100

#define S_IRWXG 00070
#define S_IRGRP 00040
#define S_IWGRP 00020
#define S_IXGRP 00010

#define S_IRWXO 00007
#define S_IROTH 00004
#define S_IWOTH 00002
#define S_IXOTH 00001

extern int stat(const char *__file, struct stat *__buf) __THROW;
extern int fstat(int __fd, struct stat *__buf) __THROW;
extern int lstat(const char *__file, struct stat *__buf) __THROW;

#if __WORDSIZE == 64
#define __NO_STAT64
#else
extern int stat64(const char *__file, struct stat64 *__buf) __THROW;
extern int fstat64(int __fd, struct stat64 *__buf) __THROW;
extern int lstat64(const char *__file, struct stat64 *__buf) __THROW;

#if defined _FILE_OFFSET_BITS && _FILE_OFFSET_BITS == 64
#define lstat lstat64
#define fstat fstat64
#define stat stat64
#define pread pread64
#define pwrite pwrite64
#endif
#endif

#define major(dev) ({ unsigned long long l=(dev); ((l>>8) & 0xfff) | (l >> 32) & 0xfffff000; })
#define minor(dev) ({ unsigned long long l=(dev); (l & 0xff) | ((l>>12)&0xffffff00); })
#define makedev(maj,min) ({ unsigned long long a=(maj), i=(min); ((a&0xfff)<<8) | (i&0xff) | ((a&~0xfff)<<32) | ((i&0xfffff00)<<12); })

extern int chmod (const char *__file, mode_t __mode) __THROW;
extern int fchmod (int __fd, mode_t __mode) __THROW;
extern mode_t umask (mode_t __mask) __THROW;
extern int mkdir (const char *__path, mode_t __mode) __THROW;
extern int mknod (const char *__path, mode_t __mode, dev_t __dev) __THROW;
extern int mkfifo (const char *__path, mode_t __mode) __THROW;

#define S_IREAD S_IRUSR
#define S_IWRITE S_IWUSR
#define S_IEXEC S_IXUSR

__END_DECLS

#endif
