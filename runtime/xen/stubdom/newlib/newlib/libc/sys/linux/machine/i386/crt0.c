/* libc/sys/linux/crt0.c - Run-time initialization */

/* FIXME: This should be rewritten in assembler and
          placed in a subdirectory specific to a platform.
          There should also be calls to run constructors. */

/* Written 2000 by Werner Almesberger */


#include <stdlib.h>
#include <time.h>
#include <string.h>


extern char **environ;

extern int main(int argc,char **argv,char **envp);

extern char _end;
extern char __bss_start;

void _start(int args)
{
    /*
     * The argument block begins above the current stack frame, because we
     * have no return address. The calculation assumes that sizeof(int) ==
     * sizeof(void *). This is okay for i386 user space, but may be invalid in
     * other cases.
     */
    int *params = &args-1;
    int argc = *params;
    char **argv = (char **) (params+1);

    environ = argv+argc+1;

    /* Note: do not clear the .bss section.  When running with shared
     *       libraries, certain data items such __mb_cur_max or environ
     *       may get placed in the .bss, even though they are initialized
     *       to non-zero values.  Clearing the .bss will end up zeroing
     *       out their initial values.  The .bss is already initialized
     *       by this time by Linux.  */

    tzset(); /* initialize timezone info */
    exit(main(argc,argv,environ));
}
