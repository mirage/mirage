/* This is a simple version of setjmp and longjmp for iq2000. */


/* int setjmp (jmp_buf);  */
	.globl	setjmp
	.ent	setjmp
setjmp:
	sw	r16,0(r4)	/* rs0 */
	sw	r17,4(r4)	/* rs1 */
	sw	r18,8(r4)	/* rs2 */
	sw	r19,12(r4)	/* rs3 */
	sw	r20,16(r4)	/* rs4 */
	sw	r21,20(r4)	/* rs5 */
	sw	r22,24(r4)	/* rs6 */
	sw	r23,28(r4)	/* rs7 */
	sw	r30,32(r4)	/* rs8 */

	sw	r29,36(r4)
	sw	r31,40(r4)

	move	r2,r0

	j	r31

	.end	setjmp

/* volatile void longjmp (jmp_buf, int);  */
	.globl	longjmp
	.ent	longjmp
longjmp:
	lw	r16,0(r4)	/* rs0 */
	lw	r17,4(r4)	/* rs1 */
	lw	r18,8(r4)	/* rs2 */
	lw	r19,12(r4)	/* rs3 */
	lw	r20,16(r4)	/* rs4 */
	lw	r21,20(r4)	/* rs5 */
	lw	r22,24(r4)	/* rs6 */
	lw	r23,28(r4)	/* rs7 */
	lw	r30,32(r4)	/* rs8 */

	lw	r29,36(r4)
	lw	r31,40(r4)

	bne	r5,r0,1f
	li	r5,1
1:
	move	r2,r5

	j	r31

	.end longjmp
