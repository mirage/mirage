/* ctermid */

#include <stdio.h>
#include <string.h>

static char devname[] = "/dev/tty";

char *
_DEFUN (ctermid, (buf),
     char *buf)
{
  if (buf == NULL)
    return devname;

  return strcpy (buf, "/dev/tty");
}
