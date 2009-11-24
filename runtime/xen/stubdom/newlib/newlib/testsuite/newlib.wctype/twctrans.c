#include <wctype.h>
#include <newlib.h>
#include "check.h"

int main()
{
  wctrans_t x;

  x = wctrans ("tolower");
  CHECK (x != 0);
  CHECK (towctrans (L'A', x) == tolower ('A'));
  CHECK (towctrans (L'5', x) == tolower ('5'));

  x = wctrans ("toupper");
  CHECK (x != 0);
  CHECK (towctrans (L'c', x) == toupper ('c'));
  CHECK (towctrans (L'9', x) == toupper ('9'));

  x = wctrans ("unknown");
  CHECK (x == 0);

  exit (0);
}
