/**
 * fido-crt0.S -- Simple startup code
 *
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
 *
 * Copyright 2006 Innovasic Semiconductor, All Rights Reserved.
 * Part of the fido Realtime Support Library
 *
 * Description:
 *   This routine performs initializations assuming a Fido
 *   development board.  In order, the following functions are performed:
 *
 *     -- memory offset register initialization
 *     -- chip select register initialization for external memory
 *     -- SDRAM ctrl register initialization for external memory
 *     -- in line test of external SRAM
 *     -- sets user SP for MasterContext0 (main)
 *     -- copies the bss section to RAM
 *     -- transfers control to MasterContext0 (main)
 * 
 */

#include "asm.h"
#include "fido.h"

.title "fido-crt0.S for Fido"

/*----------------------------------------------------------------------------*/
//--------- 66 MHz values --------
// set up CS0 for flash
#define CS0_CTRL_VAL         0x0000024A
#define CS0_TIMING_VAL       0x01000000

// set up CS1 for SDRAM
#define CS1_CTRL_VAL         0x0200030A   /* selects SDRAM ctrl instead of CS1 */
#define CS1_TIMING_VAL       0x00000000   /* N/A for SDRAM operation */
#define SDRAM_TIMING_0_VAL   0x00022522   /* TRP=0x2, TRCD=0x2, TRF=0x5, TWR=0x5 TCL=0x5 */
#define SDRAM_TIMING_1_VAL   0x00120407   /* INI_PREC=0x1, INI_REFT=0x2, REF_INTV=0x407 */
#define SDRAM_CONFIG_0_VAL   0x00002113   /* MA2T=0, DDW=x16device=0x2, dsz=64MBit, mbw=16bit, bnksz=8Mbyte */
#define SDRAM_CONFIG_1_VAL   0x00000000   /* IPREC=0, IREF=0, ISMR=0, PWDN=0, SREF=0 */
#define SDRAM_EXT_BANK_1_VAL 0x00001020   /* SDRAM memory bank 0 at addr 0x0200_0000 */ 

// set up CS2 for SRAM        
#define CS2_CTRL_VAL         0x03000267
#define CS2_TIMING_VAL       0x08400000
/*----------------------------------------------------------------------------*/

#define EXT_SRAM_END_ADDR  0x30FFFFC /* 1 MB of ext. SRAM (2-512Kx8 chips) */
#define PERP_PWRUP_MASK    0x0000       /* turn on all peripherals */

/*
 * Define an empty environment.
 */
    .data  2
    .align 2
SYM (environ):
    .long 0

 	.align	2
	.text   2

/*
 * These symbols are defined in C code, so they need to always be
 * named with SYM because of the difference between object file formats.
 */

/* These are defined in C code. */
/*	.extern SYM (main)    */
	.extern SYM (exit)
	.extern SYM (hardware_init_hook)
	.extern SYM (software_init_hook)
	.extern SYM (atexit)
	.extern SYM (__do_global_dtors)
/* 
 * These values are set in the linker script, so they must be
 * explicitly named here without SYM.
 */
#ifdef FIDO_rom
	.extern __stack
#endif
	.extern __bss_start
	.extern _end

/*
 * set things up so application will run. This *must* be called _start.
 */
	.global SYM (_start)

SYM (_start):

#ifdef FIDO_rom
    /* save initial value of base offset register */
    movec  mbb,d7

    /* Initialize memory offset register to offset value in FIDOmemmap.h */ 
    movel #FIDO_MEM_OFFSET,d0          /* Load memory offset into REG d0 */
    movec d0,mbb

    movel #0x011, FIDO_DBG_CTRL       /* set the debug control reg */
    
    /* At POR the PerpPowerCtrlReg is set to 0x3F0F, all peripherals off
       See PerpPowerCtrlReg definition, this example turns ON everything */
    movel   #PERP_PWRUP_MASK,FIDO_CLOCK_MASK_REGISTER

	/* Set up chip selects for ROM, SRAM, and SDRAM (all external mem.) */
    movel   #CS0_CTRL_VAL, FIDO_BIU_CS0_CONTROL   /* flash memory CS0    */
    movel   #CS0_TIMING_VAL, FIDO_BIU_CS0_TIMING 

    movel   #CS2_CTRL_VAL, FIDO_BIU_CS2_CONTROL   /* SRAM memory CS2     */
    movel   #CS2_TIMING_VAL, FIDO_BIU_CS2_TIMING 

    /* if this is not POR then say so */
    movel FIDO_POR_REG,d6

	/* test external SRAM -- */
	/*   a0 == working pointer           */
	/*   a1 == pointer to base of memory */
	/*   a2 == pointer to end of memory  */
	/*   d0,d1,d2,d3 working registers   */
	
	moveal #0x3000000,a1
	moveal #0x30FFFFC,a2

	movel  a1,a0
	/*   walking ones  */
	movel #1,d0

