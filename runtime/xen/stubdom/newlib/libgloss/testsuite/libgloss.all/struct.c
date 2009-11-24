/* Oki bug report, no number. Here's the output the error generates.

    gcc -c -g -ansi  oki008.c -o oki008.o -msoft-float
        oki008.c: In function `Proc0':
        oki008.c:50: internal error--insn does not satisfy its constraints:
        (insn 37 35 24 (set (mem:DF (post_inc:DF (reg:SI 1 %r1)))
            (reg:DF 48 %fr12)) 94 {reload_outdf+2} (nil)
            (nil))
        gcc: Internal compiler error: program cc1 got fatal signal 6
 */

#include <stdio.h>

typedef int     Enumeration;
typedef int     OneToFifty;
typedef char String30[31];
struct  Record
{
        struct Record           *PtrComp;
        Enumeration             Discr;
        Enumeration             EnumComp;
        OneToFifty              IntComp;
        String30                StringComp;
};

typedef struct Record   RecordType;
typedef RecordType *    RecordPtr;
typedef int             boolean;

#include <stdio.h>

char buf[0x10000];
char *pbuf = buf;

char *_malloc(size)
{
        char *p;

        p = pbuf;
        pbuf += size;
        if (pbuf >= &buf[sizeof (buf)]) {
                printf("_malloc error\n");
                return (0);
        }
        return (p);
}

main()
{
        Proc0();
	pass ("struct");
	fflush (stdout);
        return (0);
}

RecordPtr       PtrGlbNext;

Proc0()
{
        extern char             *_malloc();

        register unsigned int   i;

        PtrGlbNext = (RecordPtr) _malloc(sizeof(RecordType));
}
