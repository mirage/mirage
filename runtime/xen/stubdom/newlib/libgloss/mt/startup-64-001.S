/*
 * $Header: /cvs/src/src/libgloss/mt/startup-64-001.S,v 1.1 2005/12/12 11:16:41 nathan Exp $
 *
 * interrupt_vectors.s -- the interrupt handler jump table. 
 *
 *
 * There are a total of 32 interrupt vector possible, however, only
 *   11 of those are currently used (the others are reserved). The
 *   order of vectors is as follows:
 *
 *     1. Boot Vector. Vector for power-on/reset.
 *     2. Software Vector. Vector for handling the SI instruction (an
 *          explicit interrupt caused by software).
 *     3. Break Vector. Vector for handling the Break instruction.
 *     4. Device 0 Vector. Service vector for device zero. 
 *     5. Device 1 Vector. Service vector for device one. 
 *     6. Device 2 Vector. Service vector for device two. 
 *     7. Device 3 Vector. Service vector for device three. 
 *     8. Device 4 Vector. Service vector for device four. 
 *     9. Device 5 Vector. Service vector for device five. 
 *    10. Device 6 Vector. Service vector for device six. 
 *    11. Device 7 Vector. Service vector for device seven. 
 *
 *   The rest of the interrupt vectors are reserved for future use.
 *
 *
 * Each jump table entry consists of the following two instructions:
 *
 *   jmp Label		; Label as appropriate
 *   nop 		; implemented as or r0,r0,r0
 *
 *   The following labels are reserved for the vectors named above,
 *   respectively:
 *
 *     _BOOTIVEC, _SOFTIVEC, _BRKIVEC, _DEV0IVEC, _DEV1IVEC, _DEV2IVEC,
 *     _DEV3IVEC, _DEV4IVEC, _DEV5IVEC, _DEV6IVEC, _DEV7IVEC
 *
 *
 *   26Sep01 (DJK) The memory map is changed and the device interrupts are
 *                   now memory-mapped.
 *
 *   10Oct01 (DJK) The memory map is finalized and the first 4K of address
 *                   space is now reserved for memory-mapped I/O devices.
 *                   (There is over 2K unused, reserved space in this area.)
 *
 *   27Jul02 (DJK) Fixed the address for the interrupt mask register. Old
 *                   documentation stated the port address as 0x140, but
 *                   the implementation uses 0x13c.
 *
 *   30Jul02 (DJK) Added support for printf. This only supports output to
 *                   stderr and stdout. Using the message box interface,
 *                   a (newly defined) message or series of messages is
 *                   passed to the controller to output bytes as text to
 *                   the debug console. These messages are constructed in
 *                   the interrupt handler for the SI instruction.
 *                   With this implementation, the user is unable to
 *                   utilize the message box interface in applications as
 *                   specialized interrupt handlers for the external
 *                   interrupts are necessary.
 *
 *
 *
 * Copyright (c) 2001, 2002, 2003, 2004 Morpho Technologies, Inc.
 *
 */

	.section .startup, "a", @progbits
	.global __boot_start
_INTERRUPT_VECTOR_TABLE:
__boot_start:
	jmp	_BOOTIVEC		; Boot vector
	or	r0, r0, r0
	jmp	_SOFTIVEC		; Vector for SI instruction
	or	r0,r0,r0
	jmp	_BRKIVEC		; Vector for Break instruction
	or	r0,r0,r0


	; This is the memory-mapped I/O region.

	; Hardware Interrupt Registers
	.org 0x100
	.global _DEV0_INTERRUPT_REG
_DEV0_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV1_INTERRUPT_REG
_DEV1_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV2_INTERRUPT_REG
_DEV2_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV3_INTERRUPT_REG
_DEV3_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV4_INTERRUPT_REG
_DEV4_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV5_INTERRUPT_REG
_DEV5_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV6_INTERRUPT_REG
_DEV6_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV7_INTERRUPT_REG
_DEV7_INTERRUPT_REG:
	.word 0x00000000

	; 60 bytes minus eight registers (four bytes per register)
	.fill (60 - 8 * 4)

	.global _INTERRUPT_MASK_REG
