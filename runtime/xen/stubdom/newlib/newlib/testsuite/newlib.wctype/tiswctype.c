#include <wctype.h>
#include <newlib.h>
#include "check.h"

int main()
{
  wctype_t x;

  x = wctype ("alpha");
  CHECK (x != 0);
  CHECK (iswctype (L'a', x) && isalpha ('a'));

  x = wctype ("alnum");
  CHECK (x != 0);
  CHECK (iswctype (L'0', x) && isalnum ('0'));

  x = wctype ("blank");
  CHECK (x != 0);
  CHECK (iswctype (L' ', x) && isblank (' '));

  x = wctype ("cntrl");
  CHECK (x != 0);
  CHECK (iswctype (L'\n', x) && iscntrl ('\n'));

  x = wctype ("digit");
  CHECK (x != 0);
  CHECK (iswctype (L'7', x) && isdigit ('7'));

  x = wctype ("graph");
  CHECK (x != 0);
  CHECK (iswctype (L'!', x) && isgraph ('!'));

  x = wctype ("lower");
  CHECK (x != 0);
  CHECK (iswctype (L'k', x) && islower ('k'));

  x = wctype ("print");
  CHECK (x != 0);
  CHECK (iswctype (L'@', x) && isprint ('@'));

  x = wctype ("punct");
  CHECK (x != 0);
  CHECK (iswctype (L'.', x) && ispunct ('.'));

  x = wctype ("space");
  CHECK (x != 0);
  CHECK (iswctype (L'\t', x) && isspace ('\t'));

  x = wctype ("upper");
  CHECK (x != 0);
  CHECK (iswctype (L'T', x) && isupper ('T'));

  x = wctype ("xdigit");
  CHECK (x != 0);
  CHECK (iswctype (L'B', x) && isxdigit ('B'));

  x = wctype ("unknown");
  CHECK (x == 0);

  exit (0);
}
