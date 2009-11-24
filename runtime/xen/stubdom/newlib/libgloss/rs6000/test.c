extern int led_putnum();
extern char putDebugChar(),print(),putnum(); 

main()
{
  char buf[20];

  outbyte ('&');
  outbyte ('@');
  outbyte ('$');
  outbyte ('%');
  print ("FooBar\r\n");

#if 0
  write (2, "Enter 5 characters... ", 24);
  read (0, buf, 5);
  print (buf);
  print ("\r\n");
#endif
  
  /* whew, we made it */
  print ("\r\nDone...");
}
