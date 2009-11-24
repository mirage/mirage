#include <mini-os/os.h>
#include <mini-os/x86/arch_limits.h>
#include <xen/features.h>

.section __xen_guest
	.ascii	"GUEST_OS=Mini-OS"
	.ascii	",XEN_VER=xen-3.0"
	.ascii	",VIRT_BASE=0x0" /* &_text from minios_x86_64.lds */
	.ascii	",ELF_PADDR_OFFSET=0x0"
	.ascii	",HYPERCALL_PAGE=0x2"
	.ascii	",LOADER=generic"
	.byte	0
.text

#define ENTRY(X) .globl X ; X :
.globl _start, shared_info, hypercall_page


_start:
        cld
        movq stack_start(%rip),%rsp
        andq $(~(__STACK_SIZE-1)), %rsp
        movq %rsi,%rdi
        call start_kernel

stack_start:
        .quad stack+(2*__STACK_SIZE)

        /* Unpleasant -- the PTE that maps this page is actually overwritten */
        /* to map the real shared-info page! :-)                             */
        .org 0x1000
shared_info:
        .org 0x2000

hypercall_page:
        .org 0x3000


/* Offsets into shared_info_t. */                
#define evtchn_upcall_pending		/* 0 */
#define evtchn_upcall_mask		1

NMI_MASK = 0x80000000

#define RDI 112
#define ORIG_RAX 120       /* + error_code */ 
#define EFLAGS 144

.macro RESTORE_ALL
	movq (%rsp),%r11
	movq 1*8(%rsp),%r10
	movq 2*8(%rsp),%r9
	movq 3*8(%rsp),%r8
	movq 4*8(%rsp),%rax
	movq 5*8(%rsp),%rcx
	movq 6*8(%rsp),%rdx
	movq 7*8(%rsp),%rsi
	movq 8*8(%rsp),%rdi
	addq $9*8+8,%rsp
.endm	


.macro HYPERVISOR_IRET flag
	testl $NMI_MASK,2*8(%rsp)
	jnz   2f

	testb $1,(xen_features+XENFEAT_supervisor_mode_kernel)
	jnz   1f

	/* Direct iret to kernel space. Correct CS and SS. */
	orb   $3,1*8(%rsp)
	orb   $3,4*8(%rsp)
1:	iretq

2:	/* Slow iret via hypervisor. */
	andl  $~NMI_MASK, 16(%rsp)
	pushq $\flag
	jmp  hypercall_page + (__HYPERVISOR_iret * 32)
.endm

/*
 * Exception entry point. This expects an error code/orig_rax on the stack
 * and the exception handler in %rax.	
 */ 		  				
ENTRY(error_entry)
	/* rdi slot contains rax, oldrax contains error code */
	cld	
	subq  $14*8,%rsp
	movq %rsi,13*8(%rsp)
	movq 14*8(%rsp),%rsi	/* load rax from rdi slot */
	movq %rdx,12*8(%rsp)
	movq %rcx,11*8(%rsp)
	movq %rsi,10*8(%rsp)	/* store rax */ 
	movq %r8, 9*8(%rsp)
	movq %r9, 8*8(%rsp)
	movq %r10,7*8(%rsp)
	movq %r11,6*8(%rsp)
	movq %rbx,5*8(%rsp) 
	movq %rbp,4*8(%rsp) 
	movq %r12,3*8(%rsp) 
	movq %r13,2*8(%rsp) 
	movq %r14,1*8(%rsp) 
	movq %r15,(%rsp) 

error_call_handler:
	movq %rdi, RDI(%rsp)            
	movq %rsp,%rdi
	movq ORIG_RAX(%rsp),%rsi	# get error code 
	movq $-1,ORIG_RAX(%rsp)
	call *%rax
	jmp error_exit

.macro zeroentry sym
    movq (%rsp),%rcx
    movq 8(%rsp),%r11
    addq $0x10,%rsp /* skip rcx and r11 */
	pushq $0	/* push error code/oldrax */ 
	pushq %rax	/* push real oldrax to the rdi slot */ 
	leaq  \sym(%rip),%rax
	jmp error_entry
.endm	

.macro errorentry sym
        movq (%rsp),%rcx
        movq 8(%rsp),%r11
        addq $0x10,%rsp /* rsp points to the error code */
	pushq %rax
	leaq  \sym(%rip),%rax
	jmp error_entry
.endm

#define XEN_GET_VCPU_INFO(reg)	movq HYPERVISOR_shared_info,reg
#define XEN_PUT_VCPU_INFO(reg)
#define XEN_PUT_VCPU_INFO_fixup
#define XEN_LOCKED_BLOCK_EVENTS(reg)	movb $1,evtchn_upcall_mask(reg)
#define XEN_LOCKED_UNBLOCK_EVENTS(reg)	movb $0,evtchn_upcall_mask(reg)
#define XEN_TEST_PENDING(reg)	testb $0xFF,evtchn_upcall_pending(reg)

