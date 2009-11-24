/***
**** CAUTION!!! KEEP DOC CONSISTENT---if you change text of a message
****            here, change two places:
****            1) the leading doc section (alphabetized by macro)
****            2) the real text inside switch(errnum)
***/

/*
FUNCTION
	<<strerror>>---convert error number to string

INDEX
	strerror

ANSI_SYNOPSIS
	#include <string.h>
	char *strerror(int <[errnum]>);

TRAD_SYNOPSIS
	#include <string.h>
	char *strerror(<[errnum]>)
	int <[errnum]>;

DESCRIPTION
<<strerror>> converts the error number <[errnum]> into a
string.  The value of <[errnum]> is usually a copy of <<errno>>.
If <<errnum>> is not a known error number, the result points to an
empty string.

This implementation of <<strerror>> prints out the following strings
for each of the values defined in `<<errno.h>>':

o+
o E2BIG
Arg list too long

o EACCES
Permission denied

o EADDRINUSE
Address already in use

o EADV
Advertise error

o EAFNOSUPPORT
Address family not supported by protocol family

o EAGAIN
No more processes

o EALREADY
Socket already connected

o EBADF
Bad file number

o EBADMSG
Bad message

o EBUSY
Device or resource busy

o ECHILD
No children

o ECOMM
Communication error

o ECONNABORTED
Software caused connection abort

o ECONNREFUSED
Connection refused

o EDEADLK
Deadlock

o EDESTADDRREQ
Destination address required

o EEXIST
File exists

o EDOM
Math argument

o EFAULT
Bad address

o EFBIG
File too large

o EHOSTDOWN
Host is down

o EHOSTUNREACH
Host is unreachable

o EIDRM
Identifier removed

o EINPROGRESS
Connection already in progress

o EINTR
Interrupted system call

o EINVAL
Invalid argument

o EIO
I/O error

o EISCONN
Socket is already connected

o EISDIR
Is a directory

o ELIBACC
Cannot access a needed shared library

o ELIBBAD
Accessing a corrupted shared library

o ELIBEXEC
Cannot exec a shared library directly

o ELIBMAX
Attempting to link in more shared libraries than system limit

o ELIBSCN
<<.lib>> section in a.out corrupted

o EMFILE
Too many open files

o EMLINK
Too many links

o EMSGSIZE
Message too long

o EMULTIHOP
Multihop attempted

o ENAMETOOLONG
File or path name too long

o ENETDOWN
Network interface not configured

o ENETUNREACH
Network is unreachable

o ENFILE
Too many open files in system

o ENODEV
No such device

o ENOENT
No such file or directory

o ENOEXEC
Exec format error

o ENOLCK
No lock

o ENOLINK
Virtual circuit is gone

o ENOMEM
Not enough space

o ENOMSG
No message of desired type

o ENONET
Machine is not on the network

o ENOPKG
No package

o ENOPROTOOPT
Protocol not available

o ENOSPC
No space left on device

o ENOSR
No stream resources

o ENOSTR
Not a stream

o ENOSYS
Function not implemented

o ENOTBLK
Block device required

o ENOTCONN
Socket is not connected

o ENOTDIR
Not a directory

o ENOTEMPTY
Directory not empty

o ENOTSOCK
Socket operation on non-socket

o ENOTSUP
Not supported

o ENOTTY
Not a character device

o ENXIO
No such device or address

o EPERM
Not owner

o EPIPE
Broken pipe

o EPROTO
Protocol error

o EPROTOTYPE
Protocol wrong type for socket

o EPROTONOSUPPORT
Unknown protocol

o ERANGE
Result too large

o EREMOTE
Resource is remote

o EROFS
Read-only file system

o ESHUTDOWN
Can't send after socket shutdown

o ESOCKTNOSUPPORT
Socket type not supported

o ESPIPE
Illegal seek

o ESRCH
No such process

o ESRMNT
Srmount error

o ETIME
Stream ioctl timeout

o ETIMEDOUT
Connection timed out

o ETXTBSY
Text file busy

o EXDEV
Cross-device link

o-

RETURNS
This function returns a pointer to a string.  Your application must
not modify that string.

PORTABILITY
ANSI C requires <<strerror>>, but does not specify the strings used
for each error number.

Although this implementation of <<strerror>> is reentrant, ANSI C
declares that subsequent calls to <<strerror>> may overwrite the
result string; therefore portable code cannot depend on the reentrancy
of this subroutine.

This implementation of <<strerror>> provides for user-defined
extensibility.  <<errno.h>> defines <[__ELASTERROR]>, which can be
used as a base for user-defined error values.  If the user supplies a
routine named <<_user_strerror>>, and <[errnum]> passed to
<<strerror>> does not match any of the supported values,
<<_user_strerror>> is called with <[errnum]> as its argument.

<<_user_strerror>> takes one argument of type <[int]>, and returns a
character pointer.  If <[errnum]> is unknown to <<_user_strerror>>,
<<_user_strerror>> returns <[NULL]>.  The default <<_user_strerror>>
returns <[NULL]> for all input values.

<<strerror>> requires no supporting OS subroutines.

QUICKREF
	strerror ansi pure
*/

