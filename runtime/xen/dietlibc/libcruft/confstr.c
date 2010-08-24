#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <stdlib.h>
#include <string.h>

#define DEF_PATH "/bin:/usr/bin"

size_t confstr(int name,char*buf,size_t len) {
  switch (name) {
  case _CS_PATH:
    if (buf) strncpy(buf,DEF_PATH,len);
    return sizeof(DEF_PATH);
    break;
  }
  errno=EINVAL;
  return 0;
}
