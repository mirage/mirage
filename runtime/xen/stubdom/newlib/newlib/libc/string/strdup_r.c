#include <reent.h>
#include <stdlib.h>
#include <string.h>

char *
_DEFUN (_strdup_r, (reent_ptr, str), 
        struct _reent *reent_ptr  _AND
        _CONST char   *str)
{
  size_t len = strlen (str) + 1;
  char *copy = _malloc_r (reent_ptr, len);
  if (copy)
    {
      memcpy (copy, str, len);
    }
  return copy;
}
