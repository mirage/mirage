/* Copyright 2002, Red Hat Inc. - all rights reserved */
/*
FUNCTION
<<getline>>---read a line from a file

INDEX
        getline

ANSI_SYNOPSIS
        #include <stdio.h>
        ssize_t getline(char **<[bufptr]>, size_t *<[n]>, FILE *<[fp]>);

TRAD_SYNOPSIS
        #include <stdio.h>
        ssize_t getline(<[bufptr]>, <[n]>, <[fp]>)
        char **<[bufptr]>;
        size_t *<[n]>;
        FILE *<[fp]>;

DESCRIPTION
<<getline>> reads a file <[fp]> up to and possibly including the
newline character.  The line is read into a buffer pointed to
by <[bufptr]> and designated with size *<[n]>.  If the buffer is
not large enough, it will be dynamically grown by <<getdelim>>.
As the buffer is grown, the pointer to the size <[n]> will be
updated.

<<getline>> is equivalent to getdelim(bufptr, n, '\n', fp);

RETURNS
<<getline>> returns <<-1>> if no characters were successfully read,
otherwise, it returns the number of bytes successfully read.
at end of file, the result is nonzero.

PORTABILITY
<<getline>> is a glibc extension.

No supporting OS subroutines are directly required.
*/

#include <_ansi.h>
#include <stdio.h>

extern ssize_t _EXFUN(__getdelim, (char **, size_t *, int, FILE *));

ssize_t
_DEFUN(__getline, (lptr, n, fp),
       char **lptr _AND
       size_t *n   _AND
       FILE *fp)
{
  return __getdelim (lptr, n, '\n', fp);
}

