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
 * strncpy(s1, s2, n)
 *
 * Copy s2 to s1, truncating or null-padding to always copy n bytes
 * return s1
 */

#include "DEFS.h"

#define	d_addr  r26
#define	s_addr  r25
#define	count   r24
#define	tmp1    r19
#define	tmp2    r20
#define	tmp3    r21
#define	tmp4    r22
#define	tmp5	arg3
#define	save	r1


ENTRY(strncpy)

	combt,=   s_addr,r0,pad_null_bytes1	/* if s2==NULL then pad nulls and exit */
        copy      d_addr,ret0          /* The return value is defined to be the value of d_addr. DELAY SLOT*/
        addibt,<,n  -4,count,byteloop     /* If count is <= 4 don't get fancy.*/

        extru       s_addr,31,2,tmp1   /* Extract the low two bits of the source address.*/
        extru       d_addr,31,2,tmp5   /* Extract the low two bits of the destination address.*/
        add         count,tmp5,count   /* pre increment the count by the byte address so that the count is*/
        comb,<>       tmp5,tmp1,not_aligned /* branch if tmp5<>tmp1. */
        dep         0,31,2,s_addr      /* Compute the word address of the source.  DELAY SLOT.*/
/* aligned*/
	combt,=		tmp5,r0,skip_mask
        ldwm        4(0,s_addr),tmp1   /* tmp1 = *s_addr   s_addr += 4 (DELAY SLOT)*/
	sh3add		tmp5,r0,save	/* compute mask in save*/
	mtctl		save,11
	zvdepi		-2,32,save
	b		skip_mask	/* don't reload tmp1*/
	or		save,tmp1,tmp1  /* or mask with data*/

chunks:
	ldwm		4(0,s_addr),tmp1 /* get a word*/

skip_mask:
	uxor,nbz	tmp1,r0,save 	/* check for null*/
	b,n		null1
	addibf,<	-4,count,chunks
        stbys,b,m   tmp1,4(0,d_addr)   /* store word (delay slot)*/

/* back_porch				   last word to store*/
         addibt,=,n  4,count,done       /* if count = 0 we're, of course, done !*/
         ldws        0(s_addr),tmp1     /* load up the back_porch*/
         add         d_addr,count,d_addr/* final store address  is +1 too high !*/
	 sh3add		count,r0, save	/* setup right mask based on count*/
	 mtctl		save,r11
	 zvdepi		-2,32,save	/*save now has left-hand mask*/
	 uaddcm		r0,save,save	/*form right hand mask */
	 or		tmp1,save,tmp1	/*and insert data*/
	 uxor,nbz	tmp1,r0,save	/* check for null*/
	 b,n 		null2
	 bv		0(r2)
	 stbys,e	tmp1,0(d_addr)	/* done */

/* Begin non_aligned code. */
not_aligned:
        sub,>=       tmp5,tmp1,tmp3     /* compute the shift amt.and skip load if tmp5 > tmp1.*/
        ldwm         4(0,s_addr),tmp1   /* load up the first word from the source. tmp1 = *s_addr++*/
        zdep         tmp3,28,29,tmp4    /* compute the number of bits to shift */
        mtctl        tmp4,11            /* load the shift count into cr11 = shift count register.*/
        addibt,<,n   -4,count,chkchnk2 /* first step in pre adjustment of count for looping.*/

        ldwm        4(0,s_addr),tmp2    /* get either first or second word from source. */
	combt,=		tmp5,r0,skip_mask2 /* don't mask if whole word is valid*/
        vshd        tmp1,tmp2,tmp3      /* position data !  (delay slot)*/
	sh3add		tmp5,r0,save	/* setup r1*/
	mtctl		save,r11	/* setup mask in save*/
	zvdepi		-2,32,save
	or		save, tmp3, tmp3
        mtctl           tmp4,11            /* re-load the shift count into cr11 */
	b		skip_mask2
	copy 		r0, tmp5	/* zero out tmp5 so we don't try to mask again*/

chunk2:
        ldwm        4(0,s_addr),tmp2
        vshd        tmp1,tmp2,tmp3 

skip_mask2:
	uxor,nbz	tmp3, r0, save
	b,n		null3
        stbys,b,m   tmp3,4(0,d_addr)    /* store ! */

        ldwm        4(0,s_addr),tmp1    /* get 2nd word ! */
        vshd        tmp2,tmp1,tmp3      /* position data ! */
	uxor,nbz	tmp3, r0, save
	b,n		null4

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
	copy 		r0, tmp5	/* zero out tmp5 so we don't try to mask again*/
skip_mask3:
	uxor,nbz	tmp3,r0,save
	b,n		null4
	b		bp_1 /* we now have less than 4 bytes to move*/
        stbys,b,m   tmp3,4(0,d_addr)    /* store !*/

bp_0:    
	copy        tmp1,tmp2           /* switch registers used in the shift process.*/
	addibt,<=,n  4,count,done        /* if count = -4 this implies that count = 0 -> done */

