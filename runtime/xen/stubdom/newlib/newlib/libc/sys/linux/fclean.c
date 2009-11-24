#include <stdio.h>

int
fclean (FILE *fp)
{
  return fflush (fp);
}