.LWalkOnes:
	movel d0, (a0)       /* write value out */
	cmpl  (a0), d0       /* read it back    */
	bne   .LFailOnes
	lsl.l  #1, d0        /* move to next value */
	bne   .LWalkOnes       /* when it goes to zero you're done */
	bra   .LValTest
.LFailOnes:
	movel #0x01, d0
	bra   .LMemTestEnd

.LValTest:
	/*   ffff's    */
	/*   5555's	   */
	/*   aaaa's	   */
	/*   0000's    */
	movel a1,a0
	movel  #0xFFFFFFFF,d0

.LValLoop:
	movel d0,(a0)        /* write value out */
	cmpl  (a0)+, d0      /* compare and move to next */
	bne   .LFailVal
	cmpl  a0,a2          /* at end of memory?  */
	bge   .LValLoop
	movel d0,d0          /* done writing zeros?  */
	beq   .LAddrTest
	movel a1,a0          /* go back to start with next value */
	subl  #0x55555555,d0 /* get next value (f->a->5->0) */
	bra   .LValLoop
.LFailVal:
	movel #0x02, d0
	bra   .LMemTestEnd

.LAddrTest:
	/*   unique values */
	movel  a1,a0
.LWriteLoop:
	movel  a0, (a0)+     /* write value out and move one */
	cmpl   a0,a2         /* look for end of memory */
	bge    .LWriteLoop

	movel  a1,a0
.LReadLoop:
	cmpl   (a0), a0      /* compare value and move on */
	bne    .LFailAddr
	addql  #4,a0
	cmpl   a0,a2         /* look for end of memory */
	bge    .LReadLoop
	clrl   d0            /* everything passed */
	bra    .LMemTestEnd

.LFailAddr:
	movel  #0x03, d0

.LMemTestEnd:
    movel   d0,d4        /* mem test result in d4 0 == pass */
#endif /* ROM */
	
	/* See if user supplied their own stack (__stack != 0).  If not, then
	 * default to using the value of %sp as set by the ROM monitor      */
	movel	IMM(__stack), a0
	cmpl	IMM(0), a0
	jbeq    .Lloc1
	movel	a0, sp
.Lloc1:
	/* set up initial stack frame */
	link	a6, IMM(-8)

#ifdef FIDO_rom
/* 
 * Now set up the SDRAM (waited to let the controller spin up)
*/
    /* always initialize SDRAM regs, they're cleared by any reset */	
    /* SDRAM enbl bit set in CS1 re-directs to SDRAM controller regs    */

    movel   #CS1_CTRL_VAL,         FIDO_BIU_CS1_CONTROL  /* SDRAM memory CS1    */
    movel   #SDRAM_TIMING_0_VAL,   FIDO_SDRAM_TIMING_0   /* SDRAM TIMING REG0 */
    movel   #SDRAM_TIMING_1_VAL,   FIDO_SDRAM_TIMING_1   /* SDRAM TIMING REG1 */
    movel   #SDRAM_CONFIG_0_VAL,   FIDO_SDRAM_CONFIG_0   /* SDRAM CONFIG REG */
    movel   #0x0000001c,           FIDO_SDRAM_CONFIG_1   /* SDRAM CONFIG REG */
	
.LsdConfigLoop:
    movel   FIDO_SDRAM_CONFIG_1,d0
    cmpl    #0x00000000,d0
    bne     .LsdConfigLoop   

    movel   #SDRAM_EXT_BANK_1_VAL, FIDO_SDRAM_EXT_BANK_1 /* BANK 1 REG    */

