/*
FUNCTION
        <<memcpy>>---copy memory regions, optimized for the mips processors

ANSI_SYNOPSIS
        #include <string.h>
        void* memcpy(void *<[out]>, const void *<[in]>, size_t <[n]>);

TRAD_SYNOPSIS
        void *memcpy(<[out]>, <[in]>, <[n]>
        void *<[out]>;
        void *<[in]>;
        size_t <[n]>;

DESCRIPTION
        This function copies <[n]> bytes from the memory region
        pointed to by <[in]> to the memory region pointed to by
        <[out]>.

        If the regions overlap, the behavior is undefined.

RETURNS
        <<memcpy>> returns a pointer to the first byte of the <[out]>
        region.

PORTABILITY
<<memcpy>> is ANSI C.

<<memcpy>> requires no supporting OS subroutines.

QUICKREF
        memcpy ansi pure
	*/

#include <_ansi.h>
#include <stddef.h>
#include <limits.h>

#ifdef __mips64
#define wordtype long long
#else
#define wordtype long
#endif

/* Nonzero if either X or Y is not aligned on a "long" boundary.  */
#define UNALIGNED(X, Y) \
  (((long)X & (sizeof (wordtype) - 1)) | ((long)Y & (sizeof (wordtype) - 1)))

/* How many bytes are copied each iteration of the 4X unrolled loop.  */
#define BIGBLOCKSIZE    (sizeof (wordtype) << 2)

/* How many bytes are copied each iteration of the word copy loop.  */
#define LITTLEBLOCKSIZE (sizeof (wordtype))

/* Threshhold for punting to the byte copier.  */
#define TOO_SMALL(LEN)  ((LEN) < BIGBLOCKSIZE)

_PTR
_DEFUN (memcpy, (dst0, src0, len0),
	_PTR dst0 _AND
	_CONST _PTR src0 _AND
	size_t len0)
{
#if defined(PREFER_SIZE_OVER_SPEED) || defined(__OPTIMIZE_SIZE__) || defined(__mips16)
  char *dst = (char *) dst0;
  char *src = (char *) src0;

  _PTR save = dst0;

  while (len0--)
    {
      *dst++ = *src++;
    }

  return save;
#else
  char *dst = dst0;
  _CONST char *src = src0;
  wordtype *aligned_dst;
  _CONST wordtype *aligned_src;
  int   len =  len0;
  size_t iter;

  /* Handle aligned moves here.  */
  if (!UNALIGNED (src, dst))
    {
      iter = len / BIGBLOCKSIZE;
      len = len % BIGBLOCKSIZE;
      aligned_dst = (wordtype *)dst;
      aligned_src = (wordtype *)src;

	  /* Copy 4X long or long long words at a time if possible.  */
      while (iter > 0)
	{
	  wordtype tmp0 = aligned_src[0];
	  wordtype tmp1 = aligned_src[1];
	  wordtype tmp2 = aligned_src[2];
	  wordtype tmp3 = aligned_src[3];

	  aligned_dst[0] = tmp0;
	  aligned_dst[1] = tmp1;
	  aligned_dst[2] = tmp2;
	  aligned_dst[3] = tmp3;
	  aligned_src += 4;
	  aligned_dst += 4;
	  iter--;
	}

      /* Copy one long or long long word at a time if possible.  */
      iter = len / LITTLEBLOCKSIZE;
      len = len % LITTLEBLOCKSIZE;

      while (iter > 0)
	{
	  *aligned_dst++ = *aligned_src++;
	  iter--;
	}

      /* Pick up any residual with a byte copier.  */
      dst = (char*)aligned_dst;
      src = (char*)aligned_src;

      while (len > 0)
	{
	  *dst++ = *src++;
	  len--;
	}

      return dst0;
    }

  /* Handle unaligned moves here, using lwr/lwl and swr/swl where possible */
  else
    {
#ifndef NO_UNALIGNED_LOADSTORE
      int tmp;
      int *int_src = (int *)src;
      int *int_dst = (int *)dst;
      iter = len / 4;
      len = len % 4;
      while (iter > 0)
	{
	  __asm__ ("ulw %0,%1" : "=r" (tmp) : "m" (*int_src));
	  iter--;
	  int_src++;
	  __asm__ ("usw %1,%0" : "=m" (*int_dst) : "r" (tmp));
	  int_dst++;
	}

      /* Pick up any residual with a byte copier.  */
      dst = (char*)int_dst;
      src = (char*)int_src;
#endif

      while (len > 0)
	{
	  *dst++ = *src++;
	  len--;
	}

      return dst0;
    }
#endif /* not PREFER_SIZE_OVER_SPEED */
}
