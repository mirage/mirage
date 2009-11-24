#ifndef _SYSCALL_H_
#define _SYSCALL_H_

/*
 * This file defines the minimal set of system calls needed
 * by newlib for both sunos4 and solaris2.
 *
 * WARNING: This file can be included by assembler files.
 */

/* Process control.  */
#define	SYS_exit	1
#define	SYS_getpid	20
#define	SYS_kill	37

/* File stuff.  */
#define	SYS_read	3
#define	SYS_write	4
#define	SYS_open	5
#define	SYS_close	6
#define	SYS_lseek	19

/* Memory stuff.  */
#define	SYS_brk		17

/* Directory stuff.  */
#define	SYS_unlink	10
#define	SYS_chdir	12
#ifdef SVR4
#define SYS_stat	18
#define SYS_fstat	28
#define	SYS_lstat	88
#else
#define	SYS_stat	38
#define	SYS_fstat	62
#define	SYS_lstat	40
#endif

#endif /* _SYSCALL_H_ */
