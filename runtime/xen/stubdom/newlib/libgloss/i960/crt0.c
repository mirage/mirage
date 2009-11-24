extern int main(int argc, char **argv, char **envp);
extern int brk (void *value);

extern char bss_start;
extern char end;

char *__env[1] = {0};
char **environ = __env;

#define ENABLE_TRACE_MASK 1

__inline static void 
enable_tracing (void)
{
    register int mask = ENABLE_TRACE_MASK;
    __asm__ volatile ("modpc %0,%0,%0"
	              :
	              : "d" (mask));
}

#define STACK_ALIGN 64

__inline static void
set_stack (void* ptr)
{
    ptr = (void *)(((int)ptr + STACK_ALIGN - 1) & ~(STACK_ALIGN - 1));
    /* SP must be 64 bytes larger than FP at start.  */
    __asm__ volatile ("mov %0,sp"
	              :
	              : "d" (ptr+STACK_ALIGN));
    __asm__ volatile ("mov %0,fp"
	              :
	              : "d" (ptr));
}

__inline static void 
init_Cregs (void)
{
    /* set register values gcc like */
    register unsigned int mask0=0x3b001000;
    register unsigned int mask1=0x00009107;
    __asm__ volatile ("mov   %0,g14"
                      :                      /* no output */
                      : "I" (0));            /* gnu structure pointer */
    __asm__ volatile ("modac %1,%0,%0"
                      :                      /* no output */
                      : "d" (mask0),
                        "d" (mask1));        /* fpu control kb */
}

void
_start(void)
{
  char *p;

  enable_tracing ();
  set_stack (&end);
  init_Cregs ();
  /* The stack grows upwards, so this makes the heap start after a 256K
     stack area.  PlumHall known to fail with less than 73K of stack.  */
  brk (&end+0x40000);
  /* clear bss */
  memset (&bss_start, 0, &end - &bss_start);
  main(0, 0, 0);
  exit(0);
}
