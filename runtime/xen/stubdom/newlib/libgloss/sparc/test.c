#include "debug.h"

char hextab[] = "0123456789abcdef";

int
foo(arg)
     int arg;
{
  return arg+1;
}

int
fact (i)
     int i;
{
  if (i == 1)
    return 1;
  else
    return i * fact ( i - 1);
}

main()
{
  unsigned char c;
  int num;
  char foo[100];

#if 0
  set_debug_level(2);

  cache_on();
#endif

  set_debug_traps();
  breakpoint();

  print("Got to here\r\n");

  while (1) {
    c = inbyte();
    if (c == 'c')
      break;
    
    if (c == 'd') {
      set_debug_traps();
      breakpoint();
      break;
    }
    
    print("echo ");
    outbyte(c);
    print("\r\n");
  }

  print("Hello world\r\n");
  
  while (1) {
    c = inbyte();
    
    if ((c & 0x7f) == 4)
      break;
    
    print("Char is ");
    outbyte (c);
    print("\r\n");
  }
  
  print("I escaped!\r\n");
}
