#include <stdio.h>
#include <string.h>


int
main (void)
{
  char buf[100];
  int result = 0;

  if (sprintf (buf, "%.0ls", L"foo") != 0
      || strlen (buf) != 0)
    {
      puts ("sprintf (buf, \"%.0ls\", L\"foo\") produced some output\n");
      result = 1;
    }

  return result;
}
