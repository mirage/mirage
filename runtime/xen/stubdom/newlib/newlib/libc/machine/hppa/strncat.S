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

/*HPUX_ID:	@(#) $Revision: 1.1 $	*/
/* strncat(s1,s2,n) : concatonate at most n characters from s2 onto s1 */

#include "DEFS.h"

#define	d_addr  r26
#define	s_addr  r25
#define	count   r24
#define	tmp1    r19
#define	tmp2    r20
#define	tmp3    r21
#define	tmp4    r22
#define	tmp5	arg3
#define tmp6	r31
#define	save	r1
#define tmp7	ret1	/* source offset-- reset to orig source addr if not aligned */


ENTRY(strncat)

	comb,=		r0,s_addr,quit	/* quit if s2=NULL */
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
        addibt,<,n  -4,count,byteloop     /* If count is <= 4 don't get fancy.*/

        extru       s_addr,31,2,tmp4   /* Extract the low two bits of the source address.*/
        extru       d_addr,31,2,tmp5   /* Extract the low two bits of the destination address.*/
        add         count,tmp5,count   /* pre increment the count by the byte address so that the count is*/
	copy		s_addr,tmp6	/* save original s_addr in case we find null in first word */
	copy	     s_addr, tmp7	/* save s_addr in case we find null before first store */
        comb,<>       tmp5,tmp4,not_aligned /* branch if tmp5<>tmp4. */
        dep         0,31,2,s_addr      /* Compute the word address of the source.  DELAY SLOT.*/
/* aligned*/
	combt,=		tmp5,r0,skip_mask
        ldwm        4(0,s_addr),tmp1   /* tmp1 = *s_addr   s_addr += 4 (DELAY SLOT)*/
	sh3add		tmp5,r0,save	/* compute mask in save*/
	mtctl		save,11
	zvdepi		-2,32,save
	or		save,tmp1,tmp1  /* or mask with data*/
	uxor,nbz	tmp1,r0,save 	/* check for null*/
	b,n		null1
	addibt,<	-4,count,back_porch
        stbys,b,m   tmp1,4(0,d_addr)   /* store word (delay slot)*/

chunks:
	ldwm		4(0,s_addr),tmp1 /* get a word*/

skip_mask:
	uxor,nbz	tmp1,r0,save 	/* check for null*/
	b,n		align_null1
	addibf,<	-4,count,chunks
        stbys,b,m   tmp1,4(0,d_addr)   /* store word (delay slot)*/

back_porch:				   /* last word to store*/
         addibt,=,n  4,count,done       /* if count = 0 we're, of course, done !*/
         ldws        0(s_addr),tmp1     /* load up the back_porch*/
	 sh3add		count,r0, save	/* setup right mask based on count*/
	 mtctl		save,r11
	 zvdepi		-2,32,save	/*save now has left-hand mask*/
	 uaddcm		r0,save,save	/*form right hand mask */
	 or		tmp1,save,tmp1	/*and insert data*/
	 uxor,nbz	tmp1,r0,save	/* check for null*/
	 b,n 		null2
         add         d_addr,count,d_addr/* final store address  is +1 too high !*/
	 b		done
	 stbys,e	tmp1,0(d_addr)	/* done */

/* Begin non_aligned code. */
not_aligned:
        sub,>=       tmp5,tmp4,tmp6     /* compute the shift amt.and skip load if tmp5 > tmp4.*/
        ldwm         4(0,s_addr),tmp1   /* load up the first word from the source. tmp1 = *s_addr++*/
        zdep         tmp6,28,29,tmp4    /* compute the number of bits to shift */
        mtctl        tmp4,11            /* load the shift count into cr11 = shift count register.*/
        addibt,<,n   -4,count,chkchnk2 /* first step in pre adjustment of count for looping.*/

        ldwm        4(0,s_addr),tmp2    /* get either first or second word from source. */
	combt,=		tmp5,r0,skip_mask4 /* don't mask if whole word is valid*/
        vshd        tmp1,tmp2,tmp3      /* position data !  (delay slot)*/
	sh3add		tmp5,r0,save	/* setup r1*/
	mtctl		save,r11	/* setup mask in save*/
	zvdepi		-2,32,save
	or		save, tmp3, tmp3
        mtctl           tmp4,11            /* re-load the shift count into cr11 */

skip_mask4:
	uxor,nbz	tmp3, r0, save
	b,n		null4		/* special case for first word */
	copy 		r0, tmp5	/* zero out tmp5 so we don't try to mask again*/
	copy		r0, tmp7	/* zero out tmp7 so we don't try to use original s_addr anymore */
	b		continue
        stbys,b,m   tmp3,4(0,d_addr)    /* store ! */

