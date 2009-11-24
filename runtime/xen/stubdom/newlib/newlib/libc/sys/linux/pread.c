/* Linux version of pread so we can have a weak_alias */

#include <_ansi.h>
#include <unistd.h>
#include <reent.h>
#include <machine/weakalias.h>

ssize_t
_DEFUN (_pread_r, (rptr, fd, buf, n, off),
     struct _reent *rptr _AND
     int fd _AND
     _PTR buf _AND
     size_t n _AND
     off_t off)
{
  off_t cur_pos;
  _READ_WRITE_RETURN_TYPE num_read;
  
  if ((cur_pos = _lseek_r (rptr, fd, 0, SEEK_CUR)) == (off_t)-1)
    return -1;

  if (_lseek_r (rptr, fd, off, SEEK_SET) == (off_t)-1)
    return -1;

  num_read = _read_r (rptr, fd, buf, n);

  if (_lseek_r (rptr, fd, cur_pos, SEEK_SET) == (off_t)-1)
    return -1;

  return (ssize_t)num_read;
}

#ifndef _REENT_ONLY

ssize_t
_DEFUN (__libc_pread, (fd, buf, n, off),
     int fd _AND
     _PTR buf _AND
     size_t n _AND
     off_t off)
{
  return _pread_r (_REENT, fd, buf, n, off);
}
weak_alias(__libc_pread,pread)

#endif
