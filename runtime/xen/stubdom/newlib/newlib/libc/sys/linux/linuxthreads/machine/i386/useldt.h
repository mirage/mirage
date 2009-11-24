/* Special definitions for ix86 machine using segment register based
   thread descriptor.
   Copyright (C) 1998, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the GNU C Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

#include <stddef.h>	/* For offsetof.  */
#include <stdlib.h>	/* For abort().  */


/* We don't want to include the kernel header.  So duplicate the
   information.  */

/* Structure passed on `modify_ldt' call.  */
struct modify_ldt_ldt_s
{
  unsigned int entry_number;
  unsigned long int base_addr;
  unsigned int limit;
  unsigned int seg_32bit:1;
  unsigned int contents:2;
  unsigned int read_exec_only:1;
  unsigned int limit_in_pages:1;
  unsigned int seg_not_present:1;
  unsigned int useable:1;
  unsigned int empty:25;
};

/* System call to set LDT entry.  */
extern int __modify_ldt (int, struct modify_ldt_ldt_s *, size_t);


/* Return the thread descriptor for the current thread.

   The contained asm must *not* be marked volatile since otherwise
   assignments like
	pthread_descr self = thread_self();
   do not get optimized away.  */
#define THREAD_SELF \
({									      \
  register pthread_descr __self;					      \
  __asm__ ("movl %%gs:%c1,%0" : "=r" (__self)				      \
	   : "i" (offsetof (struct _pthread_descr_struct,		      \
			    p_header.data.self)));			      \
  __self;								      \
})

/* Initialize the thread-unique value.  */
#define INIT_THREAD_SELF(descr, nr) \
{									      \
  struct modify_ldt_ldt_s ldt_entry =					      \
    { nr, (unsigned long int) descr, sizeof (*descr), 1, 0, 0, 0, 0, 1, 0 };  \
  if (__modify_ldt (1, &ldt_entry, sizeof (ldt_entry)) != 0)		      \
    abort ();								      \
  __asm__ __volatile__ ("movw %w0, %%gs" : : "q" (nr * 8 + 7));		      \
}

/* Free resources associated with thread descriptor.  */
#define FREE_THREAD(descr, nr) \
{									      \
  struct modify_ldt_ldt_s ldt_entry =					      \
    { nr, 0, 0, 0, 0, 1, 0, 1, 0, 0 };					      \
  __modify_ldt (1, &ldt_entry, sizeof (ldt_entry));			      \
}

/* Read member of the thread descriptor directly.  */
#define THREAD_GETMEM(descr, member) \
({									      \
  __typeof__ (descr->member) __value;					      \
  if (sizeof (__value) == 1)						      \
    __asm__ __volatile__ ("movb %%gs:%P2,%b0"				      \
			  : "=q" (__value)				      \
			  : "0" (0),					      \
			    "i" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else if (sizeof (__value) == 4)					      \
    __asm__ __volatile__ ("movl %%gs:%P1,%0"				      \
			  : "=r" (__value)				      \
			  : "i" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else									      \
    {									      \
      if (sizeof (__value) != 8)					      \
	/* There should not be any value with a size other than 1, 4 or 8.  */\
	abort ();							      \
									      \
      __asm__ __volatile__ ("movl %%gs:%P1,%%eax\n\t"			      \
			    "movl %%gs:%P2,%%edx"			      \
			    : "=A" (__value)				      \
			    : "i" (offsetof (struct _pthread_descr_struct,    \
					     member)),			      \
			      "i" (offsetof (struct _pthread_descr_struct,    \
					     member) + 4));		      \
    }									      \
  __value;								      \
})

/* Same as THREAD_GETMEM, but the member offset can be non-constant.  */
#define THREAD_GETMEM_NC(descr, member) \
({									      \
  __typeof__ (descr->member) __value;					      \
  if (sizeof (__value) == 1)						      \
    __asm__ __volatile__ ("movb %%gs:(%2),%b0"				      \
			  : "=q" (__value)				      \
			  : "0" (0),					      \
			    "r" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else if (sizeof (__value) == 4)					      \
    __asm__ __volatile__ ("movl %%gs:(%1),%0"				      \
			  : "=r" (__value)				      \
			  : "r" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else									      \
    {									      \
      if (sizeof (__value) != 8)					      \
	/* There should not be any value with a size other than 1, 4 or 8.  */\
	abort ();							      \
									      \
      __asm__ __volatile__ ("movl %%gs:(%1),%%eax\n\t"			      \
			    "movl %%gs:4(%1),%%edx"			      \
			    : "=&A" (__value)				      \
			    : "r" (offsetof (struct _pthread_descr_struct,    \
					     member)));			      \
    }									      \
  __value;								      \
})

/* Same as THREAD_SETMEM, but the member offset can be non-constant.  */
#define THREAD_SETMEM(descr, member, value) \
({									      \
  __typeof__ (descr->member) __value = (value);				      \
  if (sizeof (__value) == 1)						      \
    __asm__ __volatile__ ("movb %0,%%gs:%P1" :				      \
			  : "q" (__value),				      \
			    "i" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else if (sizeof (__value) == 4)					      \
    __asm__ __volatile__ ("movl %0,%%gs:%P1" :				      \
			  : "r" (__value),				      \
			    "i" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else									      \
    {									      \
      if (sizeof (__value) != 8)					      \
	/* There should not be any value with a size other than 1, 4 or 8.  */\
	abort ();							      \
									      \
      __asm__ __volatile__ ("movl %%eax,%%gs:%P1\n\n"			      \
			    "movl %%edx,%%gs:%P2" :			      \
			    : "A" (__value),				      \
			      "i" (offsetof (struct _pthread_descr_struct,    \
					     member)),			      \
			      "i" (offsetof (struct _pthread_descr_struct,    \
					     member) + 4));		      \
    }									      \
})

/* Set member of the thread descriptor directly.  */
#define THREAD_SETMEM_NC(descr, member, value) \
({									      \
  __typeof__ (descr->member) __value = (value);				      \
  if (sizeof (__value) == 1)						      \
    __asm__ __volatile__ ("movb %0,%%gs:(%1)" :				      \
			  : "q" (__value),				      \
			    "r" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else if (sizeof (__value) == 4)					      \
    __asm__ __volatile__ ("movl %0,%%gs:(%1)" :				      \
			  : "r" (__value),				      \
			    "r" (offsetof (struct _pthread_descr_struct,      \
					   member)));			      \
  else									      \
    {									      \
      if (sizeof (__value) != 8)					      \
	/* There should not be any value with a size other than 1, 4 or 8.  */\
	abort ();							      \
									      \
      __asm__ __volatile__ ("movl %%eax,%%gs:(%1)\n\t"			      \
			    "movl %%edx,%%gs:4(%1)" :			      \
			    : "A" (__value),				      \
			      "r" (offsetof (struct _pthread_descr_struct,    \
					     member)));			      \
    }									      \
})

/* We want the OS to assign stack addresses.  */
#define FLOATING_STACKS	1

/* Maximum size of the stack if the rlimit is unlimited.  */
#define ARCH_STACK_MAX_SIZE	8*1024*1024
