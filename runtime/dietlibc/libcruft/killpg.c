#include <signal.h>

int killpg(pid_t pgrp, int signal) {
  return kill(-pgrp,signal);
}