bp_1:
        ldwm        4(0,s_addr),tmp1    /* get final word !        */
        vshd        tmp2,tmp1,tmp3      /* position data !*/
	uxor,sbz	tmp3,r0,save	/* if some-byte-zero */
	b		no_null		/* don't goto no_null-find which null instead */
	add		d_addr,count,d_addr	/* get d_addr ready for stbys,e */
	extru,<>	save,7,8,r0
	b		found_null5
	copy		r0, tmp5
	extru,<>	save,15,8,r0
	b		found_null5
	ldil		0x1FE000,tmp5		/* setup mask (FF000000)*/
	extru,<> 	save,23,8,r0
	b		found_null5
	ldil		0x1FFFE0,tmp5		/* setup mask (FFFF0000)*/
	ldo		-1(r0),tmp5		/* setup mask (FFFFFFFF)*/
found_null5:
	and		tmp3,tmp5,tmp3  /* zero out tmp5 based on mask in tmp5*/
no_null:
	bv		0(r2)		/* were done*/
        stbys,e     tmp3,0(0,d_addr)    /* store the data !*/

/* here we do ye old byte-at-a-time moves.*/
byteloop: 
	addibt,=,n     4,count,done
        comb,=    0,s_addr,done
	stbs	  r0,0(d_addr)		/* store null in case s_addr == NULL */
        ldbs,ma     1(s_addr),tmp1
encore:
	combt,=,n	tmp1,r0, pad_null_bytes1
        stbs,ma     tmp1,1(d_addr) 
        addibf,=,n  -1,count,encore
        ldbs,ma     1(s_addr),tmp1
	b,n		done

pnb_1:
	addibt,=,n	4,count,done /* if count was already 0 then we're done*/

pad_null_bytes1:
	combt,=,n   	count,r0,done	/* if count==0 then exit */
pad_null_bytes2:
	addibf,=	-1,count,pad_null_bytes2
	stbs,ma		r0,1(d_addr)
	b,n		done

pad_nulls:
	addibf,<=,n	-4,count,pad_nulls
	stwm		r0,4(d_addr)
	b,n		pnb_1


null1:
	extru,<>	save,7,8,r0
	b		found_null1
	copy		r0, tmp5
	extru,<>	save,15,8,r0
	b		found_null1
	ldil		0x1FE000,tmp5		/* setup mask (FF000000)*/
	extru,<> 	save,23,8,r0
	b		found_null1
	ldil		0x1FFFE0,tmp5		/* setup mask (FFFF0000)*/
	ldo		-1(r0),tmp5		/* setup mask (FFFFFFFF)*/
found_null1:
	and		tmp1,tmp5,tmp1		/*zero out tmp1 according to mask*/
	b		pad_nulls		/* nullify remaining count bytes*/
	stbys,b,m	tmp1,4(0,d_addr)	/* first word (account for alignment)*/


null2:	/* back porch case. We have less than 4 bytes to go.*/
	extru,<>	save,7,8,r0 	/* is null in 1st byte? */
	b		found_null2
	copy		r0, tmp5
	extru,<>	save,15,8,r0	/* is null in 2nd byte? */
	b		found_null2
	ldil		0x1FE000,tmp5		/* setup mask (FF000000)*/
	b		found_null2	/* null must be in 3rd byte */
	ldil		0x1FFFE0,tmp5		/* setup mask (FFFF0000)*/
found_null2:	
	and		tmp1,tmp5,tmp1		/*zero out tmp1 according to mask*/
	bv		0(r2)			/* we're done*/
	stbys,e		tmp1,0(0,d_addr)	/* last word (back porch)*/

null3:	/* not_aligned case where null is found in first of two words--adjust count*/
	extru,<>	save,7,8,r0
	b		found_null3
	copy		r0, tmp5
	extru,<>	save,15,8,r0
	b		found_null3
	ldil		0x1FE000,tmp5		/* setup mask (FF000000)*/
	extru,<> 	save,23,8,r0
	b		found_null3
	ldil		0x1FFFE0,tmp5		/* setup mask (FFFF0000)*/
	ldo		-1(r0),tmp5		/* setup mask (FFFFFFFF)*/
found_null3:
	addi		4,count,count 		/* fix count since null is in first of two words*/
	and		tmp3,tmp5,tmp3		/*zero out tmp3 according to mask*/
	b		pad_nulls		/* nullify remaining count bytes*/
        stbys,b,m       tmp3,4(d_addr)

null4:	/* not_aligned case where null is found in second of two words*/
	extru,<>	save,7,8,r0
	b		found_null4
	copy		r0, tmp5
	extru,<>	save,15,8,r0
	b		found_null4
	ldil		0x1FE000,tmp5		/* setup mask (FF000000)*/
	extru,<> 	save,23,8,r0
	b		found_null4
	ldil		0x1FFFE0,tmp5		/* setup mask (FFFF0000)*/
	ldo		-1(r0),tmp5		/* setup mask (FFFFFFFF)*/
found_null4:
	and		tmp3,tmp5,tmp3		/*zero out tmp4 according to mask*/
	b		pad_nulls		/* nullify remaining count bytes*/
        stbys,b,m       tmp3,4(d_addr)

done:    
EXIT(strncpy)
