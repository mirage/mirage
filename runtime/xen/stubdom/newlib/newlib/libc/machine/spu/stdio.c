/*
Copyright (C) 2007 Sony Computer Entertainment Inc.
Copyright 2007 Sony Corp.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
  * Neither the names of the copyright holders nor the names of their
    contributors may be used to endorse or promote products derived from this
    software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Author: Kazunori Asayama <asayama@sm.sony.co.jp>
*/

#include <stdio.h>

#include "c99ppe.h"


static FILE __fp[SPE_FOPEN_MAX];

FILE *
_DEFUN (__sfp, (d),
	struct _reent *d)
{
  int i;
  for (i = 0; i < SPE_FOPEN_MAX; i++) {
    if (!__fp[i]._fp) {
      return &__fp[i];
    }
  }
  d->_errno = EMFILE;
  return NULL;
}

static _VOID
_DEFUN (__cleanup, (s),
	struct _reent *s)
{
  int i;
  for (i = 0; i < SPE_FOPEN_MAX; i++) {
    if (__fp[i]._fp) {
      fclose(&__fp[i]);
    }
  }
}

_VOID
_DEFUN (__sinit, (s),
	struct _reent *s)
{
  s->__cleanup = __cleanup;
  s->__sdidinit = 1;

  s->_stdin = &s->__sf[0];
  s->_stdin->_fp = SPE_STDIN;

  s->_stdout = &s->__sf[1];
  s->_stdout->_fp = SPE_STDOUT;

  s->_stderr = &s->__sf[2];
  s->_stderr->_fp = SPE_STDERR;
}

_VOID
_DEFUN_VOID (__check_init)
{
    CHECK_INIT(_REENT);
}
