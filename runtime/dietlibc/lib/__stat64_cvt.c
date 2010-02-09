#include <sys/stat.h>
#ifndef __NO_STAT64

void __stat64_cvt(const struct stat *src,struct stat64 *dest);

void __stat64_cvt(const struct stat *src,struct stat64 *dest) {
  dest->st_dev=src->st_dev;
  dest->st_ino=src->st_ino;
  dest->st_mode=src->st_mode;
  dest->st_nlink=src->st_nlink;
  dest->st_uid=src->st_uid;
  dest->st_gid=src->st_gid;
  dest->st_rdev=src->st_rdev;
  dest->st_size=src->st_size;
  dest->st_blksize=src->st_blksize;
  dest->st_blocks=src->st_blocks;
  dest->st_atime=src->st_atime;
  dest->st_mtime=src->st_mtime;
  dest->st_ctime=src->st_ctime;
}
#endif
