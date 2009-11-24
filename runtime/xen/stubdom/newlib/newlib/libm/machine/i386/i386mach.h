/*  This file was based on the modified setjmp.S performed by
 *  Joel Sherill (joel@OARcorp.com) which specified the use
 *  of the __USER_LABEL_PREFIX__ and __REGISTER_PREFIX__ macros.
 **
 ** This file is distributed WITHOUT ANY WARRANTY; without even the implied
 ** warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

/* These are predefined by new versions of GNU cpp.  */
 
#ifndef __USER_LABEL_PREFIX__
#define __USER_LABEL_PREFIX__ _
#endif

#define __REG_PREFIX__ %
 
/* ANSI concatenation macros.  */
 
#define CONCAT1(a, b) CONCAT2(a, b)
#define CONCAT2(a, b) a##b
 
/* Use the right prefix for global labels.  */
 
#define SYM(x) CONCAT1(__USER_LABEL_PREFIX__, x)
 
/* Use the right prefix for registers.  */
 
#define REG(x) CONCAT1(__REG_PREFIX__, x)
 
#define eax %eax
#define ebx %ebx
#define ecx %ecx
#define edx %edx
#define esi %esi
#define edi %edi
#define ebp %ebp
#define esp %esp

#define st0 %st
#define st1 %st(1)
#define st2 %st(2)
#define st3 %st(3)
#define st4 %st(4)
#define st5 %st(5)
#define st6 %st(6)
#define st7 %st(7)

#define ax %ax
#define bx %bx
#define cx %cx
#define dx %dx

#define ah %ah
#define bh %bh
#define ch %ch
#define dh %dh

#define al %al
#define bl %bl
#define cl %cl
#define dl %dl

#define mm1 %mm1
#define mm2 %mm2
#define mm3 %mm3
#define mm4 %mm4
#define mm5 %mm5
#define mm6 %mm6
#define mm7 %mm7

#ifdef _I386MACH_NEED_SOTYPE_FUNCTION
#define SOTYPE_FUNCTION(sym) .type SYM(sym),@function
#else
#define SOTYPE_FUNCTION(sym)
#endif

#ifdef _I386MACH_ALLOW_HW_INTERRUPTS
#define        __CLI
#define        __STI
#else
#define __CLI  cli
#define __STI  sti
#endif
