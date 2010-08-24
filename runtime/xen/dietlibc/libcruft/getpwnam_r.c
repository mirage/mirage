#include <string.h>
#include <pwd.h>

int getpwnam_r(const char* name,
	       struct passwd *res, char *buf, size_t buflen,
	       struct passwd **res_sig) {
  while (!getpwent_r(res,buf,buflen,res_sig))
    if (!strcmp(name,res->pw_name))
      goto ok;
  *res_sig=0;
ok:
  endpwent();
  return *res_sig?0:-1;
}
