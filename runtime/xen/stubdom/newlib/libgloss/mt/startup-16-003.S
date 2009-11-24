/*
 * $Header: /cvs/src/src/libgloss/mt/startup-16-003.S,v 1.2 2006/03/22 12:47:59 nathan Exp $
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
 *   09Jan04 (DJK) Modified internal I/O port definitions for the
 *                   MS1-16-003.
 *
 *   10Oct01 (DJK) The memory map is finalized and the first 4K of address
 *                   space is now reserved for memory-mapped I/O devices.
 *                   (There is over 2K unused, reserved space in this area.)
 *
 *   26Sep01 (DJK) The memory map is changed and the device interrupts are
 *                   now memory-mapped.
 *
 *
 *
 * Copyright (c) 2001, 2002, 2003, 2004 Morpho Technologies
 *
 */

	.section .startup, "a", @progbits
	.global __boot_start
__boot_start:
_INTERRUPT_VECTOR_TABLE:
	jmp	_BOOTIVEC		; Boot vector
	or	r0, r0, r0
	jmp	_SOFTIVEC		; Vector for SI instruction
	or	r0,r0,r0
	jmp	_BRKIVEC		; Vector for Break instruction
	or	r0,r0,r0
	; The illegal instruction trap is not implemented.
	;jmp	_ILLIVEC		; Vector for illegal instruction
	or	r0,r0,r0
	or	r0,r0,r0
_RESERVED1_IVEC:
        jmp	_RESERVED1_IVEC
        or	r0,r0,r0
_RESERVED2_IVEC:
        jmp	_RESERVED2_IVEC
        or	r0,r0,r0
_RESERVED3_IVEC:
        jmp	_RESERVED3_IVEC
        or	r0,r0,r0
_RESERVED4_IVEC:
        jmp	_RESERVED4_IVEC
        or	r0,r0,r0


	.text

	.equ SI_IOPORT_ADR, _DEBUG_SW_SYSREQ_REG
	.equ SI_IOPORT_BIT, 0x1
	.equ BRK_IOPORT_ADR, _DEBUG_BREAK_REG
	.equ BRK_IOPORT_BIT, 0x1

	.global _BOOTIVEC
_BOOTIVEC:
	; Initialize the interrupt controller's interrupt vector registers
	ldui	r1, #%hi16(_IVEC_DEFAULT)
	ori	r1, r1, #%lo16(_IVEC_DEFAULT)
	stw	r1, r0, #%lo16(_DEV0_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV1_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV2_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV3_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV4_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV5_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV6_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV7_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV8_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV9_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV10_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV11_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV12_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV13_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV14_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV15_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV16_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV17_INTERRUPT_REG)
	stw	r1, r0, #%lo16(_DEV18_INTERRUPT_REG)

	; Statically initialized data must be copied from ROM to RAM.
	; This is done in the C run-time start-up code (crt0.o).

	; Jump to the beginning of the application and enable interrupts.
	jmp	_start
	ei


	; Handler for the SI instruction. To perform a system call, the
	; C model uses a trapping mechanism which executes an SI instruction.
	; The Morpho Technologies simulator simply performs a branch to
	; this vector to simulate the SI instruction (this is as the hardware
	; behaves). In order to trigger the simulator that a system call
	; is needed a write into the I/O register at address $40005 to
	; set bit #2 (0x4) is necessary.
	;
	; The above address has been changed to 0x00031C and the bit number
	; is zero. (The manifest constants have been changed to reflect this.)
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
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
	or	r0, r0, r0
	ldw	r10, sp, #$0
	ldw	r9, sp, #$4
	reti	r15
	addi	sp, sp, #$8


.if 0
	; Handler for illegal instruction.
	.global _ILLIVEC
_ILLIVEC:
	reti r15
	or r0, r0, r0
.endif


	.global _IVEC_DEFAULT
_IVEC_DEFAULT:
	reti	r15
	or	r0, r0, r0


	.section .internal_io, "a", @nobits
	.fill 256		; Fill the first page.

	; This is the memory-mapped I/O region.

	; Hardware Interrupt Registers
	;.org 0xfffff100
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

	.global _DEV8_INTERRUPT_REG
_DEV8_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV9_INTERRUPT_REG
_DEV9_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV10_INTERRUPT_REG
_DEV10_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV11_INTERRUPT_REG
_DEV11_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV12_INTERRUPT_REG
_DEV12_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV13_INTERRUPT_REG
_DEV13_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV14_INTERRUPT_REG
_DEV14_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV15_INTERRUPT_REG
_DEV15_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV16_INTERRUPT_REG
_DEV16_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV17_INTERRUPT_REG
_DEV17_INTERRUPT_REG:
	.word 0x00000000

	.global _DEV18_INTERRUPT_REG