_INTERRUPT_MASK_REG:
	.word 0x00000000

	; 256 bytes minus sixteen registers (four bytes per register)
	.fill (256 - 16 * 4)



	.org 0x200
	; MorphoSys Decoder Registers
	.global _MS_DEC_AUTO_INCREMENT_REG
_MS_DEC_AUTO_INCREMENT_REG:
	.word 0x00000000

	.global _MS_DEC_SKIP_FACTOR_REG
_MS_DEC_SKIP_FACTOR_REG:
	.word 0x00000000

	.global _MS_DEC_CUSTOM_PERMUTATION_REG
_MS_DEC_CUSTOM_PERMUTATION_REG:
	.word 0x00000000

	.global _MS_DEC_CONTEXT_BASE_REG
_MS_DEC_CONTEXT_BASE_REG:
	.word 0x00000000

	.global _MS_DEC_LOOKUP_TABLE_BASE_REG
_MS_DEC_LOOKUP_TABLE_BASE_REG:
	.word 0x00000000

	.global _MS_CIRCULAR_BUFFER_END_REG
_MS_CIRCULAR_BUFFER_END_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRCULAR_BUFFER_SIZE_REG
_MS_CIRCULAR_BUFFER_SIZE_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BLOCK_END_REG
_MS_DATA_BLOCK_END_REG:
	.word 0x00000000

	.global _MS_DATA_BLOCK_SIZE_REG
_MS_DATA_BLOCK_SIZE_REG:
	.word 0x00000000

	; 256 bytes minus nine registers (four bytes per register)
	.fill (256 - 9 * 4)



	.org 0x300
	; Debug Registers
	.global _DEBUG_HALT_REG
_DEBUG_HALT_REG:
	.word 0x00000000

	.global _DEBUG_BREAK_REG
_DEBUG_BREAK_REG:
	.word 0x00000000

	.global _DEBUG_HW_RESERVED0_REG
_DEBUG_HW_RESERVED0_REG:
	.word 0x00000000

	.global _DEBUG_HW_RESERVED1_REG
_DEBUG_HW_RESERVED1_REG:
	.word 0x00000000

	.global _DEBUG_HW_RESERVED2_REG
_DEBUG_HW_RESERVED2_REG:
	.word 0x00000000

	.global _DEBUG_HW_RESERVED3_REG
_DEBUG_HW_RESERVED3_REG:
	.word 0x00000000

	.global _DEBUG_HW_RESERVED4_REG
_DEBUG_HW_RESERVED4_REG:
	.word 0x00000000

	.global _DEBUG_SW_SYSREQ_REG
_DEBUG_SW_SYSREQ_REG:
	.word 0x00000000

	; 256 bytes minus eight registers (four bytes per register)
	.fill (256 - 8 * 4)



	.org 0x400
	; Sequence Generator Registers
_SEQ_GEN_REGS:
	.fill 256



	.org 0x500
_RESERVED_SEQ_GEN_REGS:
	.fill 256



        .org 0x600
        .global _TIMER0_VAL_REG
_TIMER0_VAL_REG:
        .word 0x00000000

        .global _TIMER0_CTRL_REG
_TIMER0_CTRL_REG:
        .word 0x00000000

        .global _TIMER1_VAL_REG
_TIMER1_VAL_REG:
        .word 0x00000000

        .global _TIMER1_CTRL_REG
_TIMER1_CTRL_REG:
        .word 0x00000000

        .global _TIMER2_VAL_REG
_TIMER2_VAL_REG:
        .word 0x00000000

        .global _TIMER2_CTRL_REG
_TIMER2_CTRL_REG:
        .word 0x00000000

	; 256 bytes minus six registers (four bytes per register)
	.fill (256 - 6 * 4)



	.org 0x700
	.global _OUTPUT0_CONTROL
