#include <libintl.h>

#undef dngettext
char* dngettext (const char* domainname,const char* msgid, const char* msgid_plural, unsigned long int n) {
  (void)domainname;
  return (char*)(n==1?msgid:msgid_plural);
}
