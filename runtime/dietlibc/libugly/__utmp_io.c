#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

void *__utmp_io(int fd, void *ut, ssize_t len, off_t *offset, int type);

/* type:  F_RDLCK or F_WRLCK */
void *
__utmp_io(int fd, void *ut, ssize_t len, off_t *offset, int type) {
  int e, ret;
  struct flock fl;
  off_t newoffset;

  fl.l_whence	= SEEK_CUR;
  fl.l_start	= 0;
  fl.l_len	= len;
  fl.l_pid	= 0;
  fl.l_type	= type;
  
  if (fcntl(fd, F_SETLKW, &fl)) return 0;
  if (type == F_WRLCK) {
      ret = write(fd, ut, len);
      e = errno;
      fsync (fd);
      /* FIXME - where exactly should the offset point after a write? */
      newoffset = lseek (fd, 0, SEEK_CUR);
   } else {
      newoffset = lseek (fd, 0, SEEK_CUR);
      ret = read(fd, ut, len);
      e = errno;
  }

  fl.l_start	= -(len);
  fl.l_type	= F_UNLCK;

  fcntl(fd, F_SETLK, &fl);

  /* Arrrgh! There's no provision in the POSIX utmp spec for detecting errors.
   * Stupidly update the offset. */
  if (offset)
      *offset = newoffset;

  errno = e;
  if (ret != len) 
      return (void *)0;
  return ut;
}
