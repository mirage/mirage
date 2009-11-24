#ifndef _X86_DEBUGREG_H
#define _X86_DEBUGREG_H


/* Indicate the register numbers for a number of the specific
   debug registers.  Registers 0-3 contain the addresses we wish to trap on */

#define DR_FIRSTADDR 0
#define DR_LASTADDR  3
#define DR_STATUS    6
#define DR_CONTROL   7

/* Define a few things for the status register.  We can use this to determine
   which debugging register was responsible for the trap.  The other bits
   are either reserved or not of interest to us. */

#define DR_TRAP0        (0x1)           /* db0 */
#define DR_TRAP1        (0x2)           /* db1 */
#define DR_TRAP2        (0x4)           /* db2 */
#define DR_TRAP3        (0x8)           /* db3 */
#define DR_STEP         (0x4000)        /* single-step */
#define DR_SWITCH       (0x8000)        /* task switch */

/* Now define a bunch of things for manipulating the control register.
   The top two bytes of the control register consist of 4 fields of 4
   bits - each field corresponds to one of the four debug registers,
   and indicates what types of access we trap on, and how large the data
   field is that we are looking at */

#define DR_CONTROL_SHIFT 16 /* Skip this many bits in ctl register */
#define DR_CONTROL_SIZE   4 /* 4 control bits per register */

#define DR_RW_EXECUTE (0x0) /* Settings for the access types to trap on */
#define DR_RW_WRITE   (0x1)
#define DR_IO         (0x2)
#define DR_RW_READ    (0x3)

#define DR_LEN_1      (0x0) /* Settings for data length to trap on */
#define DR_LEN_2      (0x4)
#define DR_LEN_4      (0xC)
#define DR_LEN_8      (0x8)

/* The low byte to the control register determine which registers are
   enabled.  There are 4 fields of two bits.  One bit is "local", meaning
   that the processor will reset the bit after a task switch and the other
   is global meaning that we have to explicitly reset the bit. */

#define DR_LOCAL_ENABLE_SHIFT  0   /* Extra shift to the local enable bit */
#define DR_GLOBAL_ENABLE_SHIFT 1   /* Extra shift to the global enable bit */
#define DR_ENABLE_SIZE         2   /* 2 enable bits per register */

#define DR_LOCAL_ENABLE_MASK (0x55)  /* Set  local bits for all 4 regs */
#define DR_GLOBAL_ENABLE_MASK (0xAA) /* Set global bits for all 4 regs */

#define DR7_ACTIVE_MASK (DR_LOCAL_ENABLE_MASK|DR_GLOBAL_ENABLE_MASK)

/* The second byte to the control register has a few special things.
   We can slow the instruction pipeline for instructions coming via the
   gdt or the ldt if we want to.  I am not sure why this is an advantage */

#define DR_CONTROL_RESERVED_ZERO (0x0000d800ul) /* Reserved, read as zero */
#define DR_CONTROL_RESERVED_ONE  (0x00000400ul) /* Reserved, read as one */
#define DR_LOCAL_EXACT_ENABLE    (0x00000100ul) /* Local exact enable */
#define DR_GLOBAL_EXACT_ENABLE   (0x00000200ul) /* Global exact enable */
#define DR_GENERAL_DETECT        (0x00002000ul) /* General detect enable */

#endif /* _X86_DEBUGREG_H */
