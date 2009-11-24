/*
FUNCTION
<<pwrite>>---write a file from specified position

INDEX
	pwrite
INDEX
	_pwrite_r

ANSI_SYNOPSIS
	#include <unistd.h>
	ssize_t pwrite(int <[fd]>, const void *<[buf]>, 
                       size_t <[n]>, off_t <[off]>);
	ssize_t _pwrite_r(struct _reent *<[rptr]>, int <[fd]>, 
                          const void *<[buf]>, size_t <[n]>, off_t <[off]>);

TRAD_SYNOPSIS
	#include <unistd.h>
	ssize_t pwrite(<[fd]>, <[buf]>, <[n]>, <[off]>)
	int <[fd]>;
	const void *<[buf]>;
	size_t <[n]>;
	off_t <[off]>;

	ssize_t _pwrite_r(<[rptr]>, <[fd]>, <[buf]>, <[n]>, <[off]>)
	struct _reent *<[rptr]>;
	int <[fd]>;
	const void *<[buf]>;
	size_t <[n]>;
	off_t <[off]>;

DESCRIPTION
The <<pwrite>> function is similar to <<write>>.  One difference is that
<<pwrite>> has an additional parameter <[off]> which is the offset to
position in the file before writing.  The function also differs in that
the file position is unchanged by the function (i.e. the file position
is the same before and after a call to <<pwrite>>).

The <<_pwrite_r>> function is the same as <<pwrite>>, only a reentrant
struct pointer <[rptr]> is provided to preserve reentrancy.

RETURNS
<<pwrite>> returns the number of bytes written or <<-1>> if failure occurred.

PORTABILITY
<<pwrite>> is non-ANSI and is specified by the Single Unix Specification.

Supporting OS subroutine required: <<write>>, <<lseek>>.
*/

#include <_ansi.h>
#include <unistd.h>
#include <reent.h>

ssize_t
_DEFUN (_pwrite_r, (rptr, fd, buf, n, off),
     struct _reent *rptr _AND
     int fd _AND
     _CONST _PTR buf _AND
     size_t n _AND
     off_t off)
{
  off_t cur_pos;
  _READ_WRITE_RETURN_TYPE num_written;
  
  if ((cur_pos = _lseek_r (rptr, fd, 0, SEEK_CUR)) == (off_t)-1)
    return -1;

  if (_lseek_r (rptr, fd, off, SEEK_SET) == (off_t)-1)
    return -1;

  num_written = _write_r (rptr, fd, buf, n);

  if (_lseek_r (rptr, fd, cur_pos, SEEK_SET) == (off_t)-1)
    return -1;

  return (ssize_t)num_written;
}

#ifndef _REENT_ONLY

ssize_t
_DEFUN (pwrite, (fd, buf, n, off),
     int fd _AND
     _CONST _PTR buf _AND
     size_t n _AND
     off_t off)
{
  return _pwrite_r (_REENT, fd, buf, n, off);
}

#endif
