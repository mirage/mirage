/*
 * ads-io.c -- stub io functions for targets using the sds monitor
 *
 * Copyright (c) 1998 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

int inbyte(void)
{
  return -1;
}


void outbyte(char c)
{
}


/*
 * write -- write some bytes to the output device.
 */

int
write (int fd, char *ptr, unsigned len)
{
  return len;
}


/*
 * print -- do a raw print of a string
 */ 
void
print (char *ptr)
{
}


/*
 * read  -- read bytes from the serial port. Ignore fd, since
 *          we only have stdin.
 */
int read (int fd, char *buf, int nbytes)
{
  return -1;
}
