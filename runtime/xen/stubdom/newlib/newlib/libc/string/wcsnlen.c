/* 
FUNCTION
        <<wcsnlen>>---get fixed-size wide-character string length
    
INDEX
        wcsnlen

ANSI_SYNOPSIS
        #include <wchar.h>
        size_t wcsnlen(const wchar_t *<[s]>, size_t <[maxlen]>);

TRAD_SYNOPSIS
        #include <wchar.h>
        size_t wcsnlen(<[s]>, <[maxlen]>)
        wchar_t *<[s]>;
        size_t <[maxlen]>;

DESCRIPTION
        The <<wcsnlen>> function computes the number of wide-character codes
        in the wide-character string pointed to by <[s]> not including the
        terminating L'\0' wide character but at most <[maxlen]> wide
        characters.

RETURNS
        <<wcsnlen>> returns the length of <[s]> if it is less then <[maxlen]>,
        or <[maxlen]> if there is no L'\0' wide character in first <[maxlen]>
        characters.

PORTABILITY
<<wcsnlen>> is a GNU extension.

<<wcsnlen>> requires no supporting OS subroutines.
*/

/*
 * Copyright (c) 2003, Artem B. Bityuckiy (dedekind@mail.ru).
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the above copyright notice,
 * this condition statement, and the following disclaimer are retained
 * in any redistributions of the source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <_ansi.h>
#include <sys/types.h>
#include <wchar.h>

size_t
_DEFUN(wcsnlen, (s, maxlen), 
                 _CONST wchar_t *s _AND 
                 size_t maxlen)
{
  _CONST wchar_t *p;

  p = s;
  while (*p && maxlen-- > 0)
    p++;

  return (size_t)(p - s);
}



