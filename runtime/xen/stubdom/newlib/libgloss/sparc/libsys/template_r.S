/* reentrant system call template */

/* Lots of system calls are trivial functions, so we build their source files
   from a template.  New syscalls can be added simply by editing the
   Makefile!

   The system calls aren't necessarily reentrant.  If we were being used in
   an embedded system they could be.  Reentrant syscalls are also used,
   however, to provide ANSI C namespace clean access to the host o/s.

   Usage: Compile this file with "func" set to the name of the syscall.  */

#include "syscallasm.h"

#define concat(a,b)	a##b
#define concat3(a,b,c)	a##b##c
#define makesys(a)	concat (SYS_, a)
#define make_r_fn(a)	concat3 (_, a, _r)

/* The leading _'s get turned into #'s by the Makefile.  */

_ifdef REENT
	defsyscall_r (make_r_fn (func), makesys (func))
_else
	defsyscall (func, makesys (func))
_endif
