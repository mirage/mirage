#include <stdio.h>

extern "C" void print (char *, ...);

class foo
{
public:
  foo () { print ("ctor\n"); }
  ~foo () { print ("dtor\n"); }
};

foo x;

main ()
{
  outbyte ('&');
  outbyte ('@');
  outbyte ('$');
  outbyte ('%');
  print ("FooBar\r\n");

  /* whew, we made it */
  print ("\r\nDone...\r\n");
  fflush(stdout);
}
