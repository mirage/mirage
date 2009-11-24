#include <_ansi.h>
#include <ctype.h>

#undef _tolower
int
_DEFUN(_tolower,(c),int c)
{
	return isupper(c) ? (c) - 'A' + 'a' : c;
}
