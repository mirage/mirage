/*
FUNCTION
<<ecvtbuf>>, <<fcvtbuf>>---double or float to string

INDEX
	ecvtbuf
INDEX
	fcvtbuf

ANSI_SYNOPSIS
	#include <stdio.h>

	char *ecvtbuf(double <[val]>, int <[chars]>, int *<[decpt]>,
                       int *<[sgn]>, char *<[buf]>);

	char *fcvtbuf(double <[val]>, int <[decimals]>, int *<[decpt]>,
                       int *<[sgn]>, char *<[buf]>);

TRAD_SYNOPSIS
	#include <stdio.h>

	char *ecvtbuf(<[val]>, <[chars]>, <[decpt]>, <[sgn]>, <[buf]>);
	double <[val]>;
	int <[chars]>;
	int *<[decpt]>;
	int *<[sgn]>;
	char *<[buf]>;

	char *fcvtbuf(<[val]>, <[decimals]>, <[decpt]>, <[sgn]>, <[buf]>);
	double <[val]>;
	int <[decimals]>;
	int *<[decpt]>;
	int *<[sgn]>;
	char *<[buf]>;

DESCRIPTION
	<<ecvtbuf>> and <<fcvtbuf>> produce (null-terminated) strings
	of digits representating the <<double>> number <[val]>.

	The only difference between <<ecvtbuf>> and <<fcvtbuf>> is the
	interpretation of the second argument (<[chars]> or
	<[decimals]>). For <<ecvtbuf>>, the second argument <[chars]>
	specifies the total number of characters to write (which is
	also the number of significant digits in the formatted string,
	since these two functions write only digits). For <<fcvtbuf>>,
	the second argument <[decimals]> specifies the number of
	characters to write after the decimal point; all digits for
	the integer part of <[val]> are always included.

	Since <<ecvtbuf>> and <<fcvtbuf>> write only digits in the
	output string, they record the location of the decimal point
	in <<*<[decpt]>>>, and the sign of the number in <<*<[sgn]>>>.
	After formatting a number, <<*<[decpt]>>> contains the number
	of digits to the left of the decimal point.  <<*<[sgn]>>>
	contains <<0>> if the number is positive, and <<1>> if it is
	negative.  For both functions, you supply a pointer <[buf]> to
	an area of memory to hold the converted string.

RETURNS
	Both functions return a pointer to <[buf]>, the string
	containing a character representation of <[val]>.

PORTABILITY
	Neither function is ANSI C.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdlib.h>
#include <string.h>
#include <reent.h>
#include "mprec.h"
#include "local.h"

static void
_DEFUN (print_f, (ptr, buf, invalue, ndigit, type, dot, mode),
	struct _reent *ptr _AND
	char *buf _AND
	double invalue _AND
	int ndigit _AND
	char type _AND
	int dot _AND
	int mode)
{
  int decpt;
  int sign;
  char *p, *start, *end;

  start = p = _dtoa_r (ptr, invalue, mode, ndigit, &decpt, &sign, &end);

  if (decpt == 9999)
    {
      strcpy (buf, p);
      return;
    }
  while (*p && decpt > 0)
    {
      *buf++ = *p++;
      decpt--;
    }
  /* Even if not in buffer */
  while (decpt > 0)
    {
      *buf++ = '0';
      decpt--;
    }

  if (dot || *p)
    {
      if (p == start)
	*buf++ = '0';
      *buf++ = '.';
      while (decpt < 0 && ndigit > 0)
	{
	  *buf++ = '0';
	  decpt++;
	  ndigit--;
	}

      /* Print rest of stuff */
      while (*p && ndigit > 0)
	{
	  *buf++ = *p++;
	  ndigit--;
	}
      /* And trailing zeros */
      while (ndigit > 0)
	{
	  *buf++ = '0';
	  ndigit--;
	}
    }
  *buf++ = 0;
}

