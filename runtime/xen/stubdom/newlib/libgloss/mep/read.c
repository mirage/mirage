/* read.c -- read characters from file, with hook.
 * 
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

extern int __mep_read(int, unsigned char *, int);
extern int _ioIn(void) __attribute__((weak));

int
read(int fd, unsigned char *buf, int count)
{
  if (fd == 0 && &_ioIn)
    {
      int c = 0;
      while (c < count)
	{
	  int ch = _ioIn();
	  *buf++ = ch;
	  if (ch == -1)
	    break;
	  c ++;
	}
      return c;
    }
  return __mep_read(fd, buf, count);
}
