/*
 * support.c -- minimal support functions. This is to keep the exit code
 * 	generic enough that pattern matching from expect should be easier.
 */

#if defined (unix)
#define PRINT printf		/* so we can test on a native system */
#else
#define PRINT iprintf		/* this is only in newlib */
#endif

int
fail (str)
char *str;
{
     PRINT ("FAIL: %s\n", str);
}

int
pass (str)
char *str;
{
     PRINT ("PASS: %s\n", str);
}
