/* mvme-read.c -- read bytes from a input device.
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

extern int inbyte ();
extern char * __inln ();

/*
 * read  -- read bytes from the serial port. Ignore fd, since
 *          we only have stdin.
 */
int
read (fd, buf, nbytes)
     int fd;
     char *buf;
     int nbytes;
{
  if (nbytes >= 256)
    {
      char *read_end = __inln (buf);
      *read_end = '\n';
      return read_end - buf + 1;
    }
  else
    {
      int i, c;
      for (i = 0; i < nbytes; i++) {
	*buf++ = c = inbyte ();
	if (c == '\n' || c == '\r') {
	  buf[-1] = '\n';	/* convert \r to \n */
	  buf[0] = '\0';
	  break;
	}
      }

      return i;
    }
}
