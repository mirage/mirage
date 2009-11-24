/*
 * Copyright (c) 1995, 1996, 1998 Cygnus Support
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

#include "asm.h"
#include "slite.h"

	.text
	.align 4

/* 
 *  The trap table has to be the first code in a boot PROM.  But because
 *  the Memory Configuration comes up thinking we only have 4K of PROM, we
 *  cannot have a full trap table and still have room left over to 
 *  reprogram the Memory Configuration register correctly.  This file
 *  uses an abbreviated trap which has every entry which might be used
 *  before RTEMS installs its own trap table.
 */
	.globl	_trap_table
_trap_table:
  TRAP(SYM(ercinit));				! 00 reset trap 
  BAD_TRAP;                                     ! 01 instruction access exception
  TRAP(SYM(no_fpu));				! 02 illegal instruction
  BAD_TRAP;                                     ! 03 privileged instruction
  BAD_TRAP;                                     ! 04 fp disabled
  TRAP(SYM(win_overflow));			! 05 window overflow
  TRAP(SYM(win_underflow));			! 06 window underflow
  BAD_TRAP;                                     ! 07 memory address not aligned
  BAD_TRAP;                                     ! 08 fp exception
  BAD_TRAP;                                     ! 09 data access exception
  BAD_TRAP;					! 0A tag overflow

  /* Trap levels from 0B to 0x10 are not defined (used for MEC init) */

SYM(ercinit):
  sethi         %hi(_ERC32_MEC), %g1		! 0B
  sethi         %hi(0x001C1000), %g2
  or            %g1,%lo(0x001C1000),%g1
  st            %g2, [%g1 + 0x10]
  st            %g0, [%g1 + 0x18]			! 0C
  nop
  nop
  nop

  TRAP(SYM(hard_reset));			! 0D undefined
  BAD_TRAP;                                     ! 0E undefined
  BAD_TRAP;                                     ! 0F undefined
  BAD_TRAP;                                     ! 10 undefined

  /* 
   *  ERC32 defined traps
   */

  BAD_TRAP;                                     ! 11 masked errors
  BAD_TRAP;                                     ! 12 external 1
  BAD_TRAP;                                     ! 13 external 2
  BAD_TRAP;                                     ! 14 UART A RX/TX
  BAD_TRAP;                                     ! 15 UART B RX/TX
  BAD_TRAP;                                     ! 16 correctable memory error
  BAD_TRAP;                                     ! 17 UART error
  BAD_TRAP;                                     ! 18 DMA access error
  BAD_TRAP;                                     ! 19 DMA timeout
  BAD_TRAP;                                     ! 1A external 3
  BAD_TRAP;                                     ! 1B external 4
  BAD_TRAP;                                     ! 1C general purpose timer
  BAD_TRAP;                                     ! 1D real time clock
  BAD_TRAP;                                     ! 1E external 5
  BAD_TRAP;                                     ! 1F watchdog timeout


  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 20 - 23 undefined
  BAD_TRAP;                                     ! 24 cp_disabled
            BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 25 - 27 undefined
  BAD_TRAP;                                     ! 28 cp_exception
            BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 29 - 2B undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 2C - 2F undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 30 - 33 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 34 - 37 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 38 - 3B undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 3C - 3F undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 40 - 43 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 44 - 47 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 48 - 4B undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 4C - 4F undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 50 - 53 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 54 - 57 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 58 - 5B undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 5C - 5F undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 60 - 63 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 64 - 67 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 68 - 6B undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 6C - 6F undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 70 - 73 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 74 - 77 undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 78 - 7B undefined
  BAD_TRAP; BAD_TRAP; BAD_TRAP; BAD_TRAP;       ! 7C - 7F undefined

  /* 
   *  Software traps
   *
   *  NOTE: At the risk of being redundant... this is not a full
   *        table.  The setjmp on the SPARC requires a window flush trap
   *        handler and RTEMS will preserve the entries that were
   *        installed before.
   */

  SOFT_TRAP;					! 80
#if 0
  SOFT_TRAP;					! 81
#else
  TRAP(SYM(trap_low))				! 81
