#define _FILE_OFFSET_BITS 64
#include <sys/statvfs.h>
#include <sys/statfs.h>

void __statvfs_cvt(struct statfs* from,struct statvfs* to);

void __statvfs_cvt(struct statfs* from,struct statvfs* to) {
  to->f_bsize=from->f_bsize;
  to->f_frsize=from->f_frsize;
  to->f_blocks=from->f_blocks;
  to->f_bfree=from->f_bfree;
  to->f_bavail=from->f_bavail;
  to->f_files=from->f_files;
  to->f_ffree=from->f_ffree;
  to->f_favail=from->f_ffree;
  to->f_fsid=from->f_fsid.__val[0];
  to->f_flag=0;
  to->f_namemax=from->f_namelen;
}
