/* This is mostly just a placeholder (copied from m88kbug) until we
   figure out what it really should be... -fnf */

extern int main(int argc, char **argv);

extern char _edata;
extern char _end;
extern char stack;

_start()
{
  char *p;

  p = &_edata + 1;
  while (p < &_end) 
    {
      *p++ = 0;
    }

  main(0, 0);
  _exit();
}
