/* mvme-print.c -- print a string on the output device.
 *
 * Copyright (c) 1996 Cygnus Support
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

/*
 * write -- write some bytes to the output device.
 */

int
write (fd, ptr, len)
     int fd;
     char *ptr;
     unsigned len;
{
  char *done = ptr + len;
  char *q;
  unsigned len2;

  while (ptr < done)
    {
      if (*ptr == '\n')
	{
	  __pcrlf ();
	  ptr++;
	}
      else
	{
	  q = ptr;
	  while ( (q < done) && ((ptr - q) < 254))
	    {
	      if (*q == '\n')
		{
		  __outln (ptr, q);
		  ptr = ++q;
		}
	      else
		q++;
	    }

	  if (ptr != q)
	    {
	      __outstr (ptr, q);
	      ptr = q;
	    }
	}
    }
  return len;
}

/*
 * print -- do a raw print of a string
 */

void
print (ptr)
     char *ptr;
{
  int len = 0;
  char *p = ptr;

  while (*p != '\0')
    p++;

  write (1, ptr, p-ptr);
}
