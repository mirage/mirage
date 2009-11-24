/* $NetBSD: hcreate.c,v 1.2 2001/02/19 21:26:04 ross Exp $ */

/*
 * Copyright (c) 2001 Christopher G. Demetriou
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * <<Id: LICENSE_GC,v 1.1 2001/10/01 23:24:05 cgd Exp>>
 */

/*
 * hcreate() / hsearch() / hdestroy()
 *
 * SysV/XPG4 hash table functions.
 *
 * Implementation done based on NetBSD manual page and Solaris manual page,
 * plus my own personal experience about how they're supposed to work.
 *
 * I tried to look at Knuth (as cited by the Solaris manual page), but
 * nobody had a copy in the office, so...
 */

#include <sys/cdefs.h>
#if 0
#if defined(LIBC_SCCS) && !defined(lint)
__RCSID("$NetBSD: hcreate.c,v 1.2 2001/02/19 21:26:04 ross Exp $");
#endif /* LIBC_SCCS and not lint */
#endif

#include <sys/types.h>
#include <sys/queue.h>
#include <errno.h>
#include <search.h>
#include <stdlib.h>
#include <string.h>

static struct hsearch_data htab;

int
_DEFUN(hcreate, (nel), size_t nel)
{
  return hcreate_r (nel, &htab);
}

void
_DEFUN_VOID (hdestroy)
{
  hdestroy_r (&htab);
}

ENTRY *
_DEFUN(hsearch, (item, action), 
       ENTRY item _AND
       ACTION action)
{
  ENTRY *retval;

  hsearch_r (item, action, &retval, &htab);

  return retval;
}
