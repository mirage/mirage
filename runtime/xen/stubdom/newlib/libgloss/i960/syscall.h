/* mon960 syscall.h file.  This is used only by the simulator.  This matches
   the syscall numbers used by mon-syscalls.S, but is otherwise a copy of
   the libgloss/syscall.h file.  */
/* ??? This file should be used by mon-syscalls.S to avoid maintenance
   problems.  */

#ifndef LIBGLOSS_SYSCALL_H
#define LIBGLOSS_SYSCALL_H

/* Note: This file may be included by assembler source.  */

/* These should be as small as possible to allow a port to use a trap type
   instruction, which the system call # as the trap (the d10v for instance
   supports traps 0..31).  An alternative would be to define one trap for doing
   system calls, and put the system call number in a register that is not used
   for the normal calling sequence (so that you don't have to shift down the
   arguments to add the system call number).  Obviously, if these system call
   numbers are ever changed, all of the simulators and potentially user code
   will need to be updated.  */

/* There is no current need for the following: SYS_execv, SYS_creat, SYS_wait,
   etc. etc.  Don't add them.  */

/* These are required by the ANSI C part of newlib (excluding system() of
   course).  */
#define	SYS_exit	257
#define	SYS_open	230
#define	SYS_close	234
#define	SYS_read	231
#define	SYS_write	232
#define	SYS_lseek	233

/* ??? The following system calls apparently aren't support by mon960.  */
#define	SYS_unlink	7
#define	SYS_getpid	8
#define	SYS_kill	9
#define SYS_fstat       10
/*#define SYS_sbrk	11 - not currently a system call, but reserved.  */

/* ARGV support.  */
#define SYS_argvlen	12
#define SYS_argv	13

/* These are extras added for one reason or another.  */
#define SYS_chdir	14
#define SYS_stat	15
#define SYS_chmod 	16
#define SYS_utime 	17
#define SYS_time 	18

#endif
