/* l64a - convert long to radix-64 ascii string
 *          
 * Conversion is performed on at most 32-bits of input value starting 
 * from least significant bits to the most significant bits.
 *
 * The routine splits the input value into groups of 6 bits for up to 
 * 32 bits of input.  This means that the last group may be 2 bits 
 * (bits 30 and 31).
 * 
 * Each group of 6 bits forms a value from 0-63 which is converted into 
 * a character as follows:
 *         0 = '.'
 *         1 = '/'
 *         2-11 = '0' to '9'
 *        12-37 = 'A' to 'Z'
 *        38-63 = 'a' to 'z'
 *
 * When the remaining bits are zero or all 32 bits have been translated, 
 * a nul terminator is appended to the resulting string.  An input value of 
 * 0 results in an empty string.
 */

#include <_ansi.h>
#include <stdlib.h>
#include <reent.h>

static const char R64_ARRAY[] = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

char *
_DEFUN (l64a, (value),
     long value)
{
  return _l64a_r (_REENT, value);
}

char *
_DEFUN (_l64a_r, (rptr, value),
     struct _reent *rptr _AND
     long value)
{
  char *ptr;
  char *result;
  int i, index;
  unsigned long tmp = (unsigned long)value & 0xffffffff;

  _REENT_CHECK_MISC(rptr);
  result = _REENT_L64A_BUF(rptr);
  ptr = result;

  for (i = 0; i < 6; ++i)
    {
      if (tmp == 0)
	{
	  *ptr = '\0';
	  break;
	}

      index = tmp & (64 - 1);
      *ptr++ = R64_ARRAY[index];
      tmp >>= 6;
    }

  return result;
}
