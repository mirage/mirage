#include <wctype.h>
#include <string.h>

struct { const char* name; wctype_t func; } types[]={
  { "alnum", iswalnum },
  { "alpha", iswalpha },
  { "blank", iswblank },
  { "cntrl", iswcntrl },
  { "digit", iswdigit },
  { "graph", iswgraph },
  { "lower", iswlower },
  { "print", iswprint },
  { "punct", iswpunct },
  { "space", iswspace },
  { "upper", iswupper },
  { "xdigit", iswxdigit },
};

wctype_t wctype(const char* name) {
  size_t i;
  for (i=0; i<sizeof(types)/sizeof(types[0]); ++i)
    if (!strcmp(name,types[i].name)) return types[i].func;
  return (wctype_t)0;
}
