#include <ctype.h>

int isalnum(int ch) {
  return (unsigned int)((ch | 0x20) - 'a') < 26u  ||
	 (unsigned int)( ch         - '0') < 10u;
}
