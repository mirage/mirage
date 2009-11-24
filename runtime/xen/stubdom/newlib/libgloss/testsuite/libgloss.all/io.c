/*
 io.c -- Test the serial I/O.
 */

#define BUFSIZE 80
#include <stdio.h>

main()
{
  char buf[100];
  char *tmp;
  int result;

  /* test the lowest level output function */
  result = outbyte ('&');
  if (result != 0x0) {
    pass ("outbyte");
  } else {
    fail ("outbyte");
  }

  /* try writing a string */
  result = write ("Write Test:\n", 12);
  print ("result was ");
  putnum (result);
  outbyte ('\n');
  if (result == 12) {
    pass ("write");
  } else {
    fail ("write");
  }

  /* try the print() function too */
  result = print ("Print Test:\n");
  print ("result was ");
  putnum (result);
  outbyte ('\n');
  if (result == 12) {
    pass ("print");
  } else {
    fail ("print");
  }

  /* try the iprintf() function too */
  result = print ("Iprintf Test:\n");
  print ("result was ");
  putnum (result);
  outbyte ('\n');
  if (result == 14) {
    pass ("iprintf");
  } else {
    fail ("iprintf");
  }  

  /* try to read a string */
  print ("Type 5 characters");

  result = 0;
  result = read (0, buf, 5);
  print (buf);
  if (result == 5) {
    pass ("read");
  } else {
    fail ("read");
  }  

  /* clear everything out */
  fflush (stdout);
}


