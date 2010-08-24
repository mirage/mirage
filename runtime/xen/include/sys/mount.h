#ifndef _SYS_MOUNT_H
#define _SYS_MOUNT_H

#include <sys/cdefs.h>
#include <sys/types.h>
#define _LINUX_CONFIG_H

__BEGIN_DECLS

#define BLOCK_SIZE	1024
#define BLOCK_SIZE_BITS	10


/* These are the fs-independent mount-flags: up to 16 flags are
   supported  */
enum
{
  MS_RDONLY = 1,		/* Mount read-only.  */
#define MS_RDONLY	MS_RDONLY
  MS_NOSUID = 2,		/* Ignore suid and sgid bits.  */
#define MS_NOSUID	MS_NOSUID
  MS_NODEV = 4,			/* Disallow access to device special files.  */
#define MS_NODEV	MS_NODEV
  MS_NOEXEC = 8,		/* Disallow program execution.  */
#define MS_NOEXEC	MS_NOEXEC
  MS_SYNCHRONOUS = 16,		/* Writes are synced at once.  */
#define MS_SYNCHRONOUS	MS_SYNCHRONOUS
  MS_REMOUNT = 32,		/* Alter flags of a mounted FS.  */
#define MS_REMOUNT	MS_REMOUNT
  MS_MANDLOCK = 64,		/* Allow mandatory locks on an FS.  */
#define MS_MANDLOCK	MS_MANDLOCK
  S_WRITE = 128,		/* Write on file/directory/symlink.  */
#define S_WRITE		S_WRITE
  S_APPEND = 256,		/* Append-only file.  */
#define S_APPEND	S_APPEND
  S_IMMUTABLE = 512,		/* Immutable file.  */
#define S_IMMUTABLE	S_IMMUTABLE
  MS_NOATIME = 1024,		/* Do not update access times.  */
#define MS_NOATIME	MS_NOATIME
  MS_NODIRATIME = 2048,		/* Do not update directory access times.  */
#define MS_NODIRATIME	MS_NODIRATIME
  MS_BIND = 4096,		/* Bind directory at different place.  */
#define MS_BIND		MS_BIND
};

/* Flags that can be altered by MS_REMOUNT  */
#define MS_RMT_MASK (MS_RDONLY | MS_MANDLOCK)


/* Magic mount flag number. Has to be or-ed to the flag values.  */

#define MS_MGC_VAL 0xc0ed0000	/* Magic flag number to indicate "new" flags */
#define MS_MGC_MSK 0xffff0000	/* Magic flag number mask */


/* The read-only stuff doesn't really belong here, but any other place
   is probably as bad and I don't want to create yet another include
   file.  */

#define BLKROSET   _IO(0x12, 93) /* Set device read-only (0 = read-write).  */
#define BLKROGET   _IO(0x12, 94) /* Get read-only status (0 = read_write).  */
#define BLKRRPART  _IO(0x12, 95) /* Re-read partition table.  */
#define BLKGETSIZE _IO(0x12, 96) /* Return device size.  */
#define BLKFLSBUF  _IO(0x12, 97) /* Flush buffer cache.  */
#define BLKRASET   _IO(0x12, 98) /* Set read ahead for block device.  */
#define BLKRAGET   _IO(0x12, 99) /* Get current read ahead setting.  */


/* Possible value for FLAGS parameter of `umount2'.  */
enum
{
  MNT_FORCE = 1,		/* Force unmounting.  */
#define MNT_FORCE MNT_FORCE
  MNT_DETACH = 2		/* Just detach, unmount when last reference dies.  */
#define MNT_DETACH MNT_DETACH
};

int  mount(const char* specialfile, const char* dir, const char* filesystemtype,
	   unsigned long rwflag, const void * data) __THROW;

int umount(const char *specialfile) __THROW;
int umount2(const char *specialfile, int mflag) __THROW;

__END_DECLS

#endif
