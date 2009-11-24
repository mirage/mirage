#ifndef __LIB_H__
#define __LIB_H__

#include <xen/inttypes.h>
#include <xen/stdarg.h>
#include <xen/config.h>
#include <xen/types.h>
#include <xen/xmalloc.h>
#include <xen/string.h>
#include <asm/bug.h>

void __bug(char *file, int line) __attribute__((noreturn));
void __warn(char *file, int line);

#define BUG_ON(p)  do { if (unlikely(p)) BUG();  } while (0)
#define WARN_ON(p) do { if (unlikely(p)) WARN(); } while (0)

/* Force a compilation error if condition is true */
#define BUILD_BUG_ON(condition) ((void)sizeof(struct { int:-!!(condition); }))

/* Force a compilation error if condition is true, but also produce a
   result (of value 0 and type size_t), so the expression can be used
   e.g. in a structure initializer (or where-ever else comma expressions
   aren't permitted). */
#define BUILD_BUG_ON_ZERO(e) (sizeof(struct { int:-!!(e); }))

#ifndef assert_failed
#define assert_failed(p)                                        \
do {                                                            \
    printk("Assertion '%s' failed, line %d, file %s\n", #p ,    \
                   __LINE__, __FILE__);                         \
    BUG();                                                      \
} while (0)
#endif

#ifndef NDEBUG
#define ASSERT(p) \
    do { if ( unlikely(!(p)) ) assert_failed(p); } while (0)
#else
#define ASSERT(p) ((void)0)
#endif

#define SWAP(_a, _b) \
   do { typeof(_a) _t = (_a); (_a) = (_b); (_b) = _t; } while ( 0 )

#define DIV_ROUND(x, y) (((x) + (y) / 2) / (y))

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]) + __must_be_array(x))

#define reserve_bootmem(_p,_l) ((void)0)

struct domain;

void cmdline_parse(char *cmdline);

/*#define DEBUG_TRACE_DUMP*/
#ifdef DEBUG_TRACE_DUMP
extern void debugtrace_dump(void);
extern void debugtrace_printk(const char *fmt, ...);
#else
#define debugtrace_dump()          ((void)0)
#define debugtrace_printk(_f, ...) ((void)0)
#endif

/* Allows us to use '%p' as general-purpose machine-word format char. */
#define _p(_x) ((void *)(unsigned long)(_x))
extern void printk(const char *format, ...)
    __attribute__ ((format (printf, 1, 2)));
extern void panic(const char *format, ...)
    __attribute__ ((format (printf, 1, 2)));
extern long vm_assist(struct domain *, unsigned int, unsigned int);
extern int __printk_ratelimit(int ratelimit_ms, int ratelimit_burst);
extern int printk_ratelimit(void);

/* vsprintf.c */
#define sprintf __xen_has_no_sprintf__
#define vsprintf __xen_has_no_vsprintf__
extern int snprintf(char * buf, size_t size, const char * fmt, ...)
    __attribute__ ((format (printf, 3, 4)));
extern int vsnprintf(char *buf, size_t size, const char *fmt, va_list args)
    __attribute__ ((format (printf, 3, 0)));
extern int scnprintf(char * buf, size_t size, const char * fmt, ...)
    __attribute__ ((format (printf, 3, 4)));
extern int vscnprintf(char *buf, size_t size, const char *fmt, va_list args)
    __attribute__ ((format (printf, 3, 0)));
extern int sscanf(const char * buf, const char * fmt, ...)
    __attribute__ ((format (scanf, 2, 3)));
extern int vsscanf(const char * buf, const char * fmt, va_list args)
    __attribute__ ((format (scanf, 2, 0)));

long simple_strtol(
    const char *cp,const char **endp, unsigned int base);
unsigned long simple_strtoul(
    const char *cp,const char **endp, unsigned int base);
long long simple_strtoll(
    const char *cp,const char **endp, unsigned int base);
unsigned long long simple_strtoull(
    const char *cp,const char **endp, unsigned int base);

unsigned long long parse_size_and_unit(const char *s, const char **ps);

uint64_t muldiv64(uint64_t a, uint32_t b, uint32_t c);

#define TAINT_UNSAFE_SMP                (1<<0)
#define TAINT_MACHINE_CHECK             (1<<1)
#define TAINT_BAD_PAGE                  (1<<2)
#define TAINT_SYNC_CONSOLE              (1<<3)
#define TAINT_ERROR_INJECT              (1<<4)
extern int tainted;
#define TAINT_STRING_MAX_LEN            20
extern char *print_tainted(char *str);
extern void add_taint(unsigned);

#endif /* __LIB_H__ */
