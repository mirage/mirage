extern int main(int argc, char **argv);

extern char edata;
extern char end;
extern char stack;

_start()
{
  char *p;

  p = &edata + 1;
  while (p < &end) 
    {
      *p++ = 0;
    }

  main(0, 0);
  _exit();
}
