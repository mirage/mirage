/* (C) Copyright IBM Corp. 2005, 2006
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
notice, this list of conditions and the following disclaimer in the 
documentation and/or other materials provided with the distribution.
    * Neither the name of IBM nor the names of its contributors may be 
used to endorse or promote products derived from this software without 
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/

/* crt0.S - entry function for C Runtime.
 *
 * With _STD_MAIN switch, the crt0.S will be compiled to crt2.o.
 * The crt2.o sets up a C99-style interface for the SPU application's
 * main() function, including a local copy of argv strings.
 * 
 * The number of argument strings is passed in R3.  The size and EA 
 * location of the argument vector region is passed in R4.  Once the
 * argv region is copied to the highest range of LS, and $SP is set 
 * just below it.
 *
 * Without _STD_MAIN, the crt0.S is compiled to crt1.o. 
 * The crt1.o prepares the entry for an SPU module. The main() function
 * is called with different parameter list: spu_id, param and env 
 * are passed by R3, R4 and R5 respectively.
 */

#ifdef _STD_MAIN
#define MFC_TAG_UPDATE_ALL 	2
#define MFC_GET_CMD		0x40
#define TAGID			0
#define TAGMASK			1
#endif

.comm __ea_local_store,16,16

.text
.global _start
.type _start, @function
	
_start:
	/* Save the local store base from $6.  */
	stqr $6, __ea_local_store

#ifdef _STD_MAIN
	/* 
 	 * Copy the argument vector region from EA to LS.  The DMA
	 * parameters are passed in R4:
	 *
 	 *        +-------+-------+-------+-------+
	 *     R4 |   LS  | EA-HI | EA-LO | SIZE  |
	 *        +-------+-------+-------+-------+
	 *  word     0       1       2       3
	 *
 	 * By the end of this sequence, the prefered slot (word 0) of
	 * R4 will contain the LS offset of argv region, which also
	 * serves as the base offset for $SP.
	 */
	wrch	$MFC_LSA, $4
	rotqbyi	$4, $4, 4
	wrch	$MFC_EAH, $4
	rotqbyi	$4, $4, 4
	wrch	$MFC_EAL, $4
	rotqbyi	$4, $4, 4
	wrch	$MFC_Size, $4
	rotqbyi	$4, $4, 4
	il	$LR, TAGID
	wrch	$MFC_TagID, $LR

	/* Issue MFC_GET_CMD, then wait for transfer of argument
	 * vector region to complete.
	 */
	il	$LR, MFC_GET_CMD
	wrch	$MFC_Cmd, $LR
	il	$LR, TAGMASK
	wrch	$MFC_WrTagMask, $LR
	il	$LR, MFC_TAG_UPDATE_ALL
	wrch	$MFC_WrTagUpdate, $LR
	rdch	$LR, $MFC_RdTagStat
#endif

	/* Save parameter list of main function to the non-volatile
	 * registers. spu_thread module has three parameters, while
	 * spulet only has two.
	 */
	ori     $80, $3, 0
	ori     $81, $4, 0
#ifndef _STD_MAIN
	ori 	$82, $5, 0
#endif

	/* The Link Register is initialized to NULL.
	 */
	il	$LR, 0

#ifdef _STD_MAIN	
	/* For spulet, initialize stack pointer just below the argv region.
	 */
	ai	$SP,$4,-16
#else
	/* For spe_thread module, the stack pointer is initialized 
	 * below the area where __stack points to.
	 */
	ila     $SP,__stack
#endif
	/* Initialize back chain to NULL.
	 */
	stqd    $LR,0($SP)

	/* Allocate 2 slots for stack frame.
	 */
	stqd    $SP,-32($SP)
	ai      $SP,$SP,-32

	/* Save the Link Register in Link Register Save Area.
	 */
	stqd	$LR,16($SP)

	/* Calculate stack size.
	 */
	ila 	$3,_end
	sf	$3,$3,$SP
	rotqbyi	$3,$3,12

        /* The BE Linux ABI passes the stack size in $2, or use
         * the default if $2 == 0.
         */
	rotqbyi	$4,$2,12
	ceqi	$5,$4,0
	selb	$3,$4,$3,$5
	fsmbi	$4,3840
	selb	$SP,$SP,$3,$4

	/* Call the _init function.
	 */
	brsl	$LR, _init
	
	/* Call the _fini function at exit time.
	 */
	ila	$3, _fini
	brsl	$LR, atexit

	ori     $3,$80,0
	ori     $4,$81,0	
#ifndef _STD_MAIN
	ori	$5,$82,0
#endif

	/* Call the programs main.
	 */
	brsl	$LR, main
	
	/* Call exit.
	 */
	brsl	$LR, exit

