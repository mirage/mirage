#include "dietfeatures.h"

#ifdef WANT_LINKER_WARNINGS

#ifndef __ASSEMBLER__

#define link_warning(symbol,msg) \
  asm (".section .gnu.warning." symbol "\n\t.string \"" msg "\"\n\t.previous");

#else

#define link_warning(symbol,msg) \
  .section .gnu.warning.##symbol ;\
  .string msg ;\
  .previous

#endif

#else

#define link_warning(foo,bar)

#endif
