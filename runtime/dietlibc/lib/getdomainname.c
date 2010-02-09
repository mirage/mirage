#define _GNU_SOURCE

#include <sys/types.h>
#include <sys/utsname.h>
#include <unistd.h>

int getdomainname(char *name,size_t len) {
  struct utsname u;
  int res=uname(&u);
  if (res==0) {
    size_t i;
    if (len>=_UTSNAME_DOMAIN_LENGTH)
      len=_UTSNAME_DOMAIN_LENGTH;
    for (i=0; i<len; i++)
      name[i]=u.domainname[i];
  }
  return res;
}