_OUTPUT0_CONTROL:
	.word 0x00000000

	.global _OUTPUT1_CONTROL
_OUTPUT1_CONTROL:
	.word 0x00000000

	.global _OUTPUT2_CONTROL
_OUTPUT2_CONTROL:
	.word 0x00000000

	.global _OUTPUT3_CONTROL
_OUTPUT3_CONTROL:
	.word 0x00000000

	.global _OUTPUT4_CONTROL
_OUTPUT4_CONTROL:
	.word 0x00000000

	.global _OUTPUT5_CONTROL
_OUTPUT5_CONTROL:
	.word 0x00000000

	.global _OUTPUT6_CONTROL
_OUTPUT6_CONTROL:
	.word 0x00000000

	.global _OUTPUT7_CONTROL
_OUTPUT7_CONTROL:
	.word 0x00000000

	; 256 bytes minus eight registers (four bytes per register)
	.fill (256 - 8 * 4)



	.org 0x800
	; Reserved memory-mapped space.
	.fill (0x1000 - 0x800)



	.text

	.equ SI_IOPORT_ADR, _DEBUG_SW_SYSREQ_REG
	.equ SI_IOPORT_BIT, 0x1
	.equ BRK_IOPORT_ADR, _DEBUG_BREAK_REG
	.equ BRK_IOPORT_BIT, 0x1

	.global _BOOTIVEC
_BOOTIVEC:

	; Initialize the interrupt controller's interrupt vector registers
	; for devices zero through seven.
	ldui    r1, #%hi16(_IVEC_DEFAULT)
	ori     r1, r1, #%lo16(_IVEC_DEFAULT)
	stw     r1, r0, #%lo16(_DEV0_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV1_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV2_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV3_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV4_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV5_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV6_INTERRUPT_REG)
	stw     r1, r0, #%lo16(_DEV7_INTERRUPT_REG)

	; Jump to the beginning of the application and enable interrupts.
	jmp	_start
	ei



	; Handler for the SI instruction. To perform a system call, the
	; C model uses a trapping mechanism which executes an SI instruction.
	; The Morpho Technologies simulator simply performs a branch to
	; this vector to simulate the SI instruction (this is as the hardware
	; behaves). In order to trigger the simulator that a system call
	; is needed, a write into the I/O register at address $40005 to
	; set bit #2 (0x4) is necessary.
	;
	; The above address has been changed to 0x31C and the bit number
	; is zero. (The manifest constants have been changed to reflect this.)
	;
	.global _SOFTIVEC
_SOFTIVEC:
	; Build a frame to save registers.
	subi	sp, sp, #$8
	stw	r9, sp, #$4
	ldui	r9, #%hi16(SI_IOPORT_ADR)
	stw	r10, sp, #$0
	ori	r9, r9, #%lo16(SI_IOPORT_ADR)
	ori	r10, r0, #SI_IOPORT_BIT
	stw	r10, r9, #$0
	; SYS_call is handled by simulator here...
	or	r0, r0, r0
	ldw	r10, sp, #$0
	or	r0, r0, r0
	ldw	r9, sp, #$4
	reti	r14
	addi	sp, sp, #$8



	.global _BRKIVEC
_BRKIVEC:
	; Build a frame to save registers.
	subi	sp, sp, #$8
	stw	r9, sp, #$4
	ldui	r9, #%hi16(BRK_IOPORT_ADR)
	stw	r10, sp, #$0
	ori	r9, r9, #%lo16(BRK_IOPORT_ADR)
	ori	r10, r0, #BRK_IOPORT_BIT
	stw	r10, r9, #$0
	or	r0, r0, r0
	ldw	r10, sp, #$0
	subi	r15, r15, #$4		; Backup to address of break
	ldw	r9, sp, #$4
	reti	r15
	addi	sp, sp, #$8



	.global _IVEC_DEFAULT
_IVEC_DEFAULT:
	reti	r15
	or	r0, r0, r0
