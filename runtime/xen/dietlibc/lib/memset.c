#include <sys/types.h>
#include <string.h>

/* gcc is broken and has a non-SUSv2 compliant internal prototype.
 * This causes it to warn about a type mismatch here.  Ignore it. */
void* memset(void * dst, int s, size_t count) {
    register char * a = dst;
    count++;	/* this actually creates smaller code than using count-- */
    while (--count)
	*a++ = s;
    return dst;
}
