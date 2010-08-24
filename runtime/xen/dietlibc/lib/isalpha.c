#include <ctype.h>

int isalpha(int ch) {
  return (unsigned int)((ch | 0x20) - 'a') < 26u;
}