_DEV18_INTERRUPT_REG:
	.word 0x00000000

	; 128 bytes minus nineteen registers (four bytes per register)
	.fill (128 - 19 * 4)

	.global	_INTERRUPT_MASK_REG
_INTERRUPT_MASK_REG:
	.word 0x00000000

	.global	_INTERRUPT_PENDING_REG
_INTERRUPT_PENDING_REG:
	.word 0x00000000

	; 16 bytes minus two registers (four bytes per register)
	.fill (16 - 2 * 4)

	.global _DEV0_INTERRUPT_LEVEL_REG
_DEV0_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV1_INTERRUPT_LEVEL_REG
_DEV1_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV2_INTERRUPT_LEVEL_REG
_DEV2_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV3_INTERRUPT_LEVEL_REG
_DEV3_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV4_INTERRUPT_LEVEL_REG
_DEV4_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV5_INTERRUPT_LEVEL_REG
_DEV5_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV6_INTERRUPT_LEVEL_REG
_DEV6_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV7_INTERRUPT_LEVEL_REG
_DEV7_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV8_INTERRUPT_LEVEL_REG
_DEV8_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV9_INTERRUPT_LEVEL_REG
_DEV9_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV10_INTERRUPT_LEVEL_REG
_DEV10_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV11_INTERRUPT_LEVEL_REG
_DEV11_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV12_INTERRUPT_LEVEL_REG
_DEV12_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV13_INTERRUPT_LEVEL_REG
_DEV13_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV14_INTERRUPT_LEVEL_REG
_DEV14_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV15_INTERRUPT_LEVEL_REG
_DEV15_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV16_INTERRUPT_LEVEL_REG
_DEV16_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV17_INTERRUPT_LEVEL_REG
_DEV17_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	.global _DEV18_INTERRUPT_LEVEL_REG
_DEV18_INTERRUPT_LEVEL_REG:
	.word 0x00000000

	; 128 bytes minus twenty-three registers (four bytes per register)
	.fill (128 - 23 * 4)


	;.org 0xfffff200
	; MorphoSys Decoder Registers
	.global _MS_DEC_CIRC_BUFF_SEL_REG
_MS_DEC_CIRC_BUFF_SEL_REG:
	.word 0x00000000

	.global _MS_DEC_SKIP_FACTOR_REG
_MS_DEC_SKIP_FACTOR_REG:
	.word 0x00000000

	.global _MS_DEC_CUSTOM_PERM_REG
_MS_DEC_CUSTOM_PERM_REG:
	.word 0x00000000

	.global _MS_DEC_CTXT_BASE_REG
_MS_DEC_CTXT_BASE_REG:
	.word 0x00000000

	.global _MS_DEC_LOOKUP_TBL_REG
_MS_DEC_LOOKUP_TBL_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF0_I_REG
_MS_CIRC_BUFF0_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF0_P_REG
_MS_CIRC_BUFF0_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF0_B_REG
_MS_DATA_BUFF0_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF0_S_REG
_MS_DATA_BUFF0_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF1_I_REG
_MS_CIRC_BUFF1_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF1_P_REG
_MS_CIRC_BUFF1_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF1_B_REG
_MS_DATA_BUFF1_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF1_S_REG
_MS_DATA_BUFF1_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF2_I_REG
_MS_CIRC_BUFF2_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF2_P_REG
_MS_CIRC_BUFF2_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF2_B_REG
_MS_DATA_BUFF2_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF2_S_REG
_MS_DATA_BUFF2_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF3_I_REG
_MS_CIRC_BUFF3_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF3_P_REG
_MS_CIRC_BUFF3_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF3_B_REG
_MS_DATA_BUFF3_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF3_S_REG
_MS_DATA_BUFF3_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF4_I_REG
_MS_CIRC_BUFF4_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF4_P_REG
_MS_CIRC_BUFF4_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF4_B_REG
_MS_DATA_BUFF4_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF4_S_REG
_MS_DATA_BUFF4_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF5_I_REG
_MS_CIRC_BUFF5_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF5_P_REG
_MS_CIRC_BUFF5_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF5_B_REG
_MS_DATA_BUFF5_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF5_S_REG
_MS_DATA_BUFF5_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF6_I_REG
_MS_CIRC_BUFF6_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF6_P_REG
_MS_CIRC_BUFF6_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF6_B_REG
_MS_DATA_BUFF6_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF6_S_REG
_MS_DATA_BUFF6_S_REG:
	.word 0x00000000

	.global _MS_CIRC_BUFF7_I_REG
_MS_CIRC_BUFF7_I_REG:
	.word (__FRAME_BUFFER_END)

	.global _MS_CIRC_BUFF7_P_REG
