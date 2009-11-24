/* Oki bug report [OKI006]

        The following program is no work.

	illegal trap: 0x12 pc=d000d954
	d000d954 08000240  NOP
 */

#include <stdio.h>

main ()
{
        int i, j, k;

        print ("\r\nDemo Program Start\r\n");
        printf ("Value = %d, %d\r\n", 2, 1);
	pass ("printf [OKI006]");
	
/* Oki bug report [OKI007]

        iprintf is no work.
        "Value = 2, 1" string is not displayed.
	
	break instruction trap (9) pc=4003c
	0004003c 00000000  BREAK 0x0,0x0
 */
        print ("\r\nDemo Program Start\r\n");
        iprintf ("Value = %d, %d\r\n", 2, 1);
	pass ("iprintf [OKI007]");
	fflush (stdout);
}
