/* Oki bug report [OKI013] 

   Variable argments test failed.

   Execution result.
   val1, val2 = 1, 0
   val1, val2 = 2, 0
   val1, val2 = 3, 0

   Note, this test case for for traditional style C code.

 */

#include <stdio.h>
#include <varargs.h>
int     func();

main()
{
        func(1., 2., 3.);
}

func(va_alist)
     va_dcl
{
        va_list p;
	double val1, val2;
        int j;

        va_start(p);
        for (j = 1; j <= 3; ++j){
                dequals((double)j, va_arg(p, double));
        }
        va_end(p);
        return (p);
}

dequals(double val1, double val2)
{
        iprintf ("val1 is %d, val2 is %d\n", (int)val1, (int)val2);
        if (val1 == val2)
                pass ("varargs2 [OKI013]");
        else
                fail ("varargs2 [OKI013]");

        fflush (stdout);
        return;
}