/*
 * copy data from ROM to RAM
 */

    moval   IMM(__start_romdata),a0 /* begin data in ROM */
    moval   IMM(_data), a1         /* begin data in RAM */
    moval   IMM(_edata),a2         /* end of data in RAM */

    /* while(a1 < a2) *a1++ = *a0++; */
.LdataCopyLoop:
    movel   (a0)+,(a1)+
    cmpal    a1,a2
    bgt     .LdataCopyLoop
#endif /* ROM */

#ifdef FIDO_ram
	/* For ROM configs, the linker script ensures that
	   _vector_table is placed at the proper place.  For RAM
	   configs, we have to adjust it ourselves.  */
	movel	IMM (SYM (_vector_table)), FIDO_CTX0_VBR
#endif

#ifndef FIDO_redboot
	/* Setup interrupt vectors for secondary contexts.  */
	movel	IMM (SYM (_vector_table1)), FIDO_CTX1_VBR
	movel	IMM (SYM (_vector_table2)), FIDO_CTX2_VBR
	movel	IMM (SYM (_vector_table3)), FIDO_CTX3_VBR
	movel	IMM (SYM (_vector_table4)), FIDO_CTX4_VBR
#endif

/*
 * zero out the bss section.
 */
	movel	IMM(__bss_start), d1
	movel	IMM(_end), d0
	cmpl	d0, d1
	jbeq	.Lloc3
	movl	d1, a0
	subl	d1, d0
	subql	IMM(1), d0
2:
	clrb	(a0)+
#ifndef __mcf5200__
	dbra	d0, 2b
	clrw	d0
	subql	IMM(1), d0
	jbcc	2b
#else
	subql	IMM(1), d0
	jbpl	2b
#endif

.Lloc3:

#ifdef ADD_DTORS
	/* put __do_global_dtors in the atexit list so the destructors get run */
	movel	IMM (SYM(__do_global_dtors)),(sp)
	jsr	SYM (atexit)
#endif
	movel	IMM (_fini),(sp)
	jsr	SYM (atexit)

	jsr	_init

/*
 * call the main routine from the application to get it going.
 * main (argc, argv, environ)
 * we pass argv as a pointer to NULL.
 */

    pea     0
    pea     SYM (environ)
    pea     sp@(4)
    pea     0
    jsr     SYM (main)   /* call to main */
	movel	d0, sp@-

/*
 * drop down into exit in case the user doesn't. This should drop
 * control back to the ROM monitor, if there is one. This calls the
 * exit() from the C library so the C++ tables get cleaned up right.
 */
        jsr     SYM (exit)

#ifndef FIDO_redboot
	/* Define the interrupt vector table.  The linker script
	   ensures that the table is placed at address zero.  */
	.section  .vector_table,"a"

        .global	SYM (_vector_table)

