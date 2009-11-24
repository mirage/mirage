/*
FUNCTION
	<<strupr>>---force string to uppercase
	
INDEX
	strupr

ANSI_SYNOPSIS
	#include <string.h>
	char *strupr(char *<[a]>);

TRAD_SYNOPSIS
	#include <string.h>
	char *strupr(<[a]>)
	char *<[a]>;

DESCRIPTION
	<<strupr>> converts each character in the string at <[a]> to
	uppercase.

RETURNS
	<<strupr>> returns its argument, <[a]>.

PORTABILITY
<<strupr>> is not widely portable.

<<strupr>> requires no supporting OS subroutines.

QUICKREF
	strupr */

#include <string.h>
#include <ctype.h>

char *
strupr (a)
     char *a;
{
  char *ret = a;

  while (*a != '\0')
    {
      if (islower (*a))
	*a = toupper (*a);
      ++a;
    }

  return ret;
}
