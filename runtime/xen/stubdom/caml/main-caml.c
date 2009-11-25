/*
 * Caml bootstrap
 *
 * Samuel Thibault <Samuel.Thibault@eu.citrix.net>, January 2008
 */

#include <stdio.h>
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <unistd.h>

/* Ugly binary compatibility with Linux */
FILE *_stderr asm("stderr");
int *__errno_location;
/* Will probably break everything, probably need to fetch from glibc */
void *__ctype_b_loc;

int main(int argc, char *argv[], char *envp[])
{
    value *val;

    /* Get current thread's value */
    _stderr = stderr;
    __errno_location = &errno;

    printf("starting caml\n");

    /* Wait before things might hang up */
    sleep(1);

    caml_startup(argv);
    val = caml_named_value("main");
    if (!val) {
        printf("Couldn't find Caml main");
        return 1;
    }
    caml_callback(*val, Val_int(0));
    printf("callback returned\n");
    return 0;
}
