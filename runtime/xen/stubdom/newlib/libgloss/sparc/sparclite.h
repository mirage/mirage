/* SPARClite defs
 *
 * Copyright (c) 1995 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

/* Macros for reading and writing to arbitrary address spaces.  Note that ASI
   must be a constant (sorry, but the SPARC can only specify ASIs as part of an
   instruction.  */

#define read_asi(ASI, LOC)						\
  ({									\
    unsigned int val;							\
    __asm__ volatile ("lda [%r1]%2,%0" : "=r" (val) : "rJ" (LOC), "I" (ASI)); \
    val;								\
  })

#define write_asi(ASI, LOC, VAL) \
  __asm__ volatile ("sta %0,[%r1]%2" : : "r" (VAL), "rJ" (LOC), "I" (ASI))

/* Use this when modifying registers that cause memory to be modified.  This
   will cause GCC to reload all values after this point.  */

#define write_asi_volatile(ASI, LOC, VAL) \
  __asm__ volatile ("sta %0,[%r1]%2" : : "r" (VAL), "rJ" (LOC), "I" (ASI) \
		    : "memory")

/* Read the PSR (processor state register). */

#define read_psr()							\
  ({									\
    unsigned int psr;							\
    __asm__ ("mov %%psr, %0" : "=r" (psr));				\
    psr;								\
  })

/* Write the PSR. */

#define write_psr(VAL)							\
  __asm__ ("mov %0, %%psr \n nop \n nop \n nop" : : "r" (VAL))

/* Read the specified Ancillary State Register. */

#define read_asr(REG) read_asr1(REG)
#define read_asr1(REG)							\
  ({									\
    unsigned int val;							\
    __asm__ ("rd %%asr" #REG ",%0" : "=r" (val));			\
    val;								\
  })

/* Write the specified Ancillary State Register. */

#define write_asr(REG, VAL) write_asr1(REG, VAL)
#define write_asr1(REG, VAL)						\
    __asm__ ("wr %0, 0, %%asr" #REG : : "r" (VAL))

/* Set window size for window overflow and underflow trap handlers.  Better to
   do this at at compile time than to calculate them at compile time each time
   we get a window overflow/underflow trap.  */

#ifdef SL933
	asm ("__WINSIZE=6");
#else
	asm ("__WINSIZE=8");
#endif

#define PSR_INIT   0x10c0       /* Disable traps, set s and ps */
#define TBR_INIT   0
#define WIM_INIT   2
#define STACK_SIZE 16 * 1024

