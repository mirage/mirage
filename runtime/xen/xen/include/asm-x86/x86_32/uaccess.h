#ifndef __i386_UACCESS_H
#define __i386_UACCESS_H

/*
 * Test whether a block of memory is a valid user space address.
 * Returns 0 if the range is valid, nonzero otherwise.
 *
 * This is equivalent to the following test:
 * (u33)addr + (u33)size >= (u33)HYPERVISOR_VIRT_START
 */
#define __range_not_ok(addr,size) ({ \
	unsigned long flag,sum; \
	asm("addl %3,%1 ; sbbl %0,%0; cmpl %1,%4; sbbl $0,%0" \
		:"=&r" (flag), "=r" (sum) \
		:"1" (addr),"g" ((int)(size)),"r" (HYPERVISOR_VIRT_START)); \
	flag; })

#define access_ok(addr,size) (likely(__range_not_ok(addr,size) == 0))

#define array_access_ok(addr,count,size) \
    (likely(count < (~0UL/size)) && access_ok(addr,count*size))

/* Undefined function to catch size mismatches on 64-bit get_user/put_user. */
extern void __uaccess_var_not_u64(void);

#define __put_user_u64(x, addr, retval, errret)			\
	if (sizeof(x) != 8) __uaccess_var_not_u64();		\
	__asm__ __volatile__(					\
		"1:	movl %%eax,0(%2)\n"			\
		"2:	movl %%edx,4(%2)\n"			\
		"3:\n"						\
		".section .fixup,\"ax\"\n"			\
		"4:	movl %3,%0\n"				\
		"	jmp 3b\n"				\
		".previous\n"					\
		".section __ex_table,\"a\"\n"			\
		"	.align 4\n"				\
		"	.long 1b,4b\n"				\
		"	.long 2b,4b\n"				\
		".previous"					\
		: "=r"(retval)					\
		: "A" (x), "r" (addr), "i"(errret), "0"(retval))

#define __put_user_size(x,ptr,size,retval,errret)			\
do {									\
	retval = 0;							\
	switch (size) {							\
	case 1: __put_user_asm(x,ptr,retval,"b","b","iq",errret);break;	\
	case 2: __put_user_asm(x,ptr,retval,"w","w","ir",errret);break; \
	case 4: __put_user_asm(x,ptr,retval,"l","","ir",errret); break;	\
	case 8: __put_user_u64((__typeof__(*ptr))(x),ptr,retval,errret);break;\
	default: __put_user_bad();					\
	}								\
} while (0)

#define __get_user_u64(x, addr, retval, errret)			\
	if (sizeof(x) != 8) __uaccess_var_not_u64();		\
	__asm__ __volatile__(					\
		"1:	movl 0(%2),%%eax\n"			\
		"2:	movl 4(%2),%%edx\n"			\
		"3:\n"						\
		".section .fixup,\"ax\"\n"			\
		"4:	movl %3,%0\n"				\
		"	xorl %%eax,%%eax\n"			\
		"	xorl %%edx,%%edx\n"			\
		"	jmp 3b\n"				\
		".previous\n"					\
		".section __ex_table,\"a\"\n"			\
		"	.align 4\n"				\
		"	.long 1b,4b\n"				\
		"	.long 2b,4b\n"				\
		".previous"					\
		: "=r" (retval), "=&A" (x)			\
		: "r" (addr), "i"(errret), "0"(retval))

#define __get_user_size(x,ptr,size,retval,errret)			\
do {									\
	retval = 0;							\
	switch (size) {							\
	case 1: __get_user_asm(x,ptr,retval,"b","b","=q",errret);break;	\
	case 2: __get_user_asm(x,ptr,retval,"w","w","=r",errret);break;	\
	case 4: __get_user_asm(x,ptr,retval,"l","","=r",errret);break;	\
	case 8: __get_user_u64(x,ptr,retval,errret);break;		\
	default: __get_user_bad();					\
	}								\
} while (0)

#endif /* __i386_UACCESS_H */