chunk2:
        ldwm        4(0,s_addr),tmp2
        vshd        tmp1,tmp2,tmp3 

skip_mask2:
	uxor,nbz	tmp3, r0, save
	b,n		null3
        stbys,b,m   tmp3,4(0,d_addr)    /* store ! */

continue:
        ldwm        4(0,s_addr),tmp1    /* get 2nd word ! */
        vshd        tmp2,tmp1,tmp3      /* position data ! */
	uxor,nbz	tmp3, r0, save
	b,n		null3

        addibf,<    -8,count,chunk2    /* If count is still >= 8 do another loop.*/
        stbys,b,m   tmp3,4(0,d_addr)    /* store !*/

chkchnk2:
        addibt,<,n  4,count,bp_0       /* if we don't have 4 bytes left then do the back porch (bp_0)*/

subchnk2: /* we have less than 8 chars to copy*/

        ldwm        4(0,s_addr),tmp2    /* get next word !*/
	combt,=		tmp5,r0,skip_mask3
        vshd        tmp1,tmp2,tmp3      /* position data !*/
	sh3add		tmp5,r0,save	/* setup r1*/
	mtctl		save,r11	/* setup mask in save*/
	zvdepi		-2,32,save
	or		save, tmp3, tmp3
	mtctl		tmp4,11		/* restore shift value again */
skip_mask3:
	uxor,nbz	tmp3,r0,save
	b,n		null3
	copy		r0,tmp5   /* zero out tmp5 so null3 does correct alignment */
	copy		r0,tmp7	  /* zero out tmp7 so we don't use orignal s_addr since no longer valid */
	b		bp_1 /* we now have less than 4 bytes to move*/
        stbys,b,m   tmp3,4(0,d_addr)    /* store !*/

bp_0:    
	copy		tmp1,tmp2	/* switch registers for shift process */
	addibt,<=,n  4,count,done        /* if count = -4 this implies that count = 0 -> done */

bp_1:
        ldwm        4(0,s_addr),tmp1    /* get final word !        */
        vshd        tmp2,tmp1,tmp3      /* position data !*/
	uxor,nbz	tmp3,r0,save	/* if no-byte-zero */
	b,n		bp_null		/* don't goto no_null-find which null instead */
no_null:
	add	    d_addr,count,d_addr	/* set up d_addr for stbys,e */
	b		done		/* were done*/
        stbys,e     tmp3,0(0,d_addr)    /* store the data !*/

/* here we do ye old byte-at-a-time moves.*/
align_null1:
	b	byteloop
	addi	-4,s_addr,s_addr
null1:
	copy		tmp6,s_addr		/* restore orig s_addr (aligned only) */
byteloop:
	addibt,=     4,count,done
null2:
        ldbs,ma     1(s_addr),tmp1
encore:
	combt,=,n	tmp1,r0, done
        stbs,ma     tmp1,1(d_addr) 
        addibf,=,n  -1,count,encore
        ldbs,ma     1(s_addr),tmp1
	b,n		done

bp_null:
	addi	-4,count,count		/* fudge count 'cause byteloop will re-increment */

null3:	/* not_aligned case reset s_addr and finish byte-wise */
	combt,=,n  r0,tmp7,null3a	/* if tmp7 is not valid address then branch below */
	b 	byteloop		  	/* otherwise reset s_addr to tmp7 and finish */
	copy 	tmp7, s_addr

null3a: /* right shift target */
	addibt,<,n  0,tmp6,null3b	/* if left shifting */
	sub	r0,tmp6,tmp6		/* do null3b code */
	addi	-4,tmp6,tmp6
	b	byteloop
	add	tmp6,s_addr,s_addr	/* reset s_addr by 4 + shift_amt */

null3b:
	subi	-8,tmp6,tmp6
	add	tmp5,tmp6,tmp6  /* adjust by the dest offset if this is our first store */
	b	byteloop
	add	tmp6,s_addr,s_addr	/* adjust s_addr by (8-shift_amt-dest_off) */

null4:
	add,>	tmp6,r0,tmp6		/* if left shift */
	b,n	null3			/* then do null3 */
	b	byteloop
	addi	-4,s_addr,s_addr	/* adj source only by 4 */
	
done:    
	bv		0(r2)
	stbs		r0,0(d_addr)
quit:
EXIT(strncat)
