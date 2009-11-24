/*
 * Copyright (c) 2003  Red Hat, Inc. All rights reserved.
 *
 * This copyrighted material is made available to anyone wishing to use, modify,
 * copy, or redistribute it subject to the terms and conditions of the BSD 
 * License.  This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY expressed or implied, including the implied 
 * warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy 
 * of this license is available at http://www.opensource.org/licenses. Any 
 * Red Hat trademarks that are incorporated in the source code or documentation
 * are not subject to the BSD License and may only be used or replicated with 
 * the express permission of Red Hat, Inc.
 */

#include <errno.h>

extern int __heap __far;      /* beginning of heap */
extern int __heap_end __far;  /* if at address 0, use stack pointer as limit */

static char *the_break = (char *)(& __heap);

int
is_addr_0 (int address)
{
  return address ? 0 : 1;
}

void *
sbrk(int inc)
{
  char *current_heap_limit = (char *) (& __heap_end);

  /* is_addr_0 avoids optimizing out this block.  */
  if (is_addr_0 ((int) current_heap_limit))
    {
      int something;
      int margin = 4096;
      current_heap_limit = (char *) (& something) - margin;
    }

  if ((the_break + inc) < current_heap_limit)
    {
      void *rv = (void *) the_break;
      the_break += inc;
      return rv;
    }
  else
    {
      errno = ENOMEM;
      return (void *) -1;
    }
}

int
brk (void *ptr)
{
  the_break = ptr;
  return 0;
}
