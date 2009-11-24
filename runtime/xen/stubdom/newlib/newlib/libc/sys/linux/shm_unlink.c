/* shm_unlink - remove a shared memory file */

/* Copyright 2002, Red Hat Inc. */

#include <sys/types.h>
#include <sys/mman.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>

int
shm_unlink (const char *name)
{
  int rc;
  char shm_name[PATH_MAX+20] = "/dev/shm/";

  /* skip opening slash */
  if (*name == '/')
    ++name;

  /* create special shared memory file name and leave enough space to
     cause a path/name error if name is too long */
  strlcpy (shm_name + 9, name, PATH_MAX + 10);

  rc = unlink (shm_name);

  return rc;
}
