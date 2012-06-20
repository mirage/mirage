#include <sys/shm.h>

struct __dirstream {
  int fd;
  char buf[PAGE_SIZE-(sizeof (int)*3)];
  unsigned int num;
  unsigned int cur;
};				/* stream data from opendir() */
