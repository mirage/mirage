/* shm_open - open a shared memory file */

/* Copyright 2002, Red Hat Inc. */

#include <sys/types.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <limits.h>

int
shm_open (const char *name, int oflag, mode_t mode)
{
  int fd;
  char shm_name[PATH_MAX+20] = "/dev/shm/";

  /* skip opening slash */
  if (*name == '/')
    ++name;

  /* create special shared memory file name and leave enough space to
     cause a path/name error if name is too long */
  strlcpy (shm_name + 9, name, PATH_MAX + 10);

  fd = open (shm_name, oflag, mode);

  if (fd != -1)
    {
      /* once open we must add FD_CLOEXEC flag to file descriptor */
      int flags = fcntl (fd, F_GETFD, 0);

      if (flags >= 0)
        {
          flags |= FD_CLOEXEC;
          flags = fcntl (fd, F_SETFD, flags);
        }

      /* on failure, just close file and give up */
      if (flags == -1)
        {
          close (fd);
          fd = -1;
        }
    }

  return fd;
}