_MS_CIRC_BUFF7_P_REG:
	.word __FRAME_BUFFER_SIZE

	.global _MS_DATA_BUFF7_B_REG
_MS_DATA_BUFF7_B_REG:
	.word 0x00000000

	.global _MS_DATA_BUFF7_S_REG
_MS_DATA_BUFF7_S_REG:
	.word 0x00000000

	.global _MS_OMEGA_PERM1_REG
_MS_OMEGA_PERM1_REG:
	.word 0x00000000

	.global _MS_WRITE_FB_ADDR_REG
_MS_WRITE_FB_ADDR_REG:
	.word 0x00000000

	.global _MS_OMEGA_PERM2_REG
_MS_OMEGA_PERM2_REG:
	.word 0x00000000


	; 256 bytes minus forty registers (four bytes per register)
	.fill (256 - 40 * 4)



	;.org 0xfffff300
	; Debug Registers
	.global _DEBUG_HALT_REG
_DEBUG_HALT_REG:
	.word 0x00000000

	.global _DEBUG_BREAK_REG
_DEBUG_BREAK_REG:
	.word 0x00000000

	.global _DEBUG_CRITICAL_REG
_DEBUG_OWNERSHIP_REG:
	.word 0x00000000

	.global _DEBUG_KERNEL_ID_REG
_DEBUG_KERNEL_ID_REG:
	.word 0x00000000

	.global _DEBUG_IRQ_STATUS_REG
_DEBUG_IRQ_STATUS_REG:
	.word 0x00000000

	; There are two reserved registers.
	.fill (2 * 4)

        .global _DEBUG_SW_SYSREQ_REG
_DEBUG_SW_SYSREQ_REG:
        .word 0x00000000

	; 128 bytes minus eight registers (four bytes per register)
	.fill (128 - 8 * 4)

	.global _EXTENDED_GP0_REG
_EXTENDED_GP0_REG:
	.word 0x00000000

	.global _EXTENDED_GP1_REG
_EXTENDED_GP1_REG:
	.word 0x00000000

	.global _EXTENDED_GP2_REG
_EXTENDED_GP2_REG:
	.word 0x00000000

	.global _EXTENDED_GP3_REG
_EXTENDED_GP3_REG:
	.word 0x00000000

	.global _EXTENDED_GP4_REG
_EXTENDED_GP4_REG:
	.word 0x00000000

	.global _EXTENDED_GP5_REG
_EXTENDED_GP5_REG:
	.word 0x00000000

	.global _EXTENDED_GP6_REG
_EXTENDED_GP6_REG:
	.word 0x00000000

	.global _EXTENDED_GP7_REG
_EXTENDED_GP7_REG:
	.word 0x00000000

	.global _MEM_CTRL_EN_NC_MEM_REG
_MEM_CTRL_EN_NC_MEM_REG:
	.word 0x00000000

	.global _MEM_CTRL_BASE0_ADDR_REG
_MEM_CTRL_BASE0_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_MASK0_ADDR_REG
_MEM_CTRL_MASK0_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_BASE1_ADDR_REG
_MEM_CTRL_BASE1_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_MASK1_ADDR_REG
_MEM_CTRL_MASK1_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_BASE2_ADDR_REG
_MEM_CTRL_BASE2_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_MASK2_ADDR_REG
_MEM_CTRL_MASK2_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_BASE3_ADDR_REG
_MEM_CTRL_BASE3_ADDR_REG:
	.word 0x00000000

	.global _MEM_CTRL_MASK3_ADDR_REG
_MEM_CTRL_MASK3_ADDR_REG:
	.word 0x00000000

        ; 128 bytes minus seventeen registers (four bytes per register)
        .fill (128 - 17 * 4)



	; Reserved memory-map space
	.fill (256 + 256)



        ;.org 0xfffff600
	; Timer Registers
        .global _TIMER0_VAL_REG
_TIMER0_VAL_REG:
        .word 0x00000000

        .global _TIMER1_VAL_REG
_TIMER1_VAL_REG:
        .word 0x00000000

        .global _TIMER2_VAL_REG
_TIMER2_VAL_REG:
        .word 0x00000000

        .global _TIMER3_VAL_REG
_TIMER3_VAL_REG:
        .word 0x00000000

	; 256 bytes minus four registers (four bytes per register)
	.fill (256 - 4 * 4)



	;.org 0xfffff700
	; Output Line Control Registers
	.global _OUTPUT0_CTRL
_OUTPUT0_CTRL:
	.word 0x00000000

	.global _OUTPUT1_CTRL
_OUTPUT1_CTRL:
	.word 0x00000000

	.global _OUTPUT2_CTRL
_OUTPUT2_CTRL:
	.word 0x00000000

	.global _OUTPUT3_CTRL
