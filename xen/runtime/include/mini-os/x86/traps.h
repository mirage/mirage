/* 
 ****************************************************************************
 * (C) 2005 - Grzegorz Milos - Intel Reseach Cambridge
 ****************************************************************************
 *
 *        File: traps.h
 *      Author: Grzegorz Milos (gm281@cam.ac.uk)
 *              
 *        Date: Jun 2005
 * 
 * Environment: Xen Minimal OS
 * Description: Deals with traps
 *
 ****************************************************************************
 */

#ifndef _TRAPS_H_
#define _TRAPS_H_

struct pt_regs {
	unsigned long r15;
	unsigned long r14;
	unsigned long r13;
	unsigned long r12;
	unsigned long rbp;
	unsigned long rbx;
/* arguments: non interrupts/non tracing syscalls only save upto here*/
 	unsigned long r11;
	unsigned long r10;	
	unsigned long r9;
	unsigned long r8;
	unsigned long rax;
	unsigned long rcx;
	unsigned long rdx;
	unsigned long rsi;
	unsigned long rdi;
	unsigned long orig_rax;
/* end of arguments */ 	
/* cpu exception frame or undefined */
	unsigned long rip;
	unsigned long cs;
	unsigned long eflags; 
	unsigned long rsp; 
	unsigned long ss;
/* top of stack page */ 
};


void dump_regs(struct pt_regs *regs);
void stack_walk(void);

#define TRAP_PF_PROT   0x1
#define TRAP_PF_WRITE  0x2
#define TRAP_PF_USER   0x4

#endif /* _TRAPS_H_ */
