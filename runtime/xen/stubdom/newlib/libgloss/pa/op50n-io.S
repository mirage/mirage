/* op50n-io.S -- low-level I/O routines for the Oki OP50N eval board.
 *
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

mon_start       .EQU    0xd0000000
where_dp        .EQU    mon_start+4*4
where_ci        .EQU    mon_start+14*4
where_co        .EQU    mon_start+15*4
where_read	.EQU	mon_start+22*4
where_write	.EQU	mon_start+23*4

/* 
 *int c = inbyte(wait);
 */
	.space $TEXT$
	.align 4
        .EXPORT inbyte,CODE,ARGW0=GR,RTNVAL=GR
inbyte
	.PROC
	.CALLINFO CALLER,FRAME=64,SAVE_RP
	.ENTRY
        stw     %r2,-20(0,%r30)
        ldo     64(%r30),%r30
        stw     %r27,-56(0,%r30) 	; save my dp
 	ldil    l%where_dp,%r27    	; load monitors dp
	ldw	r%where_dp(0,%r27),%r27
	ldil	l%where_ci,%r1
	ldw	r%where_ci(0,%r1),%r1
        ble     0(0,%r1)
        copy    %r31,%r2
        ldw     -56(0,%r30),%r27 	; load my dp
        ldw     -84(0,%r30),%r2
        ldo     -64(%r30),%r30
        bv      %r0(%r2)
	nop
        .EXIT
        .PROCEND
 
/* int c = outbyte(c);
*/
        .EXPORT outbyte,CODE,ARGW0=GR,RTNVAL=GR
outbyte
        .PROC
        .CALLINFO CALLER,FRAME=64,SAVE_RP
        .ENTRY
        stw     %r2,-20(0,%r30)
        ldo     64(%r30),%r30
        stw     %r27,-56(0,%r30) 	; save my dp
 	ldil    l%where_dp,%r27    	; load monitors dp
	ldw	r%where_dp(0,%r27),%r27
	ldil	l%where_co,%r1
	ldw	r%where_co(0,%r1),%r1
        ble     0(0,%r1)
        copy    %r31,%r2
        ldw     -56(0,%r30),%r27 	; load my dp
        ldw     -84(0,%r30),%r2
        ldo     -64(%r30),%r30
        bv      %r0(%r2)
	nop
        .EXIT
        .PROCEND

#if 0
/* cnt = read(fd, bufp, cnt);
*/
	.EXPORT	read,CODE,ARGW0=NO,ARGW1=NO,ARGW2=NO,ARGW3=NO,RTNVAL=NO
read
	.PROC
	.CALLINFO FRAME=64,CALLS,SAVE_RP
	.ENTRY
	stw	%r2,-20(0,%r30)
	ldo	64(%r30),%r30
	stw	%dp,-56(0,%r30)	; save my dp
	ldil	l%where_dp,%dp	; load monitors dp
	ldw	r%where_dp(0,%dp), %dp
	ldil	l%where_read,%r1
	ldw	r%where_read(0,%r1), %r1
	ble	0(0,%r1)
	copy	%r31,%r2
	ldw	-56(0,%r30),%dp	; load my dp
	ldw	-84(0,%r30),%r2
	bv	%r0(%r2)
	ldo	-64(%r30),%r30
	.EXIT
	.PROCEND

/* cnt = write(fd, bufp, cnt);
*/
	.EXPORT	write,CODE,ARGW0=NO,ARGW1=NO,ARGW2=NO,ARGW3=NO,RTNVAL=NO
write
	.PROC
	.CALLINFO FRAME=64,CALLS,SAVE_RP
	.ENTRY
	stw	%r2,-20(0,%r30)
	ldo	64(%r30),%r30
	stw	%dp,-56(0,%r30)	; save my dp
	ldil	l%where_dp,%dp	; load monitors dp
	ldw	r%where_dp(0,%dp), %dp
	ldil	l%where_write,%r1
	ldw	r%where_write(0,%r1), %r1
	ble	0(0,%r1)
	copy	%r31,%r2
	ldw	-56(0,%r30),%dp	; load my dp
	ldw	-84(0,%r30),%r2
	bv	%r0(%r2)
	ldo	-64(%r30),%r30
	.EXIT
	.PROCEND
#endif
