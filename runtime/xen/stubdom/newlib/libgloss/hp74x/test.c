extern int led_putnum();
#define DELAY 900000
extern char strobe(),putDebugChar(),print(),putnum(); 
extern char foobar();
extern char breakpoint();

#define TESTSTUB 1

main()
{
  unsigned char x;
  char buf[20];

#if TESTIO
  strobe();
  outbyte ('\n');
  outbyte ('$');
  write (2, "Enter 5 characters... ", 24);
  read (0, buf, 5);
  print (buf);
  print ("\r\n");
  strobe ();
#endif
  
#if TESTSTUB
  print ("\r\nInit vectors...\r\n");
/***  set_debug_traps(); ***/
  print ("\r\nSet a breakpoint...\r\n");
  handle_exception();
/***  breakpoint(); ***/
#endif

  print ("\r\nTest foobar\r\n");
  foobar();
  /* whew, we made it */
  print ("\r\nDone...");
}

/*
 * FIXME: this is only hear so things will link.
 */	
int
puts(s)
     char *s;
{
  s++;
}
