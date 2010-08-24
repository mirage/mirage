#ifndef _SYS_VM86_H
#define _SYS_VM86_H

#include <sys/cdefs.h>
#include <inttypes.h>

/*
 * I'm guessing at the VIF/VIP flag usage, but hope that this is how
 * the Pentium uses them. Linux will return from vm86 mode when both
 * VIF and VIP is set.
 *
 * On a Pentium, we could probably optimize the virtual flags directly
 * in the eflags register instead of doing it "by hand" in vflags...
 *
 * Linus
 */

#define TF_MASK		0x00000100
#define IF_MASK		0x00000200
#define IOPL_MASK	0x00003000
#define NT_MASK		0x00004000
#define VM_MASK		0x00020000
#define AC_MASK		0x00040000
#define VIF_MASK	0x00080000	/* virtual interrupt flag */
#define VIP_MASK	0x00100000	/* virtual interrupt pending */
#define ID_MASK		0x00200000

#define BIOSSEG		0x0f000

#define CPU_086		0
#define CPU_186		1
#define CPU_286		2
#define CPU_386		3
#define CPU_486		4
#define CPU_586		5

/*
 * Return values for the 'vm86()' system call
 */
#define VM86_TYPE(retval)	((retval) & 0xff)
#define VM86_ARG(retval)	((retval) >> 8)

#define VM86_SIGNAL	0	/* return due to signal */
#define VM86_UNKNOWN	1	/* unhandled GP fault - IO-instruction or similar */
#define VM86_INTx	2	/* int3/int x instruction (ARG = x) */
#define VM86_STI	3	/* sti/popf/iret instruction enabled virtual interrupts */

/*
 * Additional return values when invoking new vm86()
 */
#define VM86_PICRETURN	4	/* return due to pending PIC request */
#define VM86_TRAP	6	/* return due to DOS-debugger request */

/*
 * function codes when invoking new vm86()
 */
#define VM86_PLUS_INSTALL_CHECK	0
#define VM86_ENTER		1
#define VM86_ENTER_NO_BYPASS	2
#define	VM86_REQUEST_IRQ	3
#define VM86_FREE_IRQ		4
#define VM86_GET_IRQ_BITS	5
#define VM86_GET_AND_RESET_IRQ	6

/*
 * This is the stack-layout seen by the user space program when we have
 * done a translation of "SAVE_ALL" from vm86 mode. The real kernel layout
 * is 'kernel_vm86_regs' (see below).
 */

struct vm86_regs {
/*
 * normal regs, with special meaning for the segment descriptors..
 */
	int32_t ebx;
	int32_t ecx;
	int32_t edx;
	int32_t esi;
	int32_t edi;
	int32_t ebp;
	int32_t eax;
	int32_t __null_ds;
	int32_t __null_es;
	int32_t __null_fs;
	int32_t __null_gs;
	int32_t orig_eax;
	int32_t eip;
	uint16_t cs, __csh;
	int32_t eflags;
	int32_t esp;
	uint16_t ss, __ssh;
/*
 * these are specific to v86 mode:
 */
	uint16_t es, __esh;
	uint16_t ds, __dsh;
	uint16_t fs, __fsh;
	uint16_t gs, __gsh;
};

struct revectored_struct {
	uint32_t __map[8];			/* 256 bits */
};

struct vm86_struct {
	struct vm86_regs regs;
	uint32_t flags;
	uint32_t screen_bitmap;
	uint32_t cpu_type;
	struct revectored_struct int_revectored;
	struct revectored_struct int21_revectored;
};

/*
 * flags masks
 */
#define VM86_SCREEN_BITMAP	0x0001

struct vm86plus_info_struct {
	uint32_t force_return_for_pic:1;
	uint32_t vm86dbg_active:1;       /* for debugger */
	uint32_t vm86dbg_TFpendig:1;     /* for debugger */
	uint32_t unused:28;
	uint32_t is_vm86pus:1;	      /* for vm86 internal use */
	uint8_t vm86dbg_intxxtab[32];   /* for debugger */
};

struct vm86plus_struct {
	struct vm86_regs regs;
	uint32_t flags;
	uint32_t screen_bitmap;
	uint32_t cpu_type;
	struct revectored_struct int_revectored;
	struct revectored_struct int21_revectored;
	struct vm86plus_info_struct vm86plus;
};


__BEGIN_DECLS

/* Enter virtual 8086 mode.  */
extern int vm86 (uint32_t __subfunction,
		 struct vm86plus_struct *__info) __THROW;

__END_DECLS

#endif
