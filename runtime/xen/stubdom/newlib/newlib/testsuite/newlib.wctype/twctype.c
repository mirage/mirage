#include <wctype.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <newlib.h>
#include <locale.h>
#include "check.h"

int main()
{
#if !defined(_ELIX_LEVEL) || _ELIX_LEVEL > 1
  if (_MB_LEN_MAX == 1)
    {
      CHECK (iswalpha(L'a'));
      CHECK (!iswalpha(L'3'));
      CHECK (iswalnum(L'9'));
      CHECK (!iswalnum(L'$'));
      CHECK (iswcntrl(L'\n'));
      CHECK (!iswcntrl(L'#'));
      CHECK (iswdigit(L'2'));
      CHECK (!iswdigit(L'a'));
      CHECK (iswgraph(L'2'));
      CHECK (!iswgraph(L' '));
      CHECK (iswlower(L'g'));
      CHECK (!iswlower(L'G'));
      CHECK (iswprint(L'*'));
      CHECK (!iswprint(L'\n'));
      CHECK (iswpunct(L','));
      CHECK (!iswpunct(L'\n'));
      CHECK (iswspace(L'\t'));
      CHECK (!iswspace(L':'));
      CHECK (iswupper(L'G'));
      CHECK (!iswupper(L'g'));
      CHECK (iswxdigit(L'A'));
      CHECK (!iswxdigit(L'g'));
    }
  else
    {
      setlocale (LC_CTYPE, "C-UTF-8");
      CHECK (iswalpha(0x0967));
      CHECK (!iswalpha(0x128e));
      CHECK (iswalnum(0x1d7ce));
      CHECK (!iswalnum(0x1d800));
      CHECK (iswcntrl(0x007f));
      CHECK (!iswcntrl(0x2027));
      CHECK (iswdigit(L'2'));
      CHECK (!iswdigit(0x0009));
      CHECK (iswlower(0x03b3));
      CHECK (!iswlower(0x04aa));
      CHECK (iswprint(0x0b13));
      CHECK (!iswprint(0x0ce2));
      CHECK (iswpunct(0x002d));
      CHECK (!iswpunct(0x0a84));
      CHECK (iswspace(0x000a));
      CHECK (!iswspace(0x2060));
      CHECK (iswupper(0x01a4));
      CHECK (!iswupper(0x1e6d));
      CHECK (iswxdigit(L'A'));
      CHECK (!iswxdigit(0x1f48));
    }
#endif

  exit (0);
}
