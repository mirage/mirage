/* cfe.c -- I/O code for the MIPS boards running CFE.  */

/*
 * Copyright 2001, 2002, 2003
 * Broadcom Corporation. All rights reserved.
 * 
 * This software is furnished under license and may be used and copied only
 * in accordance with the following terms and conditions.  Subject to these
 * conditions, you may download, copy, install, use, modify and distribute
 * modified or unmodified copies of this software in source and/or binary
 * form. No title or ownership is transferred hereby.
 * 
 * 1) Any source code used, modified or distributed must reproduce and
 *    retain this copyright notice and list of conditions as they appear in
 *    the source file.
 * 
 * 2) No right is granted to use any trade name, trademark, or logo of
 *    Broadcom Corporation.  The "Broadcom Corporation" name may not be
 *    used to endorse or promote products derived from this software
 *    without the prior written permission of Broadcom Corporation.
 * 
 * 3) THIS SOFTWARE IS PROVIDED "AS-IS" AND ANY EXPRESS OR IMPLIED
 *    WARRANTIES, INCLUDING BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF
 *    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
 *    NON-INFRINGEMENT ARE DISCLAIMED. IN NO EVENT SHALL BROADCOM BE LIABLE
 *    FOR ANY DAMAGES WHATSOEVER, AND IN PARTICULAR, BROADCOM SHALL NOT BE
 *    LIABLE FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 *    BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 */

#include "cfe_api.h"

void *__libcfe_init (long handle, long a1, long cfe_entrypoint, long a3);
void __libcfe_exit (long status);

char inbyte (void);
int outbyte (char c);

/* Echo input characters?  */
int	__libcfe_echo_input = 0;

/* CFE handle used to access console device.  */
static int cfe_conshandle;


/* Initialize firmware callbacks.  Called from crt0_cfe.  Returns desired
   stack pointer.  */
void *
__libcfe_init (long handle, long a1, long entrypoint, long a3)
{
  cfe_init (handle, entrypoint);
  cfe_conshandle = cfe_getstdhandle (CFE_STDHANDLE_CONSOLE);

  __libcfe_meminit ();
  return __libcfe_stack_top ();
}

/* Exit back to monitor, with the given status code.  */
void
__libcfe_exit (long status)
{
  outbyte ('\r');
  outbyte ('\n');
  cfe_exit (CFE_FLG_WARMSTART, status);
}

char
inbyte (void)
{
  unsigned char c;
  int rv;

  while (cfe_read (cfe_conshandle, &c, 1) != 1)
    ;
  if (c == '\r')
    c = '\n';
  if (__libcfe_echo_input)
    outbyte (c);
  return c;
}

int
outbyte (char c)
{
  int res;

  do
    {
      res = cfe_write (cfe_conshandle, &c, 1);
    }
  while (res == 0);
  if (c == '\n')
    outbyte ('\r');
  return 0;
}

/* This is the MIPS cache flush function call.  No defines are provided
   by libgloss for 'cache', and CFE doesn't let you flush ranges, so
   we just flush all I & D for every call.  */
int
_flush_cache (char *addr, int nbytes, int cache)
{
  cfe_flushcache (0);
  return 0;
}
