/*
FUNCTION
	<<memset>>---set an area of memory, optimized for the MIPS processors

INDEX
	memset

ANSI_SYNOPSIS
	#include <string.h>
	void *memset(const void *<[dst]>, int <[c]>, size_t <[length]>);

TRAD_SYNOPSIS
	#include <string.h>
	void *memset(<[dst]>, <[c]>, <[length]>)
	void *<[dst]>;
	int <[c]>;
	size_t <[length]>;

DESCRIPTION
	This function converts the argument <[c]> into an unsigned
	char and fills the first <[length]> characters of the array
	pointed to by <[dst]> to the value.

RETURNS
	<<memset>> returns the value of <[m]>.

PORTABILITY
<<memset>> is ANSI C.

    <<memset>> requires no supporting OS subroutines.

QUICKREF
	memset ansi pure
*/

#include <string.h>

#ifdef __mips64
#define wordtype long long
#else
#define wordtype long
#endif

#define LBLOCKSIZE     (sizeof(wordtype))
#define UNALIGNED(X)   ((long)(X) & (LBLOCKSIZE - 1))
#define TOO_SMALL(LEN) ((LEN) < LBLOCKSIZE * 4)

_PTR 
_DEFUN (memset, (m, c, n),
	_PTR m _AND
	int c _AND
	size_t n)
{
#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__) || defined(__mips16)
  char *s = (char *) m;

  while (n-- != 0)
    {
      *s++ = (char) c;
    }

  return m;
#else
  char *s = (char *) m;
  int i;
  unsigned wordtype buffer;
  unsigned wordtype *aligned_addr;
  unsigned short *short_addr;
  size_t iter;

  if (!TOO_SMALL (n))
    {
      int unaligned = UNALIGNED (s);

      /* We know that N is >= LBLOCKSIZE so we can just word
         align the S without having to check the length. */

      if (unaligned)
	{
	  while (unaligned++ < LBLOCKSIZE)
	    *s++ = (char)c, n--;
	}

      /* S is now word-aligned so we can process the remainder
         in word sized chunks except for a few (< LBLOCKSIZE)
         bytes which might be left over at the end. */

      aligned_addr = (unsigned wordtype *)s;

      /* Store C into each char sized location in BUFFER so that
         we can set large blocks quickly.  */
      c &= 0xff;
      buffer = c;
      if (buffer != 0)
	{
	  if (LBLOCKSIZE == 4)
	    {
	       buffer |= (buffer << 8);
	       buffer |= (buffer << 16);
	    }
	  else if (LBLOCKSIZE == 8)
	    {
	      buffer |= (buffer << 8);
	      buffer |= (buffer << 16);
	      buffer |= ((buffer << 31) << 1);
	    }
	  else
	    {
	      for (i = 1; i < LBLOCKSIZE; i++)
		buffer = (buffer << 8) | c;
	    }
        }

      iter = n / (2*LBLOCKSIZE);
      n = n % (2*LBLOCKSIZE);
      while (iter > 0)
	{
	  aligned_addr[0] = buffer;
	  aligned_addr[1] = buffer;
	  aligned_addr += 2;
	  iter--;
	}

      if (n >= LBLOCKSIZE)
	{
	  *aligned_addr++ = buffer;
	  n -= LBLOCKSIZE;
	}

      /* Pick up the remainder with a bytewise loop.  */
      s = (char*)aligned_addr;
    }

  while (n > 0)
    {
      *s++ = (char)c;
      n--;
    }

  return m;
#endif /* not PREFER_SIZE_OVER_SPEED */
}
