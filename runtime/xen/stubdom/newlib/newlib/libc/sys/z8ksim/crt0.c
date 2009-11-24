extern char _start_bss;
extern char _end_bss;
extern int main(int argc, char **argv, char **environ);
void __main();

static void
enter()
{
#if defined(__Z8002__)
  __main();
#endif
  exit(main(0,0,0));
}
start()
{
  char *p;
#if defined(__Z8002__)
  asm("ld	r15,#__stack_top");
  asm("ld	r10,r15");
#endif
#if defined(__Z8001__)
  asm("ldl	rr14,#__stack_top");
  asm("ldl	rr10,rr14");
#endif


  /* zero bss */
  p = &_start_bss;
  while (p < & _end_bss) 
  {
    *p++ = 0;
  }
  enter();
}

#if defined(__Z8002__)
void __do_global_ctors ()
{
  typedef void (*pfunc)();
  extern pfunc __ctors[];
  extern pfunc __ctors_end[];
  pfunc *p;
  for (p = __ctors_end; p > __ctors; )
    {
      (*--p)();
    }
}

void __main()
{
  static int initialized;
  if (! initialized)
    {
      initialized = 1;
      __do_global_ctors ();
    }
}
#endif
