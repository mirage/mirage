// Perform a system call.
// Unused parameters should be set to 0.
int __trap0(unsigned long func, unsigned long p1, unsigned long p2, unsigned long p3)
{
  int ret = 0;
  asm volatile ("nop\n\tor %%4,%%0,%0" : : "r"(func));
  asm volatile ("nop\n\tor %%5,%%0,%0" : : "r"(p1));
  asm volatile ("nop\n\tor %%6,%%0,%0" : : "r"(p2));
  asm volatile ("nop\n\tor %%7,%%0,%0" : : "r"(p3));
  asm volatile ("nop\n\tor %%11,%%0,%0" : : "r"(func));
  asm volatile ("syscall\n\tnop\n\tor %0,%%0,%%2" : "=r"(ret));
  return ret;
}
