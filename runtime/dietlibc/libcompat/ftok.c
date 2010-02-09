#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ipc.h>
#include <dietwarning.h>

key_t ftok(const char* path, int id) {
  struct stat s;
  if (stat(path,&s)) return -1;
  return (key_t) (id << 24 | (s.st_dev & 0xff) << 16 | (s.st_ino & 0xffff));
}

link_warning("ftok","ftok is obsolete _and_ repugnant junk, don't use!");
