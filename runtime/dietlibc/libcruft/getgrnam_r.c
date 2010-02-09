#include <string.h>
#include <grp.h>

int getgrnam_r(const char* name,
	       struct group *res, char *buf, size_t buflen,
	       struct group **res_sig) {
  while (!getgrent_r(res,buf,buflen,res_sig))
    if (!strcmp(name,res->gr_name))
      goto ok;
  *res_sig=0;
ok:
  endgrent();
  return *res_sig?0:-1;
}
