#ifndef _ASM_IA64_XENTYPES_H
#define _ASM_IA64_XENTYPES_H

#ifndef __ASSEMBLY__
typedef unsigned long ssize_t;
typedef unsigned long size_t;
typedef long long loff_t;

typedef char bool_t;
#define test_and_set_bool(b)   xchg(&(b), 1)
#define test_and_clear_bool(b) xchg(&(b), 0)

#define BYTES_PER_LONG  8

#endif /* !__ASSEMBLY__ */

#endif /* _ASM_IA64_XENTYPES_H */
