#include <string.h>
#include <shadow.h>

int getspnam_r(const char* name,
	       struct spwd *res, char *buf, size_t buflen,
	       struct spwd **res_sig) {
  while (!getspent_r(res,buf,buflen,res_sig))
    if (!strcmp(name,res->sp_namp))
      goto ok;
  *res_sig=0;
ok:
  endspent();
  return *res_sig?0:-1;
}
