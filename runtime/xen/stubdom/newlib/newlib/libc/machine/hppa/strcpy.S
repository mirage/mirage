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

/*
	A faster strcpy.

	by

	Jerry Huck (aligned case)
	Daryl Odnert (equal-alignment case)
	Edgar Circenis (non-aligned case)
*/
/*
 * strcpy(s1, s2)
 *
 * Copy string s2 to s1.  s1 must be large enough.
 * return s1
 */

#include "DEFS.h"

#define	d_addr		r26
#define	s_addr		r25
#define	tmp6		r24
#define	tmp1		r19
#define evenside	r19
#define	tmp2		r20
#define oddside		r20
#define	tmp3		r21
#define	tmp4		r22
#define	tmp5		arg3
#define	save		r1


ENTRY(strcpy)
/* Do some quick alignment checking on and fast path both word aligned */
        extru,<>   s_addr,31,2,tmp6    /*Is source word aligned? */
        ldwm       4(0,s_addr),oddside /*Assume yes and guess that it
                                          is double-word aligned. */
        dep,=      d_addr,29,2,tmp6    /*Is target word aligned? */
        b          case_analysis
	copy       d_addr,ret0
/* Both are aligned.  First source word already loaded assuming that
   source was oddword aligned.  Fall through (therefore fastest) code
   shuffles the registers to join the main loop */
bothaligned:
	bb,>=    s_addr,29,twoatatime  /*Branch if source was odd aligned*/
	uxor,nbz oddside,r0,save

/* Even aligned source.  save holds that operand.
   Do one iteration of the main copy loop juggling the registers to avoid
   one copy. */
	b,n	 nullfound
	ldwm     4(s_addr),oddside
	stwm     save,4(d_addr)
	uxor,nbz oddside,r0,save
	b,n      nullfound
        ldwm     4(s_addr),evenside
        stwm     oddside,4(d_addr)
        uxor,nbz evenside,r0,save
        b,n      nullfound
        ldwm     4(s_addr),oddside

/* Main loop body.  Entry expects evenside still to be stored, oddside
   just loaded. */
loop:
        stwm     evenside,4(d_addr)
        uxor,nbz oddside,r0,save

/* mid loop entry */
twoatatime:
        b,n      nullfound
        ldwm     4(s_addr),evenside
        stwm     oddside,4(d_addr)
        uxor,sbz evenside,r0,save
        b        loop
        ldwm     4(s_addr),oddside

/* fall through when null found in evenside.  oddside actually loaded */
nullfound:				/* adjust d_addr and store final word */

	extru,<>	save,7,8,r0         /* pick up leftmost byte */
	addib,tr,n	1,d_addr,store_final
	extru,<>	save,15,8,r0
	addib,tr,n	2,d_addr,store_final
	extru,<> 	save,23,8,r0
	addib,tr	3,d_addr,store_final2
	bv		0(rp)
	stw		save,0(d_addr)

store_final:
	bv		0(rp)
store_final2:
	stbys,e		save,0(d_addr) 	/* delay slot */
	
case_analysis:

        blr         tmp6,r0
        nop

	/* NOTE: the delay slots for the non-aligned cases load a   */
	/* shift quantity which is TGT-SRC into tmp3.               */
        /* Note also, the case for both strings being word aligned  */
	/* is already checked before the BLR is executed, so that   */
	/* case can never occur.                                    */

                                       /* TGT SRC */
        nop                            /* 00  00  can't happen */
        nop
        b           neg_aligned_copy   /* 00  01  */
	ldi         -1,tmp3            /* load shift quantity. delay slot */
        b           neg_aligned_copy   /* 00  10  */
	ldi         -2,tmp3            /* load shift quantity. delay slot */
        b           neg_aligned_copy   /* 00  11  */
	ldi         -3,tmp3            /* load shift quantity. delay slot */
        b           pos_aligned_copy0  /* 01  00  */
	ldi         1,tmp3            /* load shift quantity. delay slot */
        b           equal_alignment_1  /* 01  01  */
        ldbs,ma     1(s_addr),tmp1
        b           neg_aligned_copy   /* 01  10  */
	ldi         -1,tmp3            /* load shift quantity. delay slot */
        b           neg_aligned_copy   /* 01  11  */
	ldi         -2,tmp3            /* load shift quantity. delay slot */
        b           pos_aligned_copy0  /* 10  00  */
	ldi         2,tmp3            /* load shift quantity. delay slot */
        b           pos_aligned_copy   /* 10  01  */
	ldi         1,tmp3            /* load shift quantity. delay slot */
        b           equal_alignment_2  /* 10  10  */
        ldhs,ma     2(s_addr),tmp1
        b           neg_aligned_copy   /* 10  11  */
	ldi         -1,tmp3            /* load shift quantity. delay slot */
        b           pos_aligned_copy0  /* 11  00  */
	ldi         3,tmp3            /* load shift quantity. delay slot */
        b           pos_aligned_copy   /* 11  01  */
	ldi         2,tmp3            /* load shift quantity. delay slot */
        b           pos_aligned_copy   /* 11  10  */
	ldi         1,tmp3            /* load shift quantity. delay slot */
        ldbs,ma     1(s_addr),tmp1     /* 11  11  */
        comiclr,<>  r0,tmp1,r0
        bv          0(rp)              /* return if 1st byte was null */
        stbs,ma     tmp1,1(d_addr)     /* store a byte to dst string  */
        b           bothaligned       /* can now goto word_aligned   */
        ldwm        4(s_addr),oddside     /* load next word of source    */

equal_alignment_1:
        comiclr,<>  r0,tmp1,r0      /* nullify next if tmp1 <> 0  */
        bv          0(rp)           /* return if null byte found  */
        stbs,ma     tmp1,1(d_addr)  /* store a byte to dst string */
        ldhs,ma     2(s_addr),tmp1  /* load next halfword         */