/* Print number in e format with width chars after.

   TYPE is one of 'e' or 'E'.  It may also be one of 'g' or 'G' indicating
   that _gcvt is calling us and we should remove trailing zeroes.

   WIDTH is the number of digits of precision after the decimal point.  */

static void
_DEFUN (print_e, (ptr, buf, invalue, width, type, dot),
	struct _reent *ptr _AND
	char *buf _AND
	double invalue _AND
	int width _AND
	char type _AND
	int dot)
{
  int sign;
  char *end;
  char *p;
  int decpt;
  int top;
  int ndigit = width;

  p = _dtoa_r (ptr, invalue, 2, width + 1, &decpt, &sign, &end);

  if (decpt == 9999)
    {
      strcpy (buf, p);
      return;
    }

  *buf++ = *p++;
  if (dot || ndigit != 0)
    *buf++ = '.';

  while (*p && ndigit > 0)
    {
      *buf++ = *p++;
      ndigit--;
    }

  /* Add trailing zeroes to fill out to ndigits unless this is 'g' format.
     Also, convert g/G to e/E.  */

  if (type == 'g')
    type = 'e';
  else if (type == 'G')
    type = 'E';
  else
    {
      while (ndigit > 0)
	{
	  *buf++ = '0';
	  ndigit--;
	}
    }

  /* Add the exponent.  */

  *buf++ = type;
  decpt--;
  if (decpt < 0)
    {
      *buf++ = '-';
      decpt = -decpt;
    }
  else
    {
      *buf++ = '+';
    }
  if (decpt > 99)
    {
      int top = decpt / 100;
      *buf++ = top + '0';
      decpt -= top * 100;
    }
  top = decpt / 10;
  *buf++ = top + '0';
  decpt -= top * 10;
  *buf++ = decpt + '0';

  *buf++ = 0;
}

#ifndef _REENT_ONLY

/* Undocumented behaviour: when given NULL as a buffer, return a
   pointer to static space in the rent structure.  This is only to
   support ecvt and fcvt, which aren't ANSI anyway.  */

char *
_DEFUN (fcvtbuf, (invalue, ndigit, decpt, sign, fcvt_buf),
	double invalue _AND
	int ndigit _AND
	int *decpt _AND
	int *sign _AND
	char *fcvt_buf)
{
  char *save;
  char *p;
  char *end;
  int done = 0;

  if (fcvt_buf == NULL)
    {
      if (_REENT->_cvtlen <= ndigit + 35)
	{
	  if ((fcvt_buf = (char *) _realloc_r (_REENT, _REENT->_cvtbuf,
					       ndigit + 36)) == NULL)
	    return NULL;
	  _REENT->_cvtlen = ndigit + 36;
	  _REENT->_cvtbuf = fcvt_buf;
	}

      fcvt_buf = _REENT->_cvtbuf ;
    }

  save = fcvt_buf;

  if (invalue < 1.0 && invalue > -1.0)
    {
      p = _dtoa_r (_REENT, invalue, 2, ndigit, decpt, sign, &end);
    }
  else
    {
      p = _dtoa_r (_REENT, invalue, 3, ndigit, decpt, sign, &end);
    }

  /* Now copy */

  done = -*decpt;
  while (p < end)
    {
      *fcvt_buf++ = *p++;
      done++;
    }
  /* And unsuppress the trailing zeroes */
  while (done < ndigit)
    {
      *fcvt_buf++ = '0';
      done++;
    }
  *fcvt_buf++ = 0;
  return save;
}

