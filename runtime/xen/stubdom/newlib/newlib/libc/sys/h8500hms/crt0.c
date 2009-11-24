
extern char _start_bss;
extern char end;
extern char stack;

static zeroandrun();
#pragma noprolog

start()
{
  asm("mov.w #%off(_stack),sp");
/*  asm("ldc.w  #0x700,sr");*/
  asm("ldc.b  #%page(_stack),tp");
  asm("ldc.b  #%page(_stack),dp");
  asm("ldc.b  #%page(_stack),ep");
  /* Can't have anything else in here, since the fp won't be set up
     so local variables won't work */
  zeroandrun();
}

static
zeroandrun()
{
  char *p;
  p = &_start_bss;
  while (p < &end) 
    {
      *p++ = 0;
    }
  main();
  _exit();
}
