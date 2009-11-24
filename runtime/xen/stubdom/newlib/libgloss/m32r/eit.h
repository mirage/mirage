/* M32R libgloss EIT interface.
   Copyright (C) 1998, Cygnus Solutions.

   At present we only document trap 0, the syscall interface.
   In the future this can hold further EIT related stuff.
   [The m32r manuals use the acronym EIT: exception, interrupt, trap.]  */

#include <reent.h>

int __trap0 (int function, int p1, int p2, int p3, struct _reent *r);

#define TRAP0(f, p1, p2, p3) \
__trap0 (f, (int) (p1), (int) (p2), (int) (p3), _REENT)
