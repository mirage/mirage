#include <_ansi.h>
#include <sys/types.h>
#include <sys/stat.h>


void _exit (n)
{
  // Set bit #0 in the _DEBUG_HALT_REG to trigger program exit to
  // the simulator. (The simulator will return a SIGQUIT signal.)
  asm("ori r1, r0, #$1\n");
  asm("stw r1, r0, #$fffff300\n");
}  // exit