#include <errno.h>
#include <string.h>

char *
_DEFUN (strerror, (errnum),
	int errnum)
{
  char *error;
  extern char *_user_strerror _PARAMS ((int));

  switch (errnum)
    {
/* go32 defines EPERM as EACCES */
#if defined (EPERM) && (!defined (EACCES) || (EPERM != EACCES))
    case EPERM:
      error = "Not owner";
      break;
#endif
#ifdef ENOENT
    case ENOENT:
      error = "No such file or directory";
      break;
#endif
#ifdef ESRCH
    case ESRCH:
      error = "No such process";
      break;
#endif
#ifdef EINTR
    case EINTR:
      error = "Interrupted system call";
      break;
#endif
#ifdef EIO
    case EIO:
      error = "I/O error";
      break;
#endif
/* go32 defines ENXIO as ENODEV */
#if defined (ENXIO) && (!defined (ENODEV) || (ENXIO != ENODEV))
    case ENXIO:
      error = "No such device or address";
      break;
#endif
#ifdef E2BIG
    case E2BIG:
      error = "Arg list too long";
      break;
#endif
#ifdef ENOEXEC
    case ENOEXEC:
      error = "Exec format error";
      break;
#endif
#ifdef EALREADY
    case EALREADY:
      error = "Socket already connected";
      break;
#endif
#ifdef EBADF
    case EBADF:
      error = "Bad file number";
      break;
#endif
#ifdef ECHILD
    case ECHILD:
      error = "No children";
      break;
#endif
#ifdef EDESTADDRREQ
    case EDESTADDRREQ:
      error = "Destination address required";
      break;
#endif
#ifdef EAGAIN
    case EAGAIN:
      error = "No more processes";
      break;
#endif
#ifdef ENOMEM
    case ENOMEM:
      error = "Not enough space";
      break;
#endif
#ifdef EACCES
    case EACCES:
      error = "Permission denied";
      break;
#endif
#ifdef EFAULT
    case EFAULT:
      error = "Bad address";
      break;
#endif
#ifdef ENOTBLK
    case ENOTBLK:
      error = "Block device required";
      break;
#endif
#ifdef EBUSY
    case EBUSY:
      error = "Device or resource busy";
      break;
#endif
#ifdef EEXIST
    case EEXIST:
      error = "File exists";
      break;
#endif
#ifdef EXDEV
    case EXDEV:
      error = "Cross-device link";
      break;
#endif
#ifdef ENODEV
    case ENODEV:
      error = "No such device";
      break;
#endif
#ifdef ENOTDIR
    case ENOTDIR:
      error = "Not a directory";
      break;
#endif
#ifdef EHOSTDOWN
    case EHOSTDOWN:
      error = "Host is down";
      break;
#endif
#ifdef EINPROGRESS 
    case EINPROGRESS:
      error = "Connection already in progress";
      break;
#endif
#ifdef EISDIR
    case EISDIR:
      error = "Is a directory";
      break;
#endif
#ifdef EINVAL
    case EINVAL:
      error = "Invalid argument";
      break;
#endif
#ifdef ENETDOWN
    case ENETDOWN:
      error = "Network interface is not configured";
      break;
#endif
#ifdef ENFILE
    case ENFILE:
      error = "Too many open files in system";
      break;
#endif
#ifdef EMFILE
    case EMFILE:
      error = "Too many open files";
      break;
#endif
#ifdef ENOTTY
    case ENOTTY:
      error = "Not a character device";
      break;
#endif
#ifdef ETXTBSY
    case ETXTBSY:
      error = "Text file busy";
      break;
#endif
#ifdef EFBIG
    case EFBIG:
      error = "File too large";
      break;
#endif
#ifdef EHOSTUNREACH
    case EHOSTUNREACH:
      error = "Host is unreachable";
      break;
#endif
#ifdef ENOSPC
    case ENOSPC:
      error = "No space left on device";
      break;
#endif
#ifdef ENOTSUP
    case ENOTSUP:
      error = "Not supported";
      break;
#endif
#ifdef ESPIPE
    case ESPIPE:
      error = "Illegal seek";
      break;
#endif
#ifdef EROFS
    case EROFS:
      error = "Read-only file system";
      break;
#endif
#ifdef EMLINK
    case EMLINK:
      error = "Too many links";
      break;
#endif
#ifdef EPIPE
    case EPIPE:
      error = "Broken pipe";
      break;
#endif
#ifdef EDOM
    case EDOM:
      error = "Math argument";
      break;
#endif
#ifdef ERANGE
    case ERANGE:
      error = "Result too large";
      break;
#endif
#ifdef ENOMSG
    case ENOMSG:
      error = "No message of desired type";
      break;
#endif
#ifdef EIDRM
    case EIDRM:
      error = "Identifier removed";
      break;
#endif
#ifdef EDEADLK
    case EDEADLK:
      error = "Deadlock";
      break;
#endif
#ifdef ENETUNREACH 
    case  ENETUNREACH:
      error = "Network is unreachable";
      break;
#endif
#ifdef ENOLCK
    case ENOLCK:
      error = "No lock";
      break;
#endif
#ifdef ENOSTR
    case ENOSTR:
      error = "Not a stream";
      break;
#endif
#ifdef ETIME
    case ETIME:
      error = "Stream ioctl timeout";
      break;
#endif
#ifdef ENOSR
    case ENOSR:
      error = "No stream resources";
      break;
#endif
#ifdef ENONET
    case ENONET:
      error = "Machine is not on the network";
      break;
#endif
#ifdef ENOPKG
    case ENOPKG:
      error = "No package";
      break;
#endif
#ifdef EREMOTE
    case EREMOTE:
      error = "Resource is remote";
      break;
#endif
#ifdef ENOLINK
    case ENOLINK:
      error = "Virtual circuit is gone";
      break;
#endif
#ifdef EADV
    case EADV:
      error = "Advertise error";
      break;
#endif
#ifdef ESRMNT
    case ESRMNT:
      error = "Srmount error";
      break;
#endif
#ifdef ECOMM
    case ECOMM:
      error = "Communication error";
      break;
#endif
#ifdef EPROTO
    case EPROTO:
      error = "Protocol error";
      break;
#endif
#ifdef EPROTONOSUPPORT
    case EPROTONOSUPPORT:
      error = "Unknown protocol";
      break;
#endif
#ifdef EMULTIHOP
    case EMULTIHOP:
      error = "Multihop attempted";
      break;
#endif
#ifdef EBADMSG
    case EBADMSG:
      error = "Bad message";
      break;
#endif
#ifdef ELIBACC
    case ELIBACC:
      error = "Cannot access a needed shared library";
      break;
#endif
#ifdef ELIBBAD
    case ELIBBAD:
      error = "Accessing a corrupted shared library";
      break;
#endif
#ifdef ELIBSCN
    case ELIBSCN:
      error = ".lib section in a.out corrupted";
      break;
#endif
#ifdef ELIBMAX
    case ELIBMAX:
      error = "Attempting to link in more shared libraries than system limit";
      break;
#endif
#ifdef ELIBEXEC
    case ELIBEXEC:
      error = "Cannot exec a shared library directly";
      break;
#endif
#ifdef ENOSYS
    case ENOSYS:
      error = "Function not implemented";
      break;
#endif
#ifdef ENMFILE
    case ENMFILE:
      error = "No more files";
      break;
#endif
#ifdef ENOTEMPTY
    case ENOTEMPTY:
      error = "Directory not empty";
      break;
#endif
#ifdef ENAMETOOLONG
    case ENAMETOOLONG:
      error = "File or path name too long";
      break;
#endif
#ifdef ELOOP
    case ELOOP:
      error = "Too many symbolic links";
      break;
#endif
#ifdef ENOBUFS
    case ENOBUFS:
      error = "No buffer space available";
      break;
#endif
#ifdef EAFNOSUPPORT
    case EAFNOSUPPORT:
      error = "Address family not supported by protocol family";
      break;
#endif
#ifdef EPROTOTYPE
    case EPROTOTYPE:
      error = "Protocol wrong type for socket";
      break;
#endif
#ifdef ENOTSOCK
    case ENOTSOCK:
      error = "Socket operation on non-socket";
      break;
#endif
#ifdef ENOPROTOOPT
    case ENOPROTOOPT:
      error = "Protocol not available";
      break;
#endif
#ifdef ESHUTDOWN
    case ESHUTDOWN:
      error = "Can't send after socket shutdown";
      break;
#endif
#ifdef ECONNREFUSED
    case ECONNREFUSED:
      error = "Connection refused";
      break;
#endif
#ifdef EADDRINUSE
    case EADDRINUSE:
      error = "Address already in use";
      break;
#endif
#ifdef ECONNABORTED
    case ECONNABORTED:
      error = "Software caused connection abort";
      break;
#endif
#if (defined(EWOULDBLOCK) && (!defined (EAGAIN) || (EWOULDBLOCK != EAGAIN)))
    case EWOULDBLOCK:
        error = "Operation would block";
        break;
#endif
#ifdef ENOTCONN
    case ENOTCONN:
        error = "Socket is not connected";
        break;
#endif
#ifdef ESOCKTNOSUPPORT
    case ESOCKTNOSUPPORT:
        error = "Socket type not supported";
        break;
#endif
#ifdef EISCONN
    case EISCONN:
        error = "Socket is already connected";
        break;
#endif
#if defined(EOPNOTSUPP) && (!defined(ENOTSUP) || (ENOTSUP != EOPNOTSUPP))
    case EOPNOTSUPP:
        error = "Operation not supported on socket";
        break;
#endif
#ifdef EMSGSIZE
    case EMSGSIZE:
        error = "Message too long";
        break;
#endif
#ifdef ETIMEDOUT
    case ETIMEDOUT:
        error = "Connection timed out";
        break;
#endif
    default:
      if ((error = _user_strerror (errnum)) == 0)
	error = "";
      break;
    }

  return error;
}
