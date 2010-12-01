#include <errno.h>
#include "dietfeatures.h"

#include <sys/stat.h>
#ifndef __NO_STAT64
#include <unistd.h>

loff_t lseek64(int fildes, loff_t offset, int whence) {
  loff_t tmp;
  if (llseek(fildes,(unsigned long)(offset>>32),(unsigned long)offset&0xffffffff,&tmp,whence)) {
    if (errno!=ENOSYS) return -1;
    return (loff_t)lseek(fildes,(off_t)offset,whence);
  }
  return tmp;
}
#endif
