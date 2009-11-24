/*
 * hosted io support for GDB's remote fileio protocol
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

#include "io.h"
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

gdb_mode_t
__hosted_to_gdb_mode_t (mode_t m)
{
  gdb_mode_t result = 0;
  if (m & S_IFREG)
    result |= GDB_S_IFREG;
  if (m & S_IFDIR)
    result |= GDB_S_IFDIR;
  if (m & S_IRUSR)
    result |= GDB_S_IRUSR;
  if (m & S_IWUSR)
    result |= GDB_S_IWUSR;
  if (m & S_IXUSR)
    result |= GDB_S_IXUSR;
  if (m & S_IRGRP)
    result |= GDB_S_IRGRP;
  if (m & S_IWGRP)
    result |= GDB_S_IWGRP;
  if (m & S_IXGRP)
    result |= GDB_S_IXGRP;
  if (m & S_IROTH)
    result |= GDB_S_IROTH;
  if (m & S_IWOTH)
    result |= GDB_S_IWOTH;
  if (m & S_IXOTH)
    result |= GDB_S_IXOTH;
  return result;
}

int32_t
__hosted_to_gdb_open_flags (int f)
{
  int32_t result = 0;
  if (f & O_RDONLY)
    result |= GDB_O_RDONLY;
  if (f & O_WRONLY)
    result |= GDB_O_WRONLY;
  if (f & O_RDWR)
    result |= GDB_O_RDWR;
  if (f & O_APPEND)
    result |= GDB_O_APPEND;
  if (f & O_CREAT)
    result |= GDB_O_CREAT;
  if (f & O_TRUNC)
    result |= GDB_O_TRUNC;
  if (f & O_EXCL)
    result |= GDB_O_EXCL;
  return result;
}

int32_t
__hosted_to_gdb_lseek_flags (int f)
{
  if (f == SEEK_CUR)
    return GDB_SEEK_CUR;
  else if (f == SEEK_END)
    return GDB_SEEK_END;
  else
    return GDB_SEEK_SET;
}

void
__hosted_from_gdb_stat (const struct gdb_stat *gs,
			struct stat *s)
{
  s->st_dev = gs->st_dev;
  s->st_ino = gs->st_ino;
  s->st_mode = gs->st_mode;
  s->st_nlink = gs->st_nlink;
  s->st_uid = gs->st_uid;
  s->st_gid = gs->st_gid;
  s->st_rdev = gs->st_rdev;
  s->st_size = gs->st_size;
  s->st_blksize = gs->st_blksize;
  s->st_blocks = gs->st_blocks;
  s->st_atime = gs->st_atime;
  s->st_mtime = gs->st_mtime;
  s->st_ctime = gs->st_ctime;
}

void
__hosted_from_gdb_timeval (const struct gdb_timeval *gt,
			   struct timeval *t)
{
  t->tv_sec = gt->tv_sec;
  t->tv_usec = gt->tv_usec;
}

int
__hosted_from_gdb_errno (int32_t err)
{
  switch (err)
    {
    case 0: 		return 0;
    case GDB_EPERM: 	return EPERM;
    case GDB_ENOENT: 	return ENOENT;
    case GDB_EINTR: 	return EINTR;
    case GDB_EBADF: 	return EBADF;
    case GDB_EACCES: 	return EACCES;
    case GDB_EFAULT: 	return EFAULT;
    case GDB_EBUSY: 	return EBUSY;
    case GDB_EEXIST: 	return EEXIST;
    case GDB_ENODEV: 	return ENODEV;
    case GDB_ENOTDIR: 	return ENOTDIR;
    case GDB_EISDIR: 	return EISDIR;
    case GDB_EINVAL: 	return EINVAL;
    case GDB_ENFILE: 	return ENFILE;
    case GDB_EMFILE: 	return EMFILE;
    case GDB_EFBIG: 	return EFBIG;
    case GDB_ENOSPC: 	return ENOSPC;
    case GDB_ESPIPE: 	return ESPIPE;
    case GDB_EROFS: 	return EROFS;
    case GDB_ENAMETOOLONG: 	return ENAMETOOLONG;
    case GDB_EUNKNOWN:
    default:
      return EIO;
    }
}

