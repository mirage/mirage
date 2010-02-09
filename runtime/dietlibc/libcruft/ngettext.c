#include <libintl.h>

#undef ngettext
char* ngettext (const char* msgid, const char* msgid_plural, unsigned long int n) {
  return (char*)(n==1?msgid:msgid_plural);
}
