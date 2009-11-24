/*
FUNCTION
<<pread64>>---read a large file from specified position

INDEX
	pread64

ANSI_SYNOPSIS
	#include <unistd.h>
	ssize_t pread64(int <[fd]>, void *<[buf]>, size_t <[n]>, loff_t <[off]>);

TRAD_SYNOPSIS
	#include <unistd.h>
	ssize_t pread64(<[fd]>, <[buf]>, <[n]>, <[off]>)
	int <[fd]>;
	void *<[buf]>;
	size_t <[n]>;
	loff_t <[off]>;

DESCRIPTION
The <<pread64>> function is similar to <<pread>>.  The only difference is
that it operates on large files and so takes a 64-bit offset.  Like <<pread>>>,
the file position is unchanged by the function (i.e. the file position
is the same before and after a call to <<pread>>).

RETURNS
<<pread64>> returns the number of bytes read or <<-1>> if failure occurred.

PORTABILITY
<<pread64>> is an EL/IX extension.

Supporting OS subroutine required: <<read>>, <<lseek64>>.
*/

#include <_ansi.h>
#include <unistd.h>
#include <reent.h>
#include <machine/weakalias.h>

ssize_t
_DEFUN (__libc_pread64, (fd, buf, n, off),
     int fd _AND
     _PTR buf _AND
     size_t n _AND
     loff_t off)
{
  loff_t cur_pos;
  _READ_WRITE_RETURN_TYPE num_read;
  
  if ((cur_pos = lseek64 (fd, 0, SEEK_CUR)) == (loff_t)-1)
    return -1;

  if (lseek64 (fd, off, SEEK_SET) == (loff_t)-1)
    return -1;

  num_read = read (fd, buf, n);

  if (lseek64 (fd, cur_pos, SEEK_SET) == (loff_t)-1)
    return -1;

  return (ssize_t)num_read;
}
weak_alias(__libc_pread64,pread64);
weak_alias(__libc_pread64,__pread64);

