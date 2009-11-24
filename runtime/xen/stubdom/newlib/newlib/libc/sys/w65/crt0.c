

int p;
extern int edata;
extern int end;
start()
{
int  *s;
  asm ("lda #stack");
  asm ("tcs");
  for (s = &edata; s != &end; s++)
    *s = 0;

  main();
  exit(0);
}