#endif
  SOFT_TRAP;					! 82
  TRAP(SYM(win_flush));				! 83 flush windows SW trap
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 84 - 87
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 88 - 8B
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 8C - 8F
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 90 - 93
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 94 - 97
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 98 - 9B
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! 9C - 9F
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! A0 - A3
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! A4 - A7
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! A8 - AB
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! AC - AF
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! B0 - B3
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! B4 - B7
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! B8 - BB
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! BC - BF
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! C0 - C3
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! C4 - C7
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! C8 - CB
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! CC - CF
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! D0 - D3
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! D4 - D7
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! D8 - DB
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! DC - DF
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! E0 - E3
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! E4 - E7
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! E8 - EB
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! EC - EF
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! F0 - F3
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! F4 - F7
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! F8 - FB 
  SOFT_TRAP; SOFT_TRAP; SOFT_TRAP; SOFT_TRAP;   ! FC - FF

/*
 * Startup code for standalone system. Wash IU and FPU (if present)
 * registers. The registers have to be written to initiate the parity
 * bits.
 */
	.globl	SYM(hard_reset)
SYM(hard_reset):

        sethi	%hi(0x01FE0),%o0
        or	%o0,%lo(0x01FE0),%o0
        mov     %o0, %psr		! Set valid PSR
        nop

        mov     %g0, %wim		! Set window invalid mask register
        mov     %g0, %y			! Init Y-register
        nop
        sethi   %hi(SYM(hard_reset)), %g1

        mov     %g1, %tbr		! Set TBR
        sethi	%hi(SP_INIT),%sp
        or      %g0, 1, %o0
        ld      [%g0], %f0		! Check if FPU is present

        tst     %o0
        bz      fixiu
        nop
        ba      fixfpu

! FPU disabled trap address

        clr     %i0
        jmpl    %l2, %g0
        rett    %l2 + 4
        nop
        

! Wash register files (fix for 90C601E & 90C602E)

fixfpu:

        ld      [%g0], %f0
        ld      [%g0], %f1
        ld      [%g0], %f2
        ld      [%g0], %f3
        ld      [%g0], %f4
        ld      [%g0], %f5
        ld      [%g0], %f6
        ld      [%g0], %f7
        ld      [%g0], %f8
        ld      [%g0], %f9
        ld      [%g0], %f10
        ld      [%g0], %f11
        ld      [%g0], %f12
        ld      [%g0], %f13
        ld      [%g0], %f14
        ld      [%g0], %f15
        ld      [%g0], %f16
        ld      [%g0], %f17
        ld      [%g0], %f18
        ld      [%g0], %f19
        ld      [%g0], %f20
        ld      [%g0], %f21
        ld      [%g0], %f22
        ld      [%g0], %f23
        ld      [%g0], %f24
        ld      [%g0], %f25
        ld      [%g0], %f26
        ld      [%g0], %f27
        ld      [%g0], %f28
        ld      [%g0], %f29
        ld      [%g0], %f30
        ld      [%g0], %f31

fixiu:
        clr     %g1
        clr     %g2
        clr     %g3
        clr     %g4
        clr     %g5
        clr     %g6
        clr     %g7
        set     8,%g1
wl0:
        clr     %i0
        clr     %i1
        clr     %i2
        clr     %i3
        clr     %i4
        clr     %i5
        clr     %i6
        clr     %i7
        clr     %l0
        clr     %l1
        clr     %l2
        clr     %l3
        clr     %l4
        clr     %l5
        clr     %l6
        clr     %l7
        save
        subcc   %g1, 1, %g1
        bne     wl0
        nop

!
! Start the real-time clock with a tick of 150 clocks
!

rtc:

        set     0x1f80000, %l0		! MEC register base
        set     149, %l1
        st      %l1, [%l0 + 0x84]	! RTC scaler = 149
        set     0x0d00, %l1
        st      %l1, [%l0 + 0x98]	! Start RTC

        st      %g0, [%l0 + 0x64]	! Disable watchdog for now
        ld      [%l0], %g1
        or      %g1, 1, %g1
        st      %g1, [%l0]		! Enable power-down mode

