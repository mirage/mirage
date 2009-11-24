#ifndef _XEN_SYMBOLS_H
#define _XEN_SYMBOLS_H

#include <xen/config.h>
#include <xen/types.h>

#define KSYM_NAME_LEN 127

/* Lookup an address. */
const char *symbols_lookup(unsigned long addr,
                           unsigned long *symbolsize,
                           unsigned long *offset,
                           char *namebuf);

/* Replace "%s" in format with address, if found */
void __print_symbol(const char *fmt, unsigned long address);

/* This macro allows us to keep printk typechecking */
static void __check_printsym_format(const char *fmt, ...)
    __attribute__((format(printf,1,2)));
    static inline void __check_printsym_format(const char *fmt, ...)
{
}

/* ia64 and ppc64 use function descriptors, which contain the real address */
#if defined(CONFIG_IA64) || defined(CONFIG_PPC64)
#define print_fn_descriptor_symbol(fmt, addr)		\
do {						\
	unsigned long *__faddr = (unsigned long*) addr;		\
	print_symbol(fmt, __faddr[0]);		\
} while (0)
#else
#define print_fn_descriptor_symbol(fmt, addr) print_symbol(fmt, addr)
#endif

#define print_symbol(fmt, addr)			\
do {						\
	__check_printsym_format(fmt, "");	\
	__print_symbol(fmt, addr);		\
} while(0)

#endif /*_XEN_SYMBOLS_H*/