#define XEN_BLOCK_EVENTS(reg)	XEN_GET_VCPU_INFO(reg)			; \
                    			XEN_LOCKED_BLOCK_EVENTS(reg)	; \
    				            XEN_PUT_VCPU_INFO(reg)

#define XEN_UNBLOCK_EVENTS(reg)	XEN_GET_VCPU_INFO(reg)			; \
                				XEN_LOCKED_UNBLOCK_EVENTS(reg)	; \
    			            	XEN_PUT_VCPU_INFO(reg)



ENTRY(hypervisor_callback)
    zeroentry hypervisor_callback2

ENTRY(hypervisor_callback2)
        movq %rdi, %rsp 
11:     movq %gs:8,%rax
        incl %gs:0
        cmovzq %rax,%rsp
        pushq %rdi
        call do_hypervisor_callback 
        popq %rsp
        decl %gs:0
        jmp error_exit

restore_all_enable_events:  
	XEN_UNBLOCK_EVENTS(%rsi)        # %rsi is already set up...

scrit:	/**** START OF CRITICAL REGION ****/
	XEN_TEST_PENDING(%rsi)
	jnz  14f			# process more events if necessary...
	XEN_PUT_VCPU_INFO(%rsi)
        RESTORE_ALL
        HYPERVISOR_IRET 0
        
14:	XEN_LOCKED_BLOCK_EVENTS(%rsi)
	XEN_PUT_VCPU_INFO(%rsi)
	subq $6*8,%rsp
	movq %rbx,5*8(%rsp) 
	movq %rbp,4*8(%rsp) 
	movq %r12,3*8(%rsp) 
	movq %r13,2*8(%rsp) 
	movq %r14,1*8(%rsp) 
	movq %r15,(%rsp) 
        movq %rsp,%rdi                  # set the argument again
	jmp  11b
ecrit:  /**** END OF CRITICAL REGION ****/


retint_kernel:
retint_restore_args:
	movl EFLAGS-6*8(%rsp), %eax
	shr $9, %eax			# EAX[0] == IRET_EFLAGS.IF
	XEN_GET_VCPU_INFO(%rsi)
	andb evtchn_upcall_mask(%rsi),%al
	andb $1,%al			# EAX[0] == IRET_EFLAGS.IF & event_mask
	jnz restore_all_enable_events	#        != 0 => enable event delivery
	XEN_PUT_VCPU_INFO(%rsi)
		
	RESTORE_ALL
	HYPERVISOR_IRET 0


error_exit:		
	movq (%rsp),%r15
	movq 1*8(%rsp),%r14
	movq 2*8(%rsp),%r13
	movq 3*8(%rsp),%r12
	movq 4*8(%rsp),%rbp
	movq 5*8(%rsp),%rbx
	addq $6*8,%rsp
	XEN_BLOCK_EVENTS(%rsi)		
	jmp retint_kernel



ENTRY(failsafe_callback)
        popq  %rcx
        popq  %r11
        iretq


ENTRY(coprocessor_error)
        zeroentry do_coprocessor_error


ENTRY(simd_coprocessor_error)
        zeroentry do_simd_coprocessor_error


ENTRY(device_not_available)
        zeroentry do_device_not_available


ENTRY(debug)
        zeroentry do_debug


ENTRY(int3)
        zeroentry do_int3

ENTRY(overflow)
        zeroentry do_overflow


ENTRY(bounds)
        zeroentry do_bounds
    
    
ENTRY(invalid_op)
        zeroentry do_invalid_op


ENTRY(coprocessor_segment_overrun)
        zeroentry do_coprocessor_segment_overrun


ENTRY(invalid_TSS)
        errorentry do_invalid_TSS


ENTRY(segment_not_present)
        errorentry do_segment_not_present


/* runs on exception stack */
ENTRY(stack_segment)
        errorentry do_stack_segment
                    

ENTRY(general_protection)
        errorentry do_general_protection


ENTRY(alignment_check)
        errorentry do_alignment_check


ENTRY(divide_error)
        zeroentry do_divide_error


ENTRY(spurious_interrupt_bug)
        zeroentry do_spurious_interrupt_bug
            

ENTRY(page_fault)
        errorentry do_page_fault





ENTRY(thread_starter)
        popq %rdi
        popq %rbx
        pushq $0
        xorq %rbp,%rbp
        call *%rbx
        call exit_thread 
        

ENTRY(__arch_switch_threads)
	pushq %rbp
	pushq %rbx
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	movq %rsp, (%rdi)		/* save ESP */
	movq (%rsi), %rsp		/* restore ESP */
	movq $1f, 8(%rdi)		/* save EIP */
	pushq 8(%rsi)			/* restore EIP */
	ret
1:
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbx
	popq %rbp
	ret