char *
_DEFUN (ecvtbuf, (invalue, ndigit, decpt, sign, fcvt_buf),
	double invalue _AND
	int ndigit _AND
	int *decpt _AND
	int *sign _AND
	char *fcvt_buf)
{
  char *save;
  char *p;
  char *end;
  int done = 0;

  if (fcvt_buf == NULL)
    {
      if (_REENT->_cvtlen <= ndigit)
	{
	  if ((fcvt_buf = (char *) _realloc_r (_REENT, _REENT->_cvtbuf,
					       ndigit + 1)) == NULL)
	    return NULL;
	  _REENT->_cvtlen = ndigit + 1;
	  _REENT->_cvtbuf = fcvt_buf;
	}

      fcvt_buf = _REENT->_cvtbuf ;
    }

  save = fcvt_buf;

  p = _dtoa_r (_REENT, invalue, 2, ndigit, decpt, sign, &end);

  /* Now copy */

  while (p < end)
    {
      *fcvt_buf++ = *p++;
      done++;
    }
  /* And unsuppress the trailing zeroes */
  while (done < ndigit)
    {
      *fcvt_buf++ = '0';
      done++;
    }
  *fcvt_buf++ = 0;
  return save;
}

#endif

char *
_DEFUN (_gcvt, (ptr, invalue, ndigit, buf, type, dot),
	struct _reent *ptr _AND
	double invalue _AND
	int ndigit _AND
	char *buf _AND
	char type _AND
	int dot)
{
  char *save = buf;

  if (invalue < 0)
    {
      invalue = -invalue;
    }

  if (invalue == 0)
    {
      *buf++ = '0';
      *buf = '\0';
    }
  else
    /* Which one to print ?
       ANSI says that anything with more that 4 zeros after the . or more
       than precision digits before is printed in e with the qualification
       that trailing zeroes are removed from the fraction portion.  */

  if (0.0001 >= invalue || invalue >= _mprec_log10 (ndigit))
    {
      /* We subtract 1 from ndigit because in the 'e' format the precision is
	 the number of digits after the . but in 'g' format it is the number
	 of significant digits.

	 We defer changing type to e/E so that print_e() can know it's us
	 calling and thus should remove trailing zeroes.  */

      print_e (ptr, buf, invalue, ndigit - 1, type, dot);
    }
  else
    {
      int decpt;
      int sign;
      char *end;
      char *p;

      if (invalue < 1.0)
	{
	  /* what we want is ndigits after the point */
	  p = _dtoa_r (ptr, invalue, 3, ndigit, &decpt, &sign, &end);
	}
      else
	{
	  p = _dtoa_r (ptr, invalue, 2, ndigit, &decpt, &sign, &end);
	}

      if (decpt == 9999)
	{
	  strcpy (buf, p);
	  return save;
	}
      while (*p && decpt > 0)
	{
	  *buf++ = *p++;
	  decpt--;
	  ndigit--;
	}
      /* Even if not in buffer */
      while (decpt > 0 && ndigit > 0)
	{
	  *buf++ = '0';
	  decpt--;
	  ndigit--;
	}

      if (dot || *p)
	{
	  if (buf == save)
	    *buf++ = '0';
	  *buf++ = '.';
	  while (decpt < 0 && ndigit > 0)
	    {
	      *buf++ = '0';
	      decpt++;
	      ndigit--;
	    }

	  /* Print rest of stuff */
	  while (*p && ndigit > 0)
	    {
	      *buf++ = *p++;
	      ndigit--;
	    }
	  /* And trailing zeros */
	  if (dot)
	    {
	      while (ndigit > 0)
		{
		  *buf++ = '0';
		  ndigit--;
		}
	    }
	}
      *buf++ = 0;
    }

  return save;
}

char *
_DEFUN (_dcvt, (ptr, buffer, invalue, precision, width, type, dot),
	struct _reent *ptr _AND
	char *buffer _AND
	double invalue _AND
	int precision _AND
	int width _AND
	char type _AND
	int dot)
{
  switch (type)
    {
    case 'f':
    case 'F':
      print_f (ptr, buffer, invalue, precision, type, precision == 0 ? dot : 1, 3);
      break;
    case 'g':
    case 'G':
      if (precision == 0)
	precision = 1;
      _gcvt (ptr, invalue, precision, buffer, type, dot);
      break;
    case 'e':
    case 'E':
      print_e (ptr, buffer, invalue, precision, type, dot);
    }
  return buffer;
}