SYM (_vector_table):

	dc.l    __stack                          /* 000 Initial Stack              */
	dc.l    _start                           /* 001 Context 0 Start            */
	dc.l    _BusErrorHandler                 /* 002 Bus Error                  */
        dc.l    _AddressErrorHandler             /* 003 Address Error              */
        dc.l    _IllegalInstructionHandler       /* 004 Illegal Instruction        */
        dc.l    _DivideByZeroHandler             /* 005 Divide by Zero             */
        dc.l    _ChkHandler                      /* 006 CHK, CHK2 Instructions     */  
        dc.l    _TrapccHandler                   /* 007 TRAPcc, TRAPV Instructions */
        dc.l    _PrivilegeViolationHandler       /* 008 Privilege Violation        */
        dc.l    _TraceHandler                    /* 009 Trace                      */
        dc.l    _ALineHandler                    /* 010 A-Line Unimplemented Instr */
        dc.l    _FLineHandler                    /* 011 F-Line Unimplemented Instr */
        dc.l    _HwBreakpointHandler             /* 012 Hardware Breakpoint        */
        dc.l    _Reserved0Handler                /* 013 Reserved                   */
        dc.l    _FormatErrorHandler              /* 014 Format Error               */
        dc.l    _UnitializedIntHandler           /* 015 Unitialized Interrupt      */
        dc.l    _SoftwareIntHandler              /* 016 Software Interrupt         */
        dc.l    _Unassigned0Handler              /* 017 Unassigned                 */
        dc.l    _Unassigned1Handler              /* 018 Unassigned                 */
        dc.l    _Unassigned2Handler              /* 019 Unassigned                 */
        dc.l    _Unassigned3Handler              /* 020 Unassigned                 */
        dc.l    _Unassigned4Handler              /* 021 Unassigned                 */
        dc.l    _Unassigned5Handler              /* 022 Unassigned                 */
        dc.l    _Unassigned6Handler              /* 023 Unassigned                 */     
        dc.l    _Int0Handler                     /* 024 Interrupt 0                */
        dc.l    _Int1Handler                     /* 025 Interrupt 1                */
        dc.l    _Int2Handler                     /* 026 Interrupt 2                */
        dc.l    _Int3Handler                     /* 027 Interrupt 3                */
        dc.l    _Int4Handler                     /* 028 Interrupt 4                */
        dc.l    _Int5Handler                     /* 029 Interrupt 5                */
        dc.l    _Int6Handler                     /* 030 Interrupt 6                */
        dc.l    _Int7Handler                     /* 031 Interrupt 7                */
        dc.l    _Trap00Handler                   /* 032 Trap #00 Instruction       */
        dc.l    _Trap01Handler                   /* 033 Trap #01 Instruction       */
        dc.l    _Trap02Handler                   /* 034 Trap #02 Instruction       */
        dc.l    _Trap03Handler                   /* 035 Trap #03 Instruction       */
        dc.l    _Trap04Handler                   /* 036 Trap #04 Instruction       */
        dc.l    _Trap05Handler                   /* 037 Trap #05 Instruction       */
        dc.l    _Trap06Handler                   /* 038 Trap #06 Instruction       */
        dc.l    _Trap07Handler                   /* 039 Trap #07 Instruction       */
        dc.l    _Trap08Handler                   /* 040 Trap #08 Instruction       */
        dc.l    _Trap09Handler                   /* 041 Trap #09 Instruction       */
        dc.l    _Trap10Handler                   /* 042 Trap #10 Instruction       */
        dc.l    _Trap11Handler                   /* 043 Trap #11 Instruction       */
        dc.l    _Trap12Handler                   /* 044 Trap #12 Instruction       */
        dc.l    _Trap13Handler                   /* 045 Trap #13 Instruction       */
        dc.l    _Trap14Handler                   /* 046 Trap #14 Instruction       */
        dc.l    _Trap15Handler                   /* 047 Trap #15 Instruction       */
        dc.l    _Reserved048Handler              /* 048 Reserved                   */
        dc.l    _Reserved049Handler              /* 049 Reserved                   */
        dc.l    _Reserved050Handler              /* 050 Reserved                   */
        dc.l    _Reserved051Handler              /* 051 Reserved                   */
        dc.l    _Reserved052Handler              /* 052 Reserved                   */
        dc.l    _Reserved053Handler              /* 053 Reserved                   */
        dc.l    _Reserved054Handler              /* 054 Reserved                   */
        dc.l    _Reserved055Handler              /* 055 Reserved                   */
        dc.l    _Reserved056Handler              /* 056 Reserved                   */
        dc.l    _Reserved057Handler              /* 057 Reserved                   */
        dc.l    _Reserved058Handler              /* 058 Reserved                   */
        dc.l    _Reserved059Handler              /* 059 Reserved                   */
        dc.l    _Reserved060Handler              /* 060 Reserved                   */
        dc.l    _Reserved061Handler              /* 061 Reserved                   */
        dc.l    _Reserved062Handler              /* 062 Reserved                   */
        dc.l    _Reserved063Handler              /* 063 Reserved                   */
        dc.l    _ContextOvertimeHandler          /* 064 Context Overtime           */
        dc.l    _MpuErrorHandler                 /* 065 MPU Error                  */
        dc.l    _SystemTimer0Handler             /* 066 System Timer 0             */
        dc.l    _SystemTimer1Handler             /* 067 System Timer 1             */
        dc.l    _SystemTimer2Handler             /* 068 System Timer 2             */
        dc.l    _SystemTimer3Handler             /* 069 System Timer 3             */
        dc.l    _SystemTimer4Handler             /* 070 System Timer 4             */
        dc.l    _WatchdogTimerHandler            /* 071 Watchdog Timer             */
        dc.l    _TimerCounter0Handler            /* 072 Timer Counter 1            */
        dc.l    _TimerCounter1Handler            /* 073 Timer Counter 2            */
        dc.l    _DMA0Handler                     /* 074 DMA Channel 0              */
        dc.l    _DMA1Handler                     /* 075 DMA Channel 1              */
        dc.l    _AtoDConversionHandler           /* 076 A/D Conversion Complete    */
        dc.l    _Pdma0Handler                    /* 077 PDMA Ch 0 Interrupt        */
        dc.l    _Pdma1Handler                    /* 078 PDMA Ch 1 Interrupt        */
        dc.l    _Pdma2Handler                    /* 079 PDMA Ch 2 Interrupt        */
        dc.l    _Pdma3Handler                    /* 080 PDMA Ch 3 Interrupt        */
        dc.l    _Reserved081Handler              /* 081 Reserved                   */
        dc.l    _Reserved082Handler              /* 082 Reserved                   */
        dc.l    _Reserved083Handler              /* 083 Reserved                   */
        dc.l    _Reserved084Handler              /* 084 Reserved                   */
        dc.l    _Reserved085Handler              /* 085 Reserved                   */
        dc.l    _Reserved086Handler              /* 086 Reserved                   */
        dc.l    _Reserved087Handler              /* 087 Reserved                   */
        dc.l    _Reserved088Handler              /* 088 Reserved                   */
        dc.l    _Reserved089Handler              /* 089 Reserved                   */
        dc.l    _Reserved090Handler              /* 090 Reserved                   */
        dc.l    _Reserved091Handler              /* 091 Reserved                   */
        dc.l    _Reserved092Handler              /* 092 Reserved                   */
        dc.l    _Reserved093Handler              /* 093 Reserved                   */
        dc.l    _Reserved094Handler              /* 094 Reserved                   */
        dc.l    _Reserved095Handler              /* 095 Reserved                   */
        dc.l    _Trapx00Handler                  /* 096 Trapx 00 Instruction       */
        dc.l    _Trapx01Handler                  /* 097 Trapx 01 Instruction       */
        dc.l    _Trapx02Handler                  /* 098 Trapx 02 Instruction       */
        dc.l    _Trapx03Handler                  /* 099 Trapx 03 Instruction       */
        dc.l    _Trapx04Handler                  /* 100 Trapx 04 Instruction       */
        dc.l    _Trapx05Handler                  /* 101 Trapx 05 Instruction       */
        dc.l    _Trapx06Handler                  /* 102 Trapx 06 Instruction       */
        dc.l    _Trapx07Handler                  /* 103 Trapx 07 Instruction       */
        dc.l    _Trapx08Handler                  /* 104 Trapx 08 Instruction       */
        dc.l    _Trapx09Handler                  /* 105 Trapx 09 Instruction       */
        dc.l    _Trapx10Handler                  /* 106 Trapx 10 Instruction       */
        dc.l    _Trapx11Handler                  /* 107 Trapx 11 Instruction       */
        dc.l    _Trapx12Handler                  /* 108 Trapx 12 Instruction       */
        dc.l    _Trapx13Handler                  /* 109 Trapx 13 Instruction       */
        dc.l    _Trapx14Handler                  /* 110 Trapx 14 Instruction       */
        dc.l    _Trapx15Handler                  /* 111 Trapx 15 Instruction       */
        dc.l    _DummyHandler                    /* 112  */
        dc.l    _DummyHandler                    /* 113  */
        dc.l    _DummyHandler                    /* 114  */
        dc.l    _DummyHandler                    /* 115  */
        dc.l    _DummyHandler                    /* 116  */
        dc.l    _DummyHandler                    /* 117  */
        dc.l    _DummyHandler                    /* 118  */
        dc.l    _DummyHandler                    /* 119  */
        dc.l    _DummyHandler                    /* 120  */
        dc.l    _DummyHandler                    /* 121  */
        dc.l    _DummyHandler                    /* 122  */
        dc.l    _DummyHandler                    /* 123  */
        dc.l    _DummyHandler                    /* 124  */
        dc.l    _DummyHandler                    /* 125  */
        dc.l    _DummyHandler                    /* 126  */
        dc.l    _DummyHandler                    /* 127  */
        dc.l    _DummyHandler                    /* 128  */
        dc.l    _DummyHandler                    /* 129  */
        dc.l    _DummyHandler                    /* 130  */
        dc.l    _DummyHandler                    /* 131  */
        dc.l    _DummyHandler                    /* 132  */
        dc.l    _DummyHandler                    /* 133  */
        dc.l    _DummyHandler                    /* 134  */
        dc.l    _DummyHandler                    /* 135  */
        dc.l    _DummyHandler                    /* 136  */
        dc.l    _DummyHandler                    /* 137  */
        dc.l    _DummyHandler                    /* 138  */
        dc.l    _DummyHandler                    /* 139  */
        dc.l    _DummyHandler                    /* 140  */
        dc.l    _DummyHandler                    /* 141  */
        dc.l    _DummyHandler                    /* 142  */
        dc.l    _DummyHandler                    /* 143  */
        dc.l    _DummyHandler                    /* 144  */
        dc.l    _DummyHandler                    /* 145  */
        dc.l    _DummyHandler                    /* 146  */
        dc.l    _DummyHandler                    /* 147  */
        dc.l    _DummyHandler                    /* 148  */
        dc.l    _DummyHandler                    /* 149  */
        dc.l    _DummyHandler                    /* 150  */
        dc.l    _DummyHandler                    /* 151  */
        dc.l    _DummyHandler                    /* 152  */
        dc.l    _DummyHandler                    /* 153  */
        dc.l    _DummyHandler                    /* 154  */
        dc.l    _DummyHandler                    /* 155  */
        dc.l    _DummyHandler                    /* 156  */
        dc.l    _DummyHandler                    /* 157  */
        dc.l    _DummyHandler                    /* 158  */
        dc.l    _DummyHandler                    /* 159  */
        dc.l    _DummyHandler                    /* 160  */
        dc.l    _DummyHandler                    /* 161  */
        dc.l    _DummyHandler                    /* 162  */
        dc.l    _DummyHandler                    /* 163  */
        dc.l    _DummyHandler                    /* 164  */
        dc.l    _DummyHandler                    /* 165  */
        dc.l    _DummyHandler                    /* 166  */
        dc.l    _DummyHandler                    /* 167  */
        dc.l    _DummyHandler                    /* 168  */
        dc.l    _DummyHandler                    /* 169  */
        dc.l    _DummyHandler                    /* 170  */
        dc.l    _DummyHandler                    /* 171  */
        dc.l    _DummyHandler                    /* 172  */
        dc.l    _DummyHandler                    /* 173  */
        dc.l    _DummyHandler                    /* 174  */
        dc.l    _DummyHandler                    /* 175  */
        dc.l    _DummyHandler                    /* 176  */
        dc.l    _DummyHandler                    /* 177  */
        dc.l    _DummyHandler                    /* 178  */
        dc.l    _DummyHandler                    /* 179  */
        dc.l    _DummyHandler                    /* 180  */
        dc.l    _DummyHandler                    /* 181  */
        dc.l    _DummyHandler                    /* 182  */
        dc.l    _DummyHandler                    /* 183  */
        dc.l    _DummyHandler                    /* 184  */
        dc.l    _DummyHandler                    /* 185  */
        dc.l    _DummyHandler                    /* 186  */
        dc.l    _DummyHandler                    /* 187  */
        dc.l    _DummyHandler                    /* 188  */
        dc.l    _DummyHandler                    /* 189  */
        dc.l    _DummyHandler                    /* 190  */
        dc.l    _DummyHandler                    /* 191  */
        dc.l    _DummyHandler                    /* 192  */
        dc.l    _DummyHandler                    /* 193  */
        dc.l    _DummyHandler                    /* 194  */
        dc.l    _DummyHandler                    /* 195  */
        dc.l    _DummyHandler                    /* 196  */
        dc.l    _DummyHandler                    /* 197  */
        dc.l    _DummyHandler                    /* 198  */
        dc.l    _DummyHandler                    /* 199  */
        dc.l    _DummyHandler                    /* 200  */
        dc.l    _DummyHandler                    /* 201  */
        dc.l    _DummyHandler                    /* 202  */
        dc.l    _DummyHandler                    /* 203  */
        dc.l    _DummyHandler                    /* 204  */
        dc.l    _DummyHandler                    /* 205  */
        dc.l    _DummyHandler                    /* 206  */
        dc.l    _DummyHandler                    /* 207  */
        dc.l    _DummyHandler                    /* 208  */
        dc.l    _DummyHandler                    /* 209  */
        dc.l    _DummyHandler                    /* 210  */
        dc.l    _DummyHandler                    /* 211  */
        dc.l    _DummyHandler                    /* 212  */
        dc.l    _DummyHandler                    /* 213  */
        dc.l    _DummyHandler                    /* 214  */
        dc.l    _DummyHandler                    /* 215  */
        dc.l    _DummyHandler                    /* 216  */
        dc.l    _DummyHandler                    /* 217  */
        dc.l    _DummyHandler                    /* 218  */
        dc.l    _DummyHandler                    /* 219  */
        dc.l    _DummyHandler                    /* 220  */
        dc.l    _DummyHandler                    /* 221  */
        dc.l    _DummyHandler                    /* 222  */
        dc.l    _DummyHandler                    /* 223  */
        dc.l    _DummyHandler                    /* 224  */
        dc.l    _DummyHandler                    /* 225  */
        dc.l    _DummyHandler                    /* 226  */
        dc.l    _DummyHandler                    /* 227  */
        dc.l    _DummyHandler                    /* 228  */
        dc.l    _DummyHandler                    /* 229  */
        dc.l    _DummyHandler                    /* 230  */
        dc.l    _DummyHandler                    /* 231  */
        dc.l    _DummyHandler                    /* 232  */
        dc.l    _DummyHandler                    /* 233  */
        dc.l    _DummyHandler                    /* 234  */
        dc.l    _DummyHandler                    /* 235  */
        dc.l    _DummyHandler                    /* 236  */
        dc.l    _DummyHandler                    /* 237  */
        dc.l    _DummyHandler                    /* 238  */
        dc.l    _DummyHandler                    /* 239  */
        dc.l    _DummyHandler                    /* 240  */
        dc.l    _DummyHandler                    /* 241  */
        dc.l    _DummyHandler                    /* 242  */
        dc.l    _DummyHandler                    /* 243  */
        dc.l    _DummyHandler                    /* 244  */
        dc.l    _DummyHandler                    /* 245  */
        dc.l    _DummyHandler                    /* 246  */
        dc.l    _DummyHandler                    /* 247  */
        dc.l    _DummyHandler                    /* 248  */
        dc.l    _DummyHandler                    /* 249  */
        dc.l    _DummyHandler                    /* 250  */
        dc.l    _DummyHandler                    /* 251  */
        dc.l    _DummyHandler                    /* 252  */
        dc.l    _DummyHandler                    /* 253  */
        dc.l    _DummyHandler                    /* 254  */
        dc.l    _DummyHandler                    /* 255  */

/*
 * Define weak symbols for four alternate interrupt vectors.
 * These will be used as the interrupt vectors for the four
 * secondary contexts.
 */
	.section .data

	.global SYM (_vector_table1)
	.weak SYM (_vector_table1)
	.set SYM (_vector_table1), SYM (_vector_table)

	.global SYM (_vector_table2)
	.weak SYM (_vector_table2)
	.set SYM (_vector_table2), SYM (_vector_table)

	.global SYM (_vector_table3)
	.weak SYM (_vector_table3)
	.set SYM (_vector_table3), SYM (_vector_table)

	.global SYM (_vector_table4)
	.weak SYM (_vector_table4)
	.set SYM (_vector_table4), SYM (_vector_table)

#endif