_init:
	set     PSR_INIT, %g1		! Initialize psr
        mov     %g1, %psr
        set     WIM_INIT, %g1		! Initialize WIM
        mov     %g1, %wim               
        set     _trap_table, %g1	! Initialize TBR
        mov     %g1, %tbr
        nop;nop;nop                     

        set     PSR_INIT, %g1
        wr      %g1, 0x20, %psr		! enable traps
        nop; nop; nop;

	call	SYM(start)
	nop
	
/*
 * Register window overflow handler.  Come here when save would move us
 * into the invalid window.  This routine runs with traps disabled, and
 * must be careful not to touch the condition codes, as PSR is never
 * restored.
 *
 * We are called with %l0 = wim, %l1 = pc, %l2 = npc
 */
	.globl SYM(win_overflow)
SYM(win_overflow):
        mov     %g1, %l3		! Save g1, we use it to hold the wim
        srl     %l0, 1, %g1		! Rotate wim right
        sll     %l0, NUMBER_OF_REGISTER_WINDOWS - 1, %l0
        or      %l0, %g1, %g1

        save    %g0, %g0, %g0		! Slip into next window
        mov     %g1, %wim		! Install the new wim
	nop
	nop
	nop

        std     %l0, [%sp + 0 * 4]	! save L & I registers
        std     %l2, [%sp + 2 * 4]
        std     %l4, [%sp + 4 * 4]
        std     %l6, [%sp + 6 * 4]

        std     %i0, [%sp + 8 * 4]
        std     %i2, [%sp + 10 * 4]
        std     %i4, [%sp + 12 * 4]
        std     %i6, [%sp + 14 * 4]

        restore                         ! Go back to trap window.
        mov     %l3, %g1		! Restore %g1

        jmpl    %l1, %g0
        rett    %l2

/*
 * Register window underflow handler.  Come here when restore would move us
 * into the invalid window.  This routine runs with traps disabled, and
 * must be careful not to touch the condition codes, as PSR is never
 * restored.
 *
 * We are called with %l0 = wim, %l1 = pc, %l2 = npc
 */
	.globl SYM(win_underflow)
SYM(win_underflow):
        sll     %l0, 1, %l3		! Rotate wim left
        srl     %l0, NUMBER_OF_REGISTER_WINDOWS - 1, %l0
        or      %l0, %l3, %l0

        mov     %l0, %wim		! Install the new wim

        restore                         ! Users window
        restore                         ! His callers window

        ldd     [%sp + 0 * 4], %l0	! restore L & I registers
        ldd     [%sp + 2 * 4], %l2
        ldd     [%sp + 4 * 4], %l4
        ldd     [%sp + 6 * 4], %l6

        ldd     [%sp + 8 * 4], %i0
        ldd     [%sp + 10 * 4], %i2
        ldd     [%sp + 12 * 4], %i4
        ldd     [%sp + 14 * 4], %i6

        save    %g0, %g0, %g0		! Back to trap window
        save    %g0, %g0, %g0

        jmpl    %l1, %g0
        rett    %l2

/*
 * Register window flush handler, triggered by a "ta 3" instruction.
 * We are called with %l0 = wim, %l1 = pc, %l2 = npc
 */
	.globl	SYM(win_flush)
SYM(win_flush):
	mov	%psr, %l0
	or	%l0,0xf00,%l3		! Disable interrupts
	mov	%l3,%psr
	nop
	nop
	nop
	mov	%wim, %l3

	srl	%l3, %l0, %l4		! wim >> cwp
	cmp	%l4, 1
	bne	flush_window_fine	! Branch if not in the invalid window
	nop

