#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "xs.h"


int main(int argc, char **argv)
{
  struct xs_handle * xsh;

  if (argc < 2 ||
      strcmp(argv[1], "check"))
  {
    fprintf(stderr,
            "Usage:\n"
            "\n"
            "       %s check\n"
            "\n", argv[0]);
    return 2;
  }

  xsh = xs_daemon_open();

  if (xsh == NULL) {
    fprintf(stderr, "Failed to contact Xenstored.\n");
    return 1;
  }

  xs_debug_command(xsh, argv[1], NULL, 0);

  xs_daemon_close(xsh);

  return 0;
}
