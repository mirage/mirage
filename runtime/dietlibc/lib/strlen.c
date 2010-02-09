#include <endian.h>
#include "dietfeatures.h"
#include <string.h>
#include <stdint.h>

#ifdef WANT_SMALL_STRING_ROUTINES
size_t strlen(const char *s) {
  register size_t i;
  if (__unlikely(!s)) return 0;
  for (i=0; __likely(*s); ++s) ++i;
  return i;
}
#else

#if __WORDSIZE == 64
typedef uint64_t	word_t;
#elif __WORDSIZE == 32
typedef uint32_t	word_t;
#else
#error unsupported __WORDSIZE
#endif

static word_t const	magic = (word_t)(0x0101010101010101ull);

size_t strlen(const char *s)
{
  const char *t = s;
  word_t	word;
  word_t	mask;

  if (__unlikely(!s)) return 0;

  /* Byte compare up until word boundary */
  for (; ((unsigned long) t & (sizeof(magic)-1)); t++)
    if (!*t) return t - s;

  /* Word compare */
  do {
    word = *((word_t const *) t); t += sizeof word;
    word = (word - magic) &~ word;
    word &= (magic << 7);
  } while (__likely(word == 0));

#if __BYTE_ORDER == __LITTLE_ENDIAN
  (void)mask;
  switch (sizeof(word)) {
  case 8:
    /* word & 0x8080808080808080 == word */
    word = (word - 1) & (magic << 8);
    word += (word << 32);
    word += (word << 16);
    word += (word << 8);
    t += word >> 56;
    break;

  case 4:
    /* word & 0x80808080 == word */
    word = (word - 1) & (magic << 10);
    word += (word << 8) + (word << 16);
    t += word >> 26;
    break;

  default: { char exc[sizeof(word)==8]; (void)exc; }
  }
#else
  mask = (magic << 7);

  switch (sizeof(word)) {
  case 8:
    mask <<= 4*8;
    if ((word & mask) == 0) {
      t     += 4;
      word <<= 4*8;
    }
    /* fallthrough */

  case 4:
    mask <<= 2*8;
    if ((word & mask) == 0) {
      t     += 2;
      word <<= 2*8;
    }
    /* fallthrough */

  case 2:
    mask <<= 1*8;
    if ((word & mask) == 0) {
      t     += 1;
      word <<= 1*8;
    }
    break;

  default: { char exc[sizeof(word)==8]; (void)exc; }
  }
#endif
  return t - sizeof(word) - s;
}
#endif
