#include <sys/statfs.h>

#if __WORDSIZE == 32

void __statfs64_cvt(const struct statfs *src,struct statfs64 *dest);
void __statfs64_cvt(const struct statfs *src,struct statfs64 *dest) {
  dest->f_type=src->f_type;
  dest->f_bsize=src->f_bsize;
  dest->f_frsize=src->f_frsize;
  dest->f_blocks=src->f_blocks;
  dest->f_bfree=src->f_bfree;
  dest->f_files=src->f_files;
  dest->f_ffree=src->f_ffree;
  dest->f_bavail=src->f_bavail;
  dest->f_fsid=src->f_fsid;
  dest->f_namelen=src->f_namelen;
}

#endif
