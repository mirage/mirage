#include <unistd.h>

int setpgrp()
{
  return setpgid(0,0);
}
