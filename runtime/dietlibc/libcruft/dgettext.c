#include <libintl.h>

#undef dgettext
char* dgettext(const char* domainname, const char* x) { return (char*)x; }
