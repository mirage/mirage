/* Copyright (c) 1995 Cygnus Support
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
 *
 * fake unix routines for sparclite and remote debugger
 * Many of these routines just substitute an appropriate error status,
 * if you want some kind of file system access, you'll have to fill them in...
 * sbrk on the other hand is functional (malloc uses it) but it doesn't do 
 * any checking for lack of memory. 
 * kill and _exit could get more real implementations, as well.
 */

#include <sys/stat.h>

int
fstat(int _fd, struct stat* _sbuf)
{
  /* this is used in a few places in stdio... */
  /* just error, so they assume a pipe */
  return -1;
}

int
isatty(int _fd)
{
  return 1;
}

int
close(int _fd)
{
  /* return value usually ignored anyhow */
  return 0;
}

int 
open(char *filename)
{
  /* always fail */
  return -1;
}

int 
getpid() {
  return 1;
}

int 
kill(int pid) {
  /* if we knew how to nuke the board, we would... */
  return 0;
}

void
_exit(int status) {
  /* likewise... */
  return;
}

int
lseek(int _fd, off_t offset, int whence)
{
  /* nothing is ever seekable */
  return -1;
}

extern char end;
char*
sbrk(int incr)
{
  static char* base;
  char *b;
  if(!base) base = &end;
  b = base;
  base += incr;
  return b;
}
