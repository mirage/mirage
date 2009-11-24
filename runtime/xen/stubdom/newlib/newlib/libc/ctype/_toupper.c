#include <_ansi.h>
#include <ctype.h>

#undef _toupper
int
_DEFUN(_toupper,(c),int c)
{
  return islower(c) ? c - 'a' + 'A' : c;
}
