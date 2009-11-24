/* Oki bug report [OKI013]
 
   Variable argments test failed.

   Execution result.
   val1, val2 = 1, 0
   val1, val2 = 2, 0
   val1, val2 = 3, 0

   Note, this tests for ANSI style varargs.

 */

#include <stdio.h>
#include <stdarg.h>
int     func(int, ...);

main()
{
        func(2, 1., 2., 3.);
}

func(int i, ...)
{
        va_list p;
        int j;

        va_start(p, i);
        for (j = 1; j <= 3; ++j){
                dequals(__LINE__, (double)j, va_arg(p, double));
        }
        va_end(p);
        return (i);
}

dequals(int line, double val1, double val2)
{
        iprintf ("val1, val2 = %d, %d\n", (int)val1, (int)val2);
        if(val1 == val2)
                pass ("varargs [OKI013]");
        else
                fail ("varargs [OKI013]");

        fflush (stdout);
        return;
}
