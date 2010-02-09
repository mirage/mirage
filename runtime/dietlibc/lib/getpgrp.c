#include <unistd.h>

pid_t getpgrp()
{
  return getpgid(0);
}
