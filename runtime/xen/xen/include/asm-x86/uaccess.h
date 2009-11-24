
#ifndef __X86_UACCESS_H__
#define __X86_UACCESS_H__

#include <xen/config.h>
#include <xen/compiler.h>
#include <xen/errno.h>
#include <xen/prefetch.h>
#include <asm/page.h>

#ifdef __x86_64__
#include <asm/x86_64/uaccess.h>
#else
#include <asm/x86_32/uaccess.h>
#endif

unsigned long copy_to_user(void *to, const void *from, unsigned len);
unsigned long copy_from_user(void *to, const void *from, unsigned len);
/* Handles exceptions in both to and from, but doesn't do access_ok */
unsigned long __copy_to_user_ll(void *to, const void *from, unsigned n);
unsigned long __copy_from_user_ll(void *to, const void *from, unsigned n);

extern long __get_user_bad(void);
extern void __put_user_bad(void);

/**
 * get_user: - Get a simple variable from user space.
 * @x:   Variable to store result.
 * @ptr: Source address, in user space.
 *
 * Context: User context only.  This function may sleep.
 *
 * This macro copies a single simple variable from user space to kernel
 * space.  It supports simple types like char and int, but not larger
 * data types like structures or arrays.
 *
 * @ptr must have pointer-to-simple-variable type, and the result of
 * dereferencing @ptr must be assignable to @x without a cast.
 *
 * Returns zero on success, or -EFAULT on error.
 * On error, the variable @x is set to zero.
 */
#define get_user(x,ptr)	\
  __get_user_check((x),(ptr),sizeof(*(ptr)))

/**
 * put_user: - Write a simple value into user space.
 * @x:   Value to copy to user space.
 * @ptr: Destination address, in user space.
 *
 * Context: User context only.  This function may sleep.
 *
 * This macro copies a single simple value from kernel space to user
 * space.  It supports simple types like char and int, but not larger
 * data types like structures or arrays.
 *
 * @ptr must have pointer-to-simple-variable type, and @x must be assignable
 * to the result of dereferencing @ptr.
 *
 * Returns zero on success, or -EFAULT on error.
 */
#define put_user(x,ptr)							\
  __put_user_check((__typeof__(*(ptr)))(x),(ptr),sizeof(*(ptr)))

/**
 * __get_user: - Get a simple variable from user space, with less checking.
 * @x:   Variable to store result.
 * @ptr: Source address, in user space.
 *
 * Context: User context only.  This function may sleep.
 *
 * This macro copies a single simple variable from user space to kernel
 * space.  It supports simple types like char and int, but not larger
 * data types like structures or arrays.
 *
 * @ptr must have pointer-to-simple-variable type, and the result of
 * dereferencing @ptr must be assignable to @x without a cast.
 *
 * Caller must check the pointer with access_ok() before calling this
 * function.
 *
 * Returns zero on success, or -EFAULT on error.
 * On error, the variable @x is set to zero.
 */
#define __get_user(x,ptr) \
  __get_user_nocheck((x),(ptr),sizeof(*(ptr)))

/**
 * __put_user: - Write a simple value into user space, with less checking.
 * @x:   Value to copy to user space.
 * @ptr: Destination address, in user space.
 *
 * Context: User context only.  This function may sleep.
 *
 * This macro copies a single simple value from kernel space to user
 * space.  It supports simple types like char and int, but not larger
 * data types like structures or arrays.
 *
 * @ptr must have pointer-to-simple-variable type, and @x must be assignable
 * to the result of dereferencing @ptr.
 *
 * Caller must check the pointer with access_ok() before calling this
 * function.
 *
 * Returns zero on success, or -EFAULT on error.
 */
#define __put_user(x,ptr) \
  __put_user_nocheck((__typeof__(*(ptr)))(x),(ptr),sizeof(*(ptr)))

#define __put_user_nocheck(x,ptr,size)				\
({								\
	long __pu_err;						\
	__put_user_size((x),(ptr),(size),__pu_err,-EFAULT);	\
	__pu_err;						\
})

#define __put_user_check(x,ptr,size)					\
({									\
	long __pu_err = -EFAULT;					\
	__typeof__(*(ptr)) __user *__pu_addr = (ptr);			\
	if (access_ok(__pu_addr,size))					\
		__put_user_size((x),__pu_addr,(size),__pu_err,-EFAULT);	\
	__pu_err;							\
})							

#define __get_user_nocheck(x,ptr,size)                          \
({                                                              \
	long __gu_err;                                          \
	__get_user_size((x),(ptr),(size),__gu_err,-EFAULT);     \
	__gu_err;                                               \
})

#define __get_user_check(x,ptr,size)                            \
({                                                              \
	long __gu_err;                                          \
	__typeof__(*(ptr)) __user *__gu_addr = (ptr);           \
	__get_user_size((x),__gu_addr,(size),__gu_err,-EFAULT); \
	if (!access_ok(__gu_addr,size)) __gu_err = -EFAULT;     \
	__gu_err;                                               \
})							