/* Handle window overflow. We can't trap here. */

	mov	%g1, %l4		! Save g1, we use it to hold the wim
	srl	%l3, 1, %g1		! Rotate wim right
        sll     %l3, NUMBER_OF_REGISTER_WINDOWS - 1, %l3
        or      %l3, %g1, %g1
	mov	%g0, %wim		! Clear wim so that subsequent save
	nop				!  wont trap
	nop
	nop
	save	%g0, %g0, %g0		! Slip into next window
	mov	%g1, %wim		! Install the new wim

	std	%l0, [%sp + 0 * 4]	! save L & I registers
	std	%l2, [%sp + 2 * 4]
	std	%l4, [%sp + 4 * 4]
	std	%l6, [%sp + 6 * 4]

	std	%i0, [%sp + 8 * 4]
	std	%i2, [%sp + 10 * 4]
	std	%i4, [%sp + 12 * 4]
	std	%i6, [%sp + 14 * 4]

	restore				! Go back to trap window.
	mov	%l4, %g1		! Restore %g1

flush_window_fine:
	mov	%psr,%l5		! enable traps
	or	%l5,0x20,%l5
	mov	%l5, %psr
	nop
	nop
	nop

	set	save_buf,%l5
	st	%l2,[%l5]

	! The stack pointer currently contains a bogus value [when a trap
	! occurs CWP is decremented and points to an unused window].
	! Give it something useful before we flush every window.
	! This does what a "save %sp,-64,$sp" would, except that CWP has
	! already been decremented.
	add	%fp, -64, %sp

	save %sp, -64, %sp		! Flush user register window to stack
	save %sp, -64, %sp
	save %sp, -64, %sp
	save %sp, -64, %sp
	save %sp, -64, %sp
	save %sp, -64, %sp
	save %sp, -64, %sp
	save %sp, -64, %sp
	restore
	restore
	restore
	restore
	restore
	restore
	restore
	restore

	restore				! Make sure we have a valid window
	save %g0, %g0, %g0

	set	save_buf, %l2		! Get our return address back
	ld	[%l2],%l2

	mov	%psr,%l5		! disable traps for rett
	andn	%l5,0x20,%l5
	mov	%l5,%psr
	nop
	nop
	nop

	jmpl	%l2, %g0
	rett	%l2+4

/*
 * Read the TBR.
 */
       .globl SYM(rdtbr)
SYM(rdtbr):
        mov     %tbr, %o0
	nop
        retl
	nop

/*
 * Read the psr
 */
	.globl	SYM(read_psr)
SYM(read_psr):
	mov	%psr, %o0
	nop
        retl
	nop

/*
 * Write the PSR.
 */

	.globl	SYM(write_psr)
SYM(write_psr):
	mov %i0, %psr
	nop
	nop
	nop
	retl
	nop
/*
 * Come here when no fpu exists.  This just skips the offending
 * instruction.
 */
	.globl	SYM(no_fpu)
SYM(no_fpu):
        jmpl %l2, %g0
        rett %l2+4

        .globl SYM(fltr_proto)
        .align 4
SYM(fltr_proto):                    ! First level trap routine prototype
        sethi 0, %l0
        jmpl 0+%l0, %g0
        nop
        nop

/*
 * Trap handler for memory errors.  This just sets mem_err to be
 * non-zero.  It assumes that l1 is non-zero.  This should be safe,
 * as it is doubtful that 0 would ever contain code that could mem
 * fault.  This routine will skip past the faulting instruction after
 * setting mem_err.
 */
	.globl	SYM(fltr_set_mem_err)
SYM(fltr_set_mem_err):
	sethi	%hi(SYM(mem_err)), %l0
	st	%l1, [%l0 + %lo(SYM(mem_err))]
	jmpl	%l2, %g0
	rett	%l2+4

        .data
        .align  4
	.ascii	"DaTa"
	.long	SYM(sdata)
in_trap_handler:
	.word	0
save_buf:	
	.word	0	/* place to save %g1 */
	.word	0	/* place to save %g2 */

	.text
	.align 4

/*
 * This function is called when any SPARC trap (except window overflow
 * or underflow) occurs.  It makes sure that the invalid register
 * window is still available before jumping into C code.  It will also
 * restore the world if you return from handle_exception.
 */
	.globl SYM(trap_low)
