#include <locale.h>
#include <stdlib.h>
#include <string.h>
#include "dietlocale.h"

char *setlocale (int category, const char *locale) {
  lc_ctype=CT_8BIT;
  if (locale && (category==LC_ALL || category==LC_CTYPE)) {
    if (!*locale) {
      const char* x;
      x=getenv("LC_CTYPE");
      if (!x) x=getenv("LC_ALL");
      if (!x) x="C";
      locale=x;
    }
  }
  if (locale) {
    if (strstr(locale,".UTF-8") || strstr(locale,".UTF8")) lc_ctype=CT_UTF8;
    if (locale[0]!='C' || locale[1]) return 0;
  }
  return "C";
}
