/* system call template */

/* Lots of system calls are trivial functions, so we build their source files
   from a template.  New syscalls can be added simply by editing the
   Makefile!

   Usage: Compile this file with "func" set to the name of the syscall.  */

#include "syscallasm.h"

#define concat(a,b) a##b
#define makesys(a)  concat (SYS_, a)

	defsyscall (func, makesys(func))
