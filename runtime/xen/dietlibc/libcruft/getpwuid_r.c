#include <pwd.h>

int getpwuid_r(uid_t uid,
	       struct passwd *res, char *buf, size_t buflen,
	       struct passwd **res_sig) {
  while (!getpwent_r(res,buf,buflen,res_sig))
    if (uid==res->pw_uid)
      goto ok;
  *res_sig=0;
ok:
  endpwent();
  return *res_sig?0:-1;
}
