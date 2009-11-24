/* Miscellaneous support functions for dynamic linker
   Copyright (C) 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <assert.h>
#include <fcntl.h>
#include <ldsodefs.h>
#include <limits.h>
#include <link.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/uio.h>

#ifndef MAP_ANON
/* This is the only dl-sysdep.c function that is actually needed at run-time
   by _dl_map_object.  */

int
_dl_sysdep_open_zero_fill (void)
{
  return __open ("/dev/zero", O_RDONLY);
}
#endif

/* Read the whole contents of FILE into new mmap'd space with given
   protections.  *SIZEP gets the size of the file.  On error MAP_FAILED
   is returned.  */

void *
internal_function
_dl_sysdep_read_whole_file (const char *file, size_t *sizep, int prot)
{
  void *result = MAP_FAILED;
  struct stat64 st;
  int fd = __open (file, O_RDONLY);
  if (fd >= 0)
    {
      if (fstat64 (fd, &st) >= 0)
	{
	  *sizep = st.st_size;

	  /* No need to map the file if it is empty.  */
	  if (*sizep != 0)
	    /* Map a copy of the file contents.  */
	    result = mmap (NULL, *sizep, prot,
#ifdef MAP_COPY
			     MAP_COPY
#else
			     MAP_PRIVATE
#endif
#ifdef MAP_FILE
			     | MAP_FILE
#endif
			     , fd, 0);
	}
      close (fd);
    }
  return result;
}


/* Descriptor to write debug messages to.  */
int _dl_debug_fd = 2;


/* Bare-bone printf implementation.  This function only knows about
   the formats and flags needed and can handle only up to 64 stripes in
   the output.  */
static void
_dl_debug_vdprintf (int fd, int tag_p, const char *fmt, va_list arg)
{
  const int niovmax = 64;
  struct iovec iov[niovmax];
  int niov = 0;
  pid_t pid = 0;
  char pidbuf[7];

  while (*fmt != '\0')
    {
      const char *startp = fmt;

      if (tag_p > 0)
	{
	  /* Generate the tag line once.  It consists of the PID and a
	     colon followed by a tab.  */
	  if (pid == 0)
	    {
	      char *p = "0";
	      pid = __getpid ();
	      assert (pid >= 0 && pid < 100000);
	      while (p > pidbuf)
		*--p = '0';
	      pidbuf[5] = ':';
	      pidbuf[6] = '\t';
	    }

	  /* Append to the output.  */
	  assert (niov < niovmax);
	  iov[niov].iov_len = 7;
	  iov[niov++].iov_base = pidbuf;

	  /* No more tags until we see the next newline.  */
	  tag_p = -1;
	}

      /* Skip everything except % and \n (if tags are needed).  */
      while (*fmt != '\0' && *fmt != '%' && (! tag_p || *fmt != '\n'))
	++fmt;

      /* Append constant string.  */
      assert (niov < niovmax);
      if ((iov[niov].iov_len = fmt - startp) != 0)
	iov[niov++].iov_base = (char *) startp;

      if (*fmt == '%')
	{
	  /* It is a format specifier.  */
	  char fill = ' ';
	  int width = -1;
#if LONG_MAX != INT_MAX
	  int long_mod = 0;
#endif

	  /* Recognize zero-digit fill flag.  */
	  if (*++fmt == '0')
	    {
	      fill = '0';
	      ++fmt;
	    }

	  /* See whether with comes from a parameter.  Note that no other
	     way to specify the width is implemented.  */
	  if (*fmt == '*')
	    {
	      width = va_arg (arg, int);
	      ++fmt;
	    }

	  /* Recognize the l modifier.  It is only important on some
	     platforms where long and int have a different size.  We
	     can use the same code for size_t.  */
	  if (*fmt == 'l' || *fmt == 'Z')
	    {
#if LONG_MAX != INT_MAX
	      long_mod = 1;
#endif
	      ++fmt;
	    }

	  switch (*fmt)
	    {
	      /* Integer formatting.  */
	    case 'u':
	    case 'x':
	      {
		/* We have to make a difference if long and int have a
		   different size.  */
#if LONG_MAX != INT_MAX
		unsigned long int num = (long_mod
					 ? va_arg (arg, unsigned long int)
					 : va_arg (arg, unsigned int));
#else
		unsigned long int num = va_arg (arg, unsigned int);
#endif
		/* We use alloca() to allocate the buffer with the most
		   pessimistic guess for the size.  Using alloca() allows
		   having more than one integer formatting in a call.  */
		char *buf = (char *) alloca (3 * sizeof (unsigned long int));
		char *endp = &buf[3 * sizeof (unsigned long int)];
		char *cp = "0"; 

		/* Pad to the width the user specified.  */
		if (width != -1)
		  while (endp - cp < width)
		    *--cp = fill;

		iov[niov].iov_base = cp;
		iov[niov].iov_len = endp - cp;
		++niov;
	      }
	      break;

	    case 's':
	      /* Get the string argument.  */
	      iov[niov].iov_base = va_arg (arg, char *);
	      iov[niov].iov_len = strlen (iov[niov].iov_base);
	      ++niov;
	      break;

	    case '%':
	      iov[niov].iov_base = (void *) fmt;
	      iov[niov].iov_len = 1;
	      ++niov;
	      break;

	    default:
	      assert (! "invalid format specifier");
	    }
	  ++fmt;
	}
      else if (*fmt == '\n')
	{
	  /* See whether we have to print a single newline character.  */
	  if (fmt == startp)
	    {
	      iov[niov].iov_base = (char *) startp;
	      iov[niov++].iov_len = 1;
	    }
	  else
	    /* No, just add it to the rest of the string.  */
	    ++iov[niov - 1].iov_len;

	  /* Next line, print a tag again.  */
	  tag_p = 1;
	  ++fmt;
	}
    }

  /* Finally write the result.  */
  writev (fd, iov, niov);
}


/* Write to debug file.  */
void
_dl_debug_printf (const char *fmt, ...)
{
  va_list arg;

  va_start (arg, fmt);
  _dl_debug_vdprintf (_dl_debug_fd, 1, fmt, arg);
  va_end (arg);
}


/* Write to debug file but don't start with a tag.  */
void
_dl_debug_printf_c (const char *fmt, ...)
{
  va_list arg;

  va_start (arg, fmt);
  _dl_debug_vdprintf (_dl_debug_fd, -1, fmt, arg);
  va_end (arg);
}


/* Write the given file descriptor.  */
void
_dl_dprintf (int fd, const char *fmt, ...)
{
  va_list arg;

  va_start (arg, fmt);
  _dl_debug_vdprintf (fd, 0, fmt, arg);
  va_end (arg);
}
