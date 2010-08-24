#include <ctype.h>
#include "dietwarning.h"

int toascii(int c) {
  return (c&0x7f);
}

link_warning("toascii","using this function converts accented characters to random unrelated characters and will make people very unhappy!")
