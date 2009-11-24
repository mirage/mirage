#ifndef _REENT_ONLY

#include <reent.h>
#include <stdlib.h>
#include <string.h>

char *
_DEFUN (strdup, (str), _CONST char *str)
{
  return _strdup_r (_REENT, str);
}

#endif /* !_REENT_ONLY */
