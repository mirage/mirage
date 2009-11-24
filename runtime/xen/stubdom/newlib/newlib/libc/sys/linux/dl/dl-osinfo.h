/* Operating system specific code  for generic dynamic loader functions.
   Copyright (C) 2000, 2001 Free Software Foundation, Inc.
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

#include <string.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>
#include "kernel-features.h"

#ifndef MIN
# define MIN(a,b) (((a)<(b))?(a):(b))
#endif

#ifdef SHARED
/* This is the function used in the dynamic linker to print the fatal error
   message.  */
static inline void
__attribute__ ((__noreturn__))
dl_fatal (const char *str)
{
  _dl_dprintf (2, str);
  _exit (1);
}
#endif


#define DL_SYSDEP_OSCHECK(FATAL) \
  do {									      \
    /* Test whether the kernel is new enough.  This test is only	      \
       performed if the library is not compiled to run on all		      \
       kernels.  */							      \
    if (__LINUX_KERNEL_VERSION > 0)					      \
      {									      \
	char bufmem[64];						      \
	char *buf = bufmem;						      \
	unsigned int version;						      \
	int parts;							      \
	char *cp;							      \
	struct utsname uts;						      \
									      \
	/* Try the uname syscall */					      \
	if (__uname (&uts))					      	      \
	  {							      	      \
	    /* This was not successful.  Now try reading the /proc	      \
	       filesystem.  */						      \
	    ssize_t reslen;						      \
	    int fd = __open ("/proc/sys/kernel/osrelease", O_RDONLY);	      \
	    if (fd == -1						      \
		|| (reslen = __read (fd, bufmem, sizeof (bufmem))) <= 0)      \
  	      /* This also didn't work.  We give up since we cannot	      \
		 make sure the library can actually work.  */		      \
	      FATAL ("FATAL: cannot determine library version\n");	      \
	    __close (fd);						      \
	    buf[MIN (reslen, (ssize_t) sizeof (bufmem) - 1)] = '\0';	      \
	  }								      \
	else								      \
          buf = uts.release;						      \
									      \
	/* Now convert it into a number.  The string consists of at most      \
	   three parts.  */						      \
	version = 0;							      \
	parts = 0;							      \
	cp = buf;							      \
	while ((*cp >= '0') && (*cp <= '9'))				      \
	  {								      \
	    unsigned int here = *cp++ - '0';				      \
									      \
	    while ((*cp >= '0') && (*cp <= '9'))			      \
	      {								      \
		here *= 10;						      \
		here += *cp++ - '0';					      \
	      }								      \
									      \
	    ++parts;							      \
	    version <<= 8;						      \
	    version |= here;						      \
									      \
	    if (*cp++ != '.')						      \
	      /* Another part following?  */				      \
	      break;							      \
	  }								      \
									      \
	if (parts < 3)							      \
	  version <<= 8 * (3 - parts);					      \
									      \
	/* Now we can test with the required version.  */		      \
	if (version < __LINUX_KERNEL_VERSION)				      \
	  /* Not sufficent.  */						      \
	  FATAL ("FATAL: kernel too old\n");				      \
									      \
	_dl_osversion = version;					      \
      }									      \
  } while (0)
