#define _GNU_SOURCE
#include <utmpx.h>

void __utmpxname (const char *file);

void
utmpxname (const char *file) {
    __utmpxname (file);
    return;
}