SYM(trap_low):
	mov	%psr, %l0
	mov	%wim, %l3

	srl	%l3, %l0, %l4		! wim >> cwp
	cmp	%l4, 1
	bne	window_fine		! Branch if not in the invalid window
	nop

        mov     %g1, %l4		! Save g1, we use it to hold the wim
        srl     %l3, 1, %g1		! Rotate wim right
        sll     %l3, 8-1, %l5
        or      %l5, %g1, %g1
		
	save	%g0, %g0, %g0		! Slip into next window
	mov	%g1, %wim		! Install the new wim

	std	%l0, [%sp + 0 * 4]	! save L & I registers
	std	%l2, [%sp + 2 * 4]
	std	%l4, [%sp + 4 * 4]
	std	%l6, [%sp + 6 * 4]

	std	%i0, [%sp + 8 * 4]
	std	%i2, [%sp + 10 * 4]
	std	%i4, [%sp + 12 * 4]
	std	%i6, [%sp + 14 * 4]

	restore				! Go back to trap window.
	mov	%l4, %g1		! Restore g1

window_fine:
	sethi	%hi(in_trap_handler), %l4
	ld	[%lo(in_trap_handler) + %l4], %l5
	tst	%l5
	bg	recursive_trap
	inc	%l5

	/* use the stack we set in the linker script */
	sethi	%hi(__trap_stack), %l6
        or      %l6,%lo(__trap_stack),%l6
	mov	%l6, %sp		! set the stack pointer

recursive_trap:
	st	%l5, [%lo(in_trap_handler) + %l4]

	sub	%sp,(16+1+6+1+72)*4,%sp	! Make room for input & locals
 					! + hidden arg + arg spill
					! + doubleword alignment
					! + registers[72] local var

	std	%g0, [%sp + (24 + 0) * 4] ! registers[Gx]
	std	%g2, [%sp + (24 + 2) * 4]
	std	%g4, [%sp + (24 + 4) * 4]
	std	%g6, [%sp + (24 + 6) * 4]

	std	%i0, [%sp + (24 + 8) * 4] ! registers[Ox]
	std	%i2, [%sp + (24 + 10) * 4]
	std	%i4, [%sp + (24 + 12) * 4]
	std	%i6, [%sp + (24 + 14) * 4]
					 ! F0->F31 not implemented
	mov	%y, %l4
	mov	%tbr, %l5
	st	%l4, [%sp + (24 + 64) * 4] ! Y
	st	%l0, [%sp + (24 + 65) * 4] ! PSR
	st	%l3, [%sp + (24 + 66) * 4] ! WIM
	st	%l5, [%sp + (24 + 67) * 4] ! TBR
	st	%l1, [%sp + (24 + 68) * 4] ! PC
	st	%l2, [%sp + (24 + 69) * 4] ! NPC
					 ! CPSR and FPSR not implemented

	or	%l0, 0xf20, %l4
	mov	%l4, %psr		! Turn on traps, disable interrupts

	call	SYM(handle_exception)
	add	%sp, 24 * 4, %o0	! Pass address of registers

/* Reload all of the registers that aren't on the stack */

	ld	[%sp + (24 + 1) * 4], %g1  ! registers[Gx]
	ldd	[%sp + (24 + 2) * 4], %g2
	ldd	[%sp + (24 + 4) * 4], %g4
	ldd	[%sp + (24 + 6) * 4], %g6

	ldd	[%sp + (24 + 8) * 4], %i0  ! registers[Ox]
	ldd	[%sp + (24 + 10) * 4], %i2
	ldd	[%sp + (24 + 12) * 4], %i4
	ldd	[%sp + (24 + 14) * 4], %i6

	ldd	[%sp + (24 + 64) * 4], %l0 ! Y & PSR
	ldd	[%sp + (24 + 68) * 4], %l2 ! PC & NPC

	restore				! Ensure that previous window is valid
	save	%g0, %g0, %g0		!  by causing a window_underflow trap

	mov	%l0, %y
	mov	%l1, %psr		! Make sure that traps are disabled
					! for rett

	sethi	%hi(in_trap_handler), %l4
	ld	[%lo(in_trap_handler) + %l4], %l5
	dec	%l5
	st	%l5, [%lo(in_trap_handler) + %l4]

	jmpl	%l2, %g0		! Restore old PC
	rett	%l3			! Restore old nPC


