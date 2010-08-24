#include <ctype.h>

inline int toupper(int ch) {
  if ( (unsigned int)(ch - 'a') < 26u )
    ch += 'A' - 'a';
  return ch;
}