equal_alignment_2:
        extru,<>    tmp1,23,8,tmp6  /* look at left byte of halfword */
        bv          0(rp)           /* return if 1st byte was null */
        stbs,ma     tmp6,1(d_addr)
        extru,<>    tmp1,31,8,r0
        bv          0(rp)           /* return if 2nd byte was null */
        stbs,ma     tmp1,1(d_addr)
        b           bothaligned
        ldwm        4(s_addr),oddside  /* load next word              */

/* source and destination are not aligned, so we do it the hard way. */

/* target alignment is greater than source alignment */
pos_aligned_copy0:
	addi		-4,s_addr,s_addr
pos_aligned_copy:
        extru       d_addr,31,2,tmp6   /* Extract low 2 bits of the dest addr */
        extru       s_addr,31,2,tmp1   /* Extract low 2 bits of the src addr */
        dep         r0,31,2,s_addr     /* Compute word address of the source. */
        sh3add		tmp3,r0,tmp4        /* compute shift amt */
        ldwm        	4(0,s_addr),tmp2    /* get 1st source word */
	sh3add		tmp1,r0,save  	    /* setup mask shift amount */
	mtctl		save,r11	    /* set-up cr11 for mask */
	zvdepi		-2,32,save	    /* create mask */
	or		save,tmp2,tmp2	    /* mask unused bytes in src */
	ldi		-1,tmp1		    /* load tmp1 with 0xffffffff */
        mtctl        	tmp4,r11            /* shift count -> shift count reg */
        vshd        	tmp1,tmp2,tmp3      /* position data ! */
	uxor,nbz	tmp3,r0,save
	b,n		first_null
	uxor,nbz	tmp2,r0,save
	b		nullfound1
        mtctl        	tmp4,r11            /* re-load shift cnt (delay slot) */
	b		loop_entry
        ldwm        	4(0,s_addr),tmp1    /* get next word. delay slot */

neg_aligned_copy:
        extru       d_addr,31,2,tmp6   /* Extract low 2 bits of the dest addr */
	extru	    s_addr,31,2,tmp2   /* Extract low 2 bits of the src addr */
        dep         r0,31,2,s_addr     /* Compute word address of the source. */
        sh3add		tmp3,r0,tmp4        /* compute shift amt */
        ldwm         	4(0,s_addr),tmp1    /* load first word from source. */
/* check to see if next word can be read safely */
	sh3add		tmp2,r0,save
        mtctl        	save,r11            /* shift count -> shift count reg */
	zvdepi		-2,32,save
	or		save, tmp1, tmp1
	uxor,nbz	tmp1,r0,save	    /* any nulls in first word? */
	b		first_null0
	mtctl		tmp4,r11
        ldwm        	4(0,s_addr),tmp2    /* load second word from source */
	combt,=		tmp6,r0,chunk1      /* don't mask if whole word valid */
        vshd        	tmp1,tmp2,tmp3      /* position data ! */
	sh3add		tmp6,r0,save  	    /* setup r1 */
	mtctl		save,r11	    /* set-up cr11 for mask */
	zvdepi		-2,32,save
	or		save, tmp3, tmp3
	uxor,nbz	tmp3,r0,save
	b,n		first_null
	uxor,nbz	tmp2,r0,save
	b		nullfound1
        mtctl        	tmp4,r11            /* re-load shift cnt (delay slot) */
	b		loop_entry
        ldwm        	4(0,s_addr),tmp1    /* get next word. delay slot */

chunk1:
	uxor,nbz	tmp2,r0,save
	b		nullfound0
	vshd		tmp1,tmp2,tmp3
did_mask:
        ldwm        	4(0,s_addr),tmp1    /* get next word !  */
loop_entry:
        stbys,b,m   	tmp3,4(0,d_addr)    /* store !  */

	uxor,nbz	tmp1, r0, save
	b		nullfound2
        vshd        	tmp2,tmp1,tmp3      /* position data !  */
	ldwm		4(s_addr),tmp2
	stwm		tmp3,4(d_addr)
	uxor,sbz	tmp2,r0,save
	b		did_mask
nullfound0:
	vshd		tmp1,tmp2,tmp3	    /* delay slot */
	uxor,nbz	tmp3,r0,save
	b,n		nullfound
nullfound1:
	stbys,b,m	tmp3,4(0,d_addr)
	b		nullfound
	vshd		tmp2,r0,save	    /* delay slot */

nullfound2:
	uxor,nbz	tmp3,r0,save
	b,n		nullfound
	stwm		tmp3,4(d_addr)
	b		nullfound
	/* notice that delay slot is in next routine */

first_null0:	/* null found in first word of non-aligned (wrt d_addr) */
	vshd		tmp1,r0,save	    /* delay slot */
	combt,=		tmp6,r0,check4
	extru		save,7,8,tmp4
first_null:
	addibt,=	-1,tmp6,check3	/* check last 3 bytes of word */
	extru   	save,15,8,tmp4
	addibt,=,n	-1,tmp6,check2	/* check last 2 bytes */
	bv		0(rp)		/* null in last byte--store and exit */
	stbys,b		save, 0(d_addr)

check4:
	combt,=		tmp4,r0,done
	stbs,ma		tmp4,1(d_addr)
	extru,<>	save,15,8,tmp4
check3:
	combt,=		tmp4,r0,done
	stbs,ma		tmp4,1(d_addr)
check2:
	extru,<>	save,23,8,tmp4
	bv		0(rp)
	stbs,ma		tmp4,1(d_addr)
	bv		0(rp)
	stbs		r0,0(d_addr)

done:    
EXIT(strcpy)
