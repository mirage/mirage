#ifndef _UTILS_H
#define _UTILS_H
#include <stdbool.h>
#include <string.h>
#include <stdint.h>

/* Is A == B ? */
#define streq(a,b) (strcmp((a),(b)) == 0)

/* Does A start with B ? */
#define strstarts(a,b) (strncmp((a),(b),strlen(b)) == 0)

/* Does A end in B ? */
static inline bool strends(const char *a, const char *b)
{
	if (strlen(a) < strlen(b))
		return false;

	return streq(a + strlen(a) - strlen(b), b);
}

#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

void barf(const char *fmt, ...) __attribute__((noreturn));
void barf_perror(const char *fmt, ...) __attribute__((noreturn));

void (*xprintf)(const char *fmt, ...);

#define eprintf(_fmt, _args...) xprintf("[ERR] %s" _fmt, __FUNCTION__, ##_args)

/*
 * Mux errno values onto returned pointers.
 */

static inline void *ERR_PTR(long error)
{
	return (void *)error;
}

static inline long PTR_ERR(const void *ptr)
{
	return (long)ptr;
}

static inline long IS_ERR(const void *ptr)
{
	return ((unsigned long)ptr > (unsigned long)-1000L);
}


#endif /* _UTILS_H */

/*
 * Local variables:
 *  c-file-style: "linux"
 *  indent-tabs-mode: t
 *  c-indent-level: 8
 *  c-basic-offset: 8
 *  tab-width: 8
 * End:
 */