struct __large_struct { unsigned long buf[100]; };
#define __m(x) (*(const struct __large_struct *)(x))

/*
 * Tell gcc we read from memory instead of writing: this is because
 * we do not write to any memory gcc knows about, so there are no
 * aliasing issues.
 */
#define __put_user_asm(x, addr, err, itype, rtype, ltype, errret)	\
	__asm__ __volatile__(						\
		"1:	mov"itype" %"rtype"1,%2\n"			\
		"2:\n"							\
		".section .fixup,\"ax\"\n"				\
		"3:	mov %3,%0\n"					\
		"	jmp 2b\n"					\
		".previous\n"						\
		".section __ex_table,\"a\"\n"				\
		"	"__FIXUP_ALIGN"\n"				\
		"	"__FIXUP_WORD" 1b,3b\n"				\
		".previous"						\
		: "=r"(err)						\
		: ltype (x), "m"(__m(addr)), "i"(errret), "0"(err))

#define __get_user_asm(x, addr, err, itype, rtype, ltype, errret)	\
	__asm__ __volatile__(						\
		"1:	mov"itype" %2,%"rtype"1\n"			\
		"2:\n"							\
		".section .fixup,\"ax\"\n"				\
		"3:	mov %3,%0\n"					\
		"	xor"itype" %"rtype"1,%"rtype"1\n"		\
		"	jmp 2b\n"					\
		".previous\n"						\
		".section __ex_table,\"a\"\n"				\
		"	"__FIXUP_ALIGN"\n"				\
		"	"__FIXUP_WORD" 1b,3b\n"				\
		".previous"						\
		: "=r"(err), ltype (x)					\
		: "m"(__m(addr)), "i"(errret), "0"(err))

/**
 * __copy_to_user: - Copy a block of data into user space, with less checking
 * @to:   Destination address, in user space.
 * @from: Source address, in kernel space.
 * @n:    Number of bytes to copy.
 *
 * Context: User context only.  This function may sleep.
 *
 * Copy data from kernel space to user space.  Caller must check
 * the specified block with access_ok() before calling this function.
 *
 * Returns number of bytes that could not be copied.
 * On success, this will be zero.
 */
static always_inline unsigned long
__copy_to_user(void __user *to, const void *from, unsigned long n)
{
    if (__builtin_constant_p(n)) {
        unsigned long ret;

        switch (n) {
        case 1:
            __put_user_size(*(const u8 *)from, (u8 __user *)to, 1, ret, 1);
            return ret;
        case 2:
            __put_user_size(*(const u16 *)from, (u16 __user *)to, 2, ret, 2);
            return ret;
        case 4:
            __put_user_size(*(const u32 *)from, (u32 __user *)to, 4, ret, 4);
            return ret;
        case 8:
            __put_user_size(*(const u64 *)from, (u64 __user *)to, 8, ret, 8);
            return ret;
        }
    }
    return __copy_to_user_ll(to, from, n);
}

/**
 * __copy_from_user: - Copy a block of data from user space, with less checking
 * @to:   Destination address, in kernel space.
 * @from: Source address, in user space.
 * @n:    Number of bytes to copy.
 *
 * Context: User context only.  This function may sleep.
 *
 * Copy data from user space to kernel space.  Caller must check
 * the specified block with access_ok() before calling this function.
 *
 * Returns number of bytes that could not be copied.
 * On success, this will be zero.
 *
 * If some data could not be copied, this function will pad the copied
 * data to the requested size using zero bytes.
 */
static always_inline unsigned long
__copy_from_user(void *to, const void __user *from, unsigned long n)
{
    if (__builtin_constant_p(n)) {
        unsigned long ret;

        switch (n) {
        case 1:
            __get_user_size(*(u8 *)to, from, 1, ret, 1);
            return ret;
        case 2:
            __get_user_size(*(u16 *)to, from, 2, ret, 2);
            return ret;
        case 4:
            __get_user_size(*(u32 *)to, from, 4, ret, 4);
            return ret;
        case 8:
            __get_user_size(*(u64*)to, from, 8, ret, 8);
            return ret;
        }
    }
    return __copy_from_user_ll(to, from, n);
}

/*
 * The exception table consists of pairs of addresses: the first is the
 * address of an instruction that is allowed to fault, and the second is
 * the address at which the program should continue.  No registers are
 * modified, so it is entirely up to the continuation code to figure out
 * what to do.
 *
 * All the routines below use bits of fixup code that are out of line
 * with the main instruction path.  This means when everything is well,
 * we don't even have to jump over them.  Further, they do not intrude
 * on our cache or tlb entries.
 */

struct exception_table_entry
{
	unsigned long insn, fixup;
};

extern unsigned long search_exception_table(unsigned long);
extern void sort_exception_tables(void);

#endif /* __X86_UACCESS_H__ */
