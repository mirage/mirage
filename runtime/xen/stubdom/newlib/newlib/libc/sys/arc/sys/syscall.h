/* ARC system call interface */

/* A special version of the flag insn is used to distinguish syscalls from
   breakpoints (a breakpoint might be set at the same place).

   The upper 23 bits of the argument to a flag insn are not currently used.
   By convention, bit 31 is one to indicate this is a specially coded operand.
   The next 15 bits (bits 30-16) can be used for software purposes.
   The format isn't documented yet, so the pattern we use here may change.  */

#define SYSCALL_MARKER 0x80010000
#define SYSCALL_MAGIC 0x61082300

/* Perform a system call.

   If ERR is 0, it succeeded.  Otherwise it is a positive value for errno.  */

#define SYSCALL(op, rc, err, r0, r1, r2) \
asm volatile ( "\
	      mov r0,%2\n\t \
	      mov r1,%3\n\t \
	      mov r2,%4\n\t \
	      mov r3,%5\n\t \
	      mov r4,%6\n\t \
	      flag %7\n\t \
	      nop\n\t \
	      nop\n\t \
	      nop\n\t \
	      mov %0,r0\n\t \
	      mov %1,r1" \
	      : "=r" (rc), "=r" (err) \
	      : "i" (SYSCALL_MAGIC), "r" (op), "r" (r0), "r" (r1), "r" (r2), \
	        "i" (1 | SYSCALL_MARKER) \
	      : "r0", "r1", "r2", "r3", "r4");

#define	SYS_exit	1
#define	SYS_open	2
#define	SYS_close	3
#define	SYS_read	4
#define	SYS_write	5
#define	SYS_lseek	6
#define	SYS_link	7
#define	SYS_unlink	8
#define	SYS_chdir	9
#define	SYS_chmod	10
#define SYS_stat	11
#define SYS_fstat	12
#define SYS_access	13
#define	SYS_getpid	14
#define SYS_kill	15
#define SYS_time	16

#define SYS_MAX		17
