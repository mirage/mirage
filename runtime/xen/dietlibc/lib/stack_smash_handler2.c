#include <unistd.h>
#include <write12.h>

void __stack_chk_fail(void);

/* earlier versions of ProPolice actually gave the address and function
 * name as arguments to the handler, so it could print some useful
 * diagnostics.  No more. :-( */
void __stack_chk_fail(void) {
  __write2("smashed stack detected, program terminated.\n");
  _exit(127);
}
