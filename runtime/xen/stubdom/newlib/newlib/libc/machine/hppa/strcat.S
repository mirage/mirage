/*
 *  (c) Copyright 1986 HEWLETT-PACKARD COMPANY
 *
 *  To anyone who acknowledges that this file is provided "AS IS"
 *  without any express or implied warranty:
 *      permission to use, copy, modify, and distribute this file
 *  for any purpose is hereby granted without fee, provided that
 *  the above copyright notice and this notice appears in all
 *  copies, and that the name of Hewlett-Packard Company not be
 *  used in advertising or publicity pertaining to distribution
 *  of the software without specific, written prior permission.
 *  Hewlett-Packard Company makes no representations about the
 *  suitability of this software for any purpose.
 */

/* HPUX_ID:	@(#) $Revision: 1.1 $	*/
/*
 * strcat(s1, s2)
 *
 * Concatenate s2 on the end of s1.  S1's space must be large enough.
 * Return s1.
 */
#include "DEFS.h"

#define	d_addr  r26
#define	s_addr  r25
#define	tmp6    r24
#define	tmp1    r19
#define	tmp2    r20
#define	tmp3    r21
#define	tmp4    r22
#define	tmp5	arg3
#define	save	r1


ENTRY(strcat)

	comb,=		r0,s_addr,done	/* quit if s2=NULL */
        copy      d_addr,ret0          /* The return value is the value of d_addr. DELAY SLOT*/

/* First look for end of s1 (d_addr) */

        extru       d_addr,31,2,tmp1   /* Extract the low two bits of the dest address. */
	combt,=		tmp1,r0,dont_mask
	dep		0,31,2,d_addr	/*set word alignment */
	ldwm		4(d_addr),tmp2
	sh3add		tmp1,r0,save	/* build mask based on tmp1 */
	mtctl		save,11
	zvdepi		-2,32,save
	or		save,tmp2,tmp2
	uxor,nbz	tmp2,r0,save
search:
	b,n		found_end	/* nullified under uxor conditions above and below */
dont_mask:
	ldwm		4(d_addr),tmp2
	comib,tr	r0,r0,search
	uxor,nbz	tmp2,r0,save

found_end:				/* at this point d_addr points to word */
	extru,<>	save,7,8,r0	/* following word with null */
	addib,tr,n	-4,d_addr,begin_copy	/*set d_addr to end of s1 */
	extru,<>	save,15,8,r0
	addib,tr,n	-3,d_addr,begin_copy
	extru,<>	save,23,8,r0
	addi		-1,d_addr,d_addr
	addi		-1,d_addr,d_addr


begin_copy:

        extru       s_addr,31,2,tmp1   /* Extract the low two bits of the source address. */
        extru       d_addr,31,2,tmp6   /* Extract the low two bits of the destination address. */
        sub,=       tmp6,tmp1,tmp3     /* Compute the shift quantity and don't branch if tmp6=tmp1. */
        b           not_aligned        /* Not_aligned says that shifts Will be needed. */
        dep         0,31,2,s_addr      /* Compute the word address of the source.  DELAY SLOT. */
/* aligned */

	combt,=		tmp6,r0,skip_mask
        ldwm        	4(0,s_addr),tmp1   /* tmp1 = *s_addr   s_addr += 4 (DELAY SLOT) */
	sh3add		tmp6,r0,save
	mtctl		save,r11
	zvdepi		-2,32,save
	or		save,tmp1,tmp1
	uxor,nbz	tmp1,r0,save
	b,n		first_null	/* special case: null in first word */
	b,n		skip_mask2

chunks:
	b,n		null_found	/* delay slot for uxor below */

skip_mask2:
	stbys,b,m	tmp1,4(d_addr)
	ldwm		4(s_addr),tmp1
skip_mask:
	comib,tr	0,0,chunks
	uxor,nbz	tmp1,r0,save

/* Begin non_aligned code.  */

not_aligned:
        sh3add,>=       tmp3,r0,tmp4        /* compute the shift amt.and skip load if tmp6 > tmp1. */
        ldwm         	4(0,s_addr),tmp1    /* load up the first word from the source. tmp1 = *s_addr++ */
        ldwm        	4(0,s_addr),tmp2    /* get either first or second word from source.  */
	combt,=		tmp6,r0,chunk2      /* don't mask if whole word is valid */
        mtctl        	tmp4,11             /* load the shift count into cr11 = shift count register. */
        vshd        	tmp1,tmp2,tmp3      /* position data !  (delay slot) */
	sh3add		tmp6,r0,save  	    /* setup r1 */
	mtctl		save,r11	    /* set-up cr11 for mask */
	zvdepi		-2,32,save
	or		save, tmp3, tmp3
	uxor,nbz	tmp3,r0,save
	b,n		first_null2
	b		did_mask
        mtctl        	tmp4,11            /* re-load the shift count into cr11 */

chunk2:
	vshd		tmp1,tmp2,tmp3
	uxor,nbz	tmp3, r0, save
	b,n		null_found
did_mask:
        stbys,b,m   	tmp3,4(0,d_addr)    /* store !  */

        ldwm        	4(0,s_addr),tmp1    /* get next word !  */
        vshd        	tmp2,tmp1,tmp3      /* position data !  */
	uxor,nbz	tmp3, r0, save
	b,n		null_found
	stwm		tmp3,4(d_addr)
	comib,tr	0,0,chunk2
	ldwm		4(s_addr),tmp2


null_found:				/* adjust d_addr and store final word */

	extru,<>	save,7,8,r0
	addib,tr,n	1,d_addr,store_final
	extru,<>	save,15,8,r0
	addib,tr,n	2,d_addr,store_final
	extru,<> 	save,23,8,r0
	addib,tr	3,d_addr,store_final2
	bv		0(r2)
	stw		save,0(d_addr)

store_final:
	bv		0(r2)
store_final2:
	stbys,e		save,0(d_addr) 	/* delay slot */

first_null:			/* null found in first word of aligned (wrt d_addr) */
	addi		-4,s_addr,s_addr
	ldbx		tmp6(s_addr),tmp4
	add		tmp6,s_addr,s_addr
	comib,=		0,tmp4,done
	stbs,ma		tmp4,1(d_addr)
	ldbs		1(s_addr),tmp4
	comib,=		0,tmp4,done
	stbs,ma		tmp4,1(d_addr)
	bv		0(r2)		/* done */
	stbs		0,0(d_addr)

first_null2:	/* null found in first word of non-aligned (wrt d_addr) */
	addibt,=	-1,tmp6,check3	/* check last 3 bytes of word */
	extru   	save,15,8,tmp4
	addibt,=,n	-1,tmp6,check2	/* check last 2 bytes */
	bv		0(r2)
	stbys,b		save, 0(d_addr)

check3:
	combt,=		tmp4,r0,done
	stbs,ma		tmp4,1(d_addr)
check2:
	extru,<>	save,23,8,tmp4
	bv		0(r2)
	stbs,ma		tmp4,1(d_addr)
	bv		0(r2)
	stbs		r0,0(d_addr)

done:
EXIT(strcat)
