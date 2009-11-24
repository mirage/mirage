#include <sys/types.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include "check.h"

int main()
{
  int fd;
  char *x;
  FILE *fp;
  char buf[40];

  fd = open("my.file", O_CREAT | O_TRUNC | O_RDWR, 0644);

  CHECK (fd != -1);

  CHECK (write (fd, "abcdefgh", 8) == 8); 
 
  x = (char *)mmap (0, 20, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

  CHECK (x != MAP_FAILED);

  x[3] = 'j';

  CHECK (munmap (x, 20) == 0);

  CHECK (close(fd) != -1);

  fp = fopen("my.file","r");

  CHECK (fp != NULL);

  CHECK (fread(buf, 1, 20, fp) == 8);

  CHECK (strncmp (buf, "abcjefgh", 8) == 0);

  exit (0);
}

