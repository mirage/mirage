/* mc68681reg.h -- Motorola mc68681 DUART register offsets.
 * Copyright (c) 1995 Cygnus Support
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

#define DUART_MR1A	0x00		/* Mode Register A */
#define DUART_MR1A	0x00		/* Mode Register A */
#define DUART_SRA	0x01		/* Status Register A */
#define DUART_CSRA	0x01		/* Clock-Select Register A */
#define DUART_CRA	0x02		/* Command Register A */
#define DUART_RBA	0x03		/* Receive Buffer A */
#define DUART_TBA	0x03		/* Transmit Buffer A */
#define DUART_IPCR	0x04		/* Input Port Change Register */
#define DUART_ACR	0x04    	/* Auxiliary Control Register */
#define DUART_ISR	0x05		/* Interrupt Status Register */
#define DUART_IMR	0x05		/* Interrupt Mask Register */
#define DUART_CUR	0x06		/* Counter Mode: current MSB */
#define DUART_CTUR	0x06		/* Counter/Timer upper reg */
#define DUART_CLR	0x07		/* Counter Mode: current LSB */
#define DUART_CTLR	0x07		/* Counter/Timer lower reg */
#define DUART_MR1B	0x08		/* Mode Register B */
#define DUART_MR2B	0x08    	/* Mode Register B */
#define DUART_SRB	0x09		/* Status Register B */
#define DUART_CSRB	0x09		/* Clock-Select Register B */
#define DUART_CRB	0x0A		/* Command Register B */
#define DUART_RBB	0x0B		/* Receive Buffer B */
#define DUART_TBB	0x0B		/* Transmit Buffer A */
#define DUART_IVR	0x0C		/* Interrupt Vector Register */
#define DUART_IP	0x0D		/* Input Port */
#define DUART_OPCR	0x0D		/* Output Port Configuration Reg. */
#define DUART_STRTCC	0x0E		/* Start-Counter command */
#define DUART_OPRSET	0x0E		/* Output Port Reg, SET bits */
#define DUART_STOPCC	0x0F		/* Stop-Counter command */
#define DUART_OPRRST	0x0F		/* Output Port Reg, ReSeT bits */
