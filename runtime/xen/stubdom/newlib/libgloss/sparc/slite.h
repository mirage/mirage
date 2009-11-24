/*
 * Copyright (c) 1995, 1996 Cygnus Support
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

#define STACK_SIZE 16 * 1024
#define TRAP_STACK_SIZE 4 * 1024
#define NUM_REGS 20

#ifdef SL933
#define NUMBER_OF_REGISTER_WINDOWS 6
#else
#define NUMBER_OF_REGISTER_WINDOWS 8
#endif

#if (NUMBER_OF_REGISTER_WINDOWS == 8)
#define SPARC_PSR_CWP_MASK               0x07   /* bits  0 -  4 */
#elif (NUMBER_OF_REGISTER_WINDOWS == 16)
#define SPARC_PSR_CWP_MASK               0x0F   /* bits  0 -  4 */
#elif (NUMBER_OF_REGISTER_WINDOWS == 32)
#define SPARC_PSR_CWP_MASK               0x1F   /* bits  0 -  4 */
#else
#error "Unsupported number of register windows for this cpu"
#endif

/* The traptable has to be the first code in a boot PROM. */

/*
 *  Entry for traps which jump to a programmer-specified trap handler.
 */
 
#define TRAP(_handler)  \
  sethi %hi(_handler), %l3 ; \
  jmpl  %l3+%lo(_handler), %g0 ; \
  mov   %wim, %l0 ; \
  nop

/* Unexcpected trap will halt the processor by forcing it to error state */
#if 1
#define BAD_TRAP ta 0; nop; nop; nop;
#else
#define BAD_TRAP \
  mov   %psr, l0 ; \
  mov   0x0, %o0 ; \
  sethi %hi(SYM(bad_trap)), l4 ; \
  jmp   l4+%lo(SYM(bad_trap));
#endif

/* Software trap. Treat as BAD_TRAP for the time being... */
#if 1
#define SOFT_TRAP BAD_TRAP
#else
#define SOFT_TRAP \
  mov   $psr, $l0 ; \
  mov   0x0, $o0 ; \
  sethi $hi(SYM(soft_trap)), l4 ; \
  jmp   l4+$lo(SYM(soft_trap));
#endif

#define PSR_INIT   0x10c0       /* Disable traps, set s and ps */
#define TBR_INIT   0
#define WIM_INIT   2
#define SP_INIT    0x023ffff0

/* Macros for reading and writing to arbitrary address spaces.  Note that ASI
   must be a constant (sorry, but the SPARC can only specify ASIs as part of an
   instruction.  */

#define read_asi(ASI, LOC)                                              \
  ({                                                                    \
    unsigned int val;                                                   \
    __asm__ volatile ("lda [%r1]%2,%0" : "=r" (val) : "rJ" (LOC), "I" (ASI)); \
    val;                                                                \
  })

#define write_asi(ASI, LOC, VAL) \
  __asm__ volatile ("sta %0,[%r1]%2" : : "r" (VAL), "rJ" (LOC), "I" (ASI));

/*
 * Use this when modifying registers that cause memory to be modified.  This
 * will cause GCC to reload all values after this point.
 */
#define write_asi_volatile(ASI, LOC, VAL) \
  __asm__ volatile ("sta %0,[%r1]%2" : : "r" (VAL), "rJ" (LOC), "I" (ASI) \
                    : "memory");

#define	WRITE_PC(x)	registers[PC] = x; registers[NPC] = x + 4;

/*
 *		Processor Status Register (psr)
 *
 * 31	28|27	24|23	20|19	12|11	9|7|6|5|4	0
 * +------+-------+-------+-------+------+-+-+-+--------+
 * | impl |  ver  |  icc  | res.  | pil  | | | |  cwp   |
 * +------+-------+-------+-------+------+-+-+-+--------+
 *					  S P E
 *					    S T
 * if ET = 1, traps are enabled, 0 means disabled.
 * if S = 1, you're in supervisor mode, 0 means user mode.
 * cwp points to the current window.
 *
 *		Trap Base Register (tbr)
 *
 * 31		12|11 		4|3	0
 * +--------------+--------------+------+
 * |	tba	  |   	 tt	 | null	|
 * +--------------+--------------+------+
 *
 * tba contains the most sig. 20 bits of the tbr base address
 * tt is the trap number.
 * 
 *		Window Invalid Register (wim)
 * 31		8| 7| 6| 5| 4| 3| 2| 1|  0
 * +-------------+--+--+--+--+--+--+--+--+
 * |   res.      |w7|w6|w5|w4|w3|w2|w1|w0|
 * +-------------+--+--+--+--+--+--+--+--+
 */

