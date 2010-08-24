#include <string.h>
#include <grp.h>

int getgrgid_r(gid_t gid,
	       struct group *res, char *buf, size_t buflen,
	       struct group **res_sig) {
  while (!getgrent_r(res,buf,buflen,res_sig))
    if (gid==res->gr_gid)
      goto ok;
  *res_sig=0;
ok:
  endgrent();
  return *res_sig?0:-1;
}
