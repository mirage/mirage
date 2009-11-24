/* setjmp/longjmp routines.
 *
 * Written by Michael Hayes <m.hayes@elec.canterbury.ac.nz>.
 *
 * The author hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

	.sect .text
	.global setjmp
	.global longjmp

setjmp:
	pop	r1	   
	ldi	sp, ar0
#ifndef _REGPARM
	ldi	*ar0, ar2	
#endif

	sti	r4, *ar2++
	sti	r5, *ar2++
	stf	r6, *ar2++
	stf	r7, *ar2++
#ifdef _TMS320C4x
	sti	r8, *ar2++
#endif
	sti	ar3, *ar2++
	sti	ar4, *ar2++
	sti	ar5, *ar2++
	sti	ar6, *ar2++
	sti	ar7, *ar2++
	bd	r1	
	sti	r1, *ar2++ 
	sti	ar0, *ar2  
	ldi	0, r0	

	
longjmp:
#ifndef _REGPARM
	ldi	sp, ar0
	ldi	*-ar0(1), ar2  
	ldi	*-ar0(2), r0   
	ldiz	1, r0	
#else
	ldi	r2, r0	 
	ldiz	1, r0	
#endif
 
	ldi	*ar2++, r4 
	ldi	*ar2++, r5 
	ldf	*ar2++, r6 
	ldf	*ar2++, r7
#ifdef _TMS320C4x
	ldi	*ar2++, r8
#endif
	ldi	*ar2++, ar3
	ldi	*ar2++, ar4 
	ldi	*ar2++, ar5 
	ldi	*ar2++, ar6 
	ldi	*ar2++, ar7 
	ldi	*ar2++, r1 
	ldi	*ar2, sp	
    
	b	 r1	
	.end
	
	

