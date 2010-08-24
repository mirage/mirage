#include <string.h>
#include <netdb.h>

extern int getservbyname_r(const char* name,const char* proto,
			   struct servent *res, char *buf, size_t buflen,
			   struct servent **res_sig) {
  while (!getservent_r(res,buf,buflen,res_sig)) {
    int i;
    if (proto && strcmp(res->s_proto,proto)) continue;
    if (!strcmp(res->s_name,name)) goto found;
    for (i=0; res->s_aliases[i]; ++i)
      if (!strcmp(res->s_aliases[i],name)) goto found;
  }
  *res_sig=0;
found:
  endservent();
  return *res_sig?0:-1;
}