_OUTPUT3_CTRL:
	.word 0x00000000

	.global _OUTPUT4_CTRL
_OUTPUT4_CTRL:
	.word 0x00000000

	.global _OUTPUT5_CTRL
_OUTPUT5_CTRL:
	.word 0x00000000

	.global _OUTPUT6_CTRL
_OUTPUT6_CTRL:
	.word 0x00000000

	; 128 bytes minus seven registers (four bytes per register)
	.fill (128 - 7 * 4)

	.global _INPUT0_CTRL
_INPUT0_CTRL:
	.word 0x00000000

	; 128 bytes minus one register (four bytes per register)
	.fill (128 - 1 * 4)



	;.org 0xfffff800
	; IQ Buffer Registers
	.global _IQ_BUFF_CTRL_REG
_IQ_BUFF_CTRL_REG:
	.word 0x00000000

	.global _IQ_BUFF_STATUS_REG
_IQ_BUFF_STATUS_REG:
	.word 0x00000000

	.global _IQ_BUFF_PARAMETER1_REG
_IQ_BUFF_PARAMETER1_REG:
	.word 0x00000000

	.global _IQ_BUFF_TRANSFER_SIZE1_REG
_IQ_BUFF_TRANSFER_SIZE1_REG:
	.word 0x00000000

	.global _IQ_BUFF_FB_BASE1_REG
_IQ_BUFF_FB_BASE1_REG:
	.word 0x00000000

	.global _IQ_BUFF_FB_SIZE1_REG
_IQ_BUFF_FB_SIZE1_REG:
	.word 0x00000000

	.global _IQ_BUFF_PARAMETER2_REG
_IQ_BUFF_PARAMETER2_REG:
	.word 0x00000000

	.global _IQ_BUFF_TRANSFER_SIZE2_REG
_IQ_BUFF_TRANSFER_SIZE2_REG:
	.word 0x00000000

	.global _IQ_BUFF_FB_BASE2_REG
_IQ_BUFF_FB_BASE2_REG:
	.word 0x00000000

	.global _IQ_BUFF_FB_SIZE2_REG
_IQ_BUFF_FB_SIZE2_REG:
	.word 0x00000000

	; 256 bytes minus ten registers (four bytes per register)
	.fill (256 - 10 * 4)



	;.org 0xfffff900
	; DMA Controller
	.global _DMA_CTRL_REG
_DMA_CTRL_REG:
	.word 0x00000000

	.global _DMA_STATUS_REG
_DMA_STATUS_REG:
	.word 0x00000000

	.global _DMA_CH0_EADDR_REG
_DMA_CH0_EADDR_REG:
	.word 0x00000000

	.global _DMA_CH0_IADDR_REG
_DMA_CH0_IADDR_REG:
	.word 0x00000000

	.global _DMA_CH0_SIZE_REG
_DMA_CH0_SIZE_REG:
	.word 0x00000000

	.global _DMA_CH1_EADDR_REG
_DMA_CH1_EADDR_REG:
	.word 0x00000000

	.global _DMA_CH1_IADDR_REG
_DMA_CH1_IADDR_REG:
	.word 0x00000000

	.global _DMA_CH1_SIZE_REG
_DMA_CH1_SIZE_REG:
	.word 0x00000000

	.global _DMA_CH2_EADDR_REG
_DMA_CH2_EADDR_REG:
	.word 0x00000000

	.global _DMA_CH2_IADDR_REG
_DMA_CH2_IADDR_REG:
	.word 0x00000000

	.global _DMA_CH2_SIZE_REG
_DMA_CH2_SIZE_REG:
	.word 0x00000000

	.global _DMA_CH3_EADDR_REG
_DMA_CH3_EADDR_REG:
	.word 0x00000000

	.global _DMA_CH3_IADDR_REG
_DMA_CH3_IADDR_REG:
	.word 0x00000000

	.global _DMA_CH3_SIZE_REG
_DMA_CH3_SIZE_REG:
	.word 0x00000000

	; 256 bytes minus fourteen registers (four bytes per register)
	.fill (256 - 14 * 4)



	;.org 0xfffffa00
	; Sequence Generator
	.global _SEQ_GEN_CTRL_STATUS_REG
_SEQ_GEN_CTRL_STATUS_REG:
	.word 0x00000000

	.global _SEQ_GEN_MASK_REGS
_SEQ_GEN_MASK_REGS:
	.fill (302 * 4)

	.global _SEQ_GEN_SHIFT_REG
_SEQ_GEN_SHIFT_REG:
	.word 0x00000000

	; 256 bytes minus seven registers (four bytes per register)
	.fill (256 - 48 * 4)



	; Reserved memory-map space
	.fill (0x1000 - 0xf00)
