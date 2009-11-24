#ifndef _LINUX_KERNEL_H
#define _LINUX_KERNEL_H

/*
 * 'kernel.h' contains some often-used function prototypes etc
 */

/*
 * min()/max() macros that also do
 * strict type-checking.. See the
 * "unnecessary" pointer comparison.
 */
#define min(x,y) ({ \
        const typeof(x) _x = (x);       \
        const typeof(y) _y = (y);       \
        (void) (&_x == &_y);            \
        _x < _y ? _x : _y; })

#define max(x,y) ({ \
        const typeof(x) _x = (x);       \
        const typeof(y) _y = (y);       \
        (void) (&_x == &_y);            \
        _x > _y ? _x : _y; })

/*
 * ..and if you can't take the strict
 * types, you can specify one yourself.
 *
 * Or not use min/max at all, of course.
 */
#define min_t(type,x,y) \
        ({ type __x = (x); type __y = (y); __x < __y ? __x: __y; })
#define max_t(type,x,y) \
        ({ type __x = (x); type __y = (y); __x > __y ? __x: __y; })

/**
 * container_of - cast a member of a structure out to the containing structure
 *
 * @ptr:	the pointer to the member.
 * @type:	the type of the container struct this is embedded in.
 * @member:	the name of the member within the struct.
 *
 */
#define container_of(ptr, type, member) ({                      \
        typeof( ((type *)0)->member ) *__mptr = (ptr);          \
        (type *)( (char *)__mptr - offsetof(type,member) );})

/*
 * Check at compile time that something is of a particular type.
 * Always evaluates to 1 so you may use it easily in comparisons.
 */
#define typecheck(type,x)                       \
({	type __dummy;                           \
	typeof(x) __dummy2;                     \
	(void)(&__dummy == &__dummy2);          \
	1;                                      \
})

extern char _start[], _end[];
#define is_kernel(p) ({                         \
    char *__p = (char *)(unsigned long)(p);     \
    (__p >= _start) && (__p <= _end);           \
})

extern char _stext[], _etext[];
#define is_kernel_text(p) ({                    \
    char *__p = (char *)(unsigned long)(p);     \
    (__p >= _stext) && (__p <= _etext);         \
})

extern char _sinittext[], _einittext[];
#define is_kernel_inittext(p) ({                \
    char *__p = (char *)(unsigned long)(p);     \
    (__p >= _sinittext) && (__p <= _einittext); \
})

#endif /* _LINUX_KERNEL_H */

