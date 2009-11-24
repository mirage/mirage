/*
FUNCTION
<<pread>>---read a file from specified position

INDEX
	pread
INDEX
	_pread_r

ANSI_SYNOPSIS
	#include <unistd.h>
	ssize_t pread(int <[fd]>, void *<[buf]>, size_t <[n]>, off_t <[off]>);
	ssize_t _pread_r(struct _reent *<[rptr]>, int <[fd]>, 
                         void *<[buf]>, size_t <[n]>, off_t <[off]>);

TRAD_SYNOPSIS
	#include <unistd.h>
	ssize_t pread(<[fd]>, <[buf]>, <[n]>, <[off]>)
	int <[fd]>;
	void *<[buf]>;
	size_t <[n]>;
	off_t <[off]>;

	ssize_t _pread_r(<[rptr]>, <[fd]>, <[buf]>, <[n]>, <[off]>)
	struct _reent *<[rptr]>;
	int <[fd]>;
	void *<[buf]>;
	size_t <[n]>;
	off_t <[off]>;

DESCRIPTION
The <<pread>> function is similar to <<read>>.  One difference is that
<<pread>> has an additional parameter <[off]> which is the offset to
position in the file before reading.  The function also differs in that
the file position is unchanged by the function (i.e. the file position
is the same before and after a call to <<pread>>).

The <<_pread_r>> function is the same as <<pread>>, only a reentrant
struct pointer <[rptr]> is provided to preserve reentrancy.

RETURNS
<<pread>> returns the number of bytes read or <<-1>> if failure occurred.

PORTABILITY
<<pread>> is non-ANSI and is specified by the Single Unix Specification.

Supporting OS subroutine required: <<read>>, <<lseek>>.
*/

#include <_ansi.h>
#include <unistd.h>
#include <reent.h>

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
_DEFUN (pread, (fd, buf, n, off),
     int fd _AND
     _PTR buf _AND
     size_t n _AND
     off_t off)
{
  return _pread_r (_REENT, fd, buf, n, off);
}

#endif
