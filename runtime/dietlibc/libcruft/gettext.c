#include <libintl.h>

#undef gettext
char* gettext(const char* msg) { return (char*)msg; }
