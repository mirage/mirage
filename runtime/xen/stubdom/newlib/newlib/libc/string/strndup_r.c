#include <reent.h>
#include <stdlib.h>
#include <string.h>

char *
_DEFUN (_strndup_r, (reent_ptr, str, n), 
        struct _reent *reent_ptr  _AND
        _CONST char   *str _AND
        size_t n)
{
  _CONST char *ptr = str;
  size_t len;
  char *copy;

  while (n-- > 0 && *ptr)
    ptr++;

  len = ptr - str;

  copy = _malloc_r (reent_ptr, len + 1);
  if (copy)
    {
      memcpy (copy, str, len);
      copy[len] = '\0';
    }
  return copy;
}
