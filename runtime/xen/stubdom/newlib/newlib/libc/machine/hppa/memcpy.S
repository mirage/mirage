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
 * memcpy(s1, s2, n)
 *
 * Copy n characters from s2 to s1; returns s1.
 */

#define d_addr  arg0
#define s_addr  arg1
#define count   arg2
#define tmp5	arg3
#define tmp1    r19
#define tmp2    r20
#define tmp3    r21
#define tmp4    r22
#define tmp6	r31

#include "DEFS.h"

ENTRY(memcpy)
        comib,>=  5,count,byteloop     /* If count is <= 6 don't get fancy.*/ 
        movb,=,n      d_addr,ret0,done    /* The return value is defined to be the value of d_addr. DELAY SLOT */
					/* if d_addr is null then exit */
        extru       s_addr,31,2,tmp1   /* Extract the low two bits of the source address. */
        extru       d_addr,31,2,tmp2   /* Extract the low two bits of the destination address. */
        add         count,tmp2,count   /* pre increment the count to adjust for alignment of s1 */
        comb,<>       tmp2,tmp1,not_aligned /* see if s1 is aligned w.r.t. s2. */
        dep         0,31,2,s_addr      /* Compute the word address of the source.  DELAY SLOT. */

/* aligned */

/* We will now begin the 16 byte at a time word move if count >= 16 ! */
/* Else we will branch to the  4 byte-at-a time word move ! */

        addibt,<,n -16,count,chekchunk  /* If count < 16 then we can't move 16 byte chunks ! */
                                        /*   actually we can legally move 13 or more bytes on the first loop.  */
        /* These loads and stores are done so as to prevent processor interlock. */
chunks:
        ldwm        16(0,s_addr),tmp1   /* tmp1 = *s_addr   s_addr += 16 */
        ldw         -12(0,s_addr),tmp2  /* tmp2 = 2nd word */
        ldw         -8(0,s_addr),tmp3   /* tmp3 = 3rd word */
        ldw         -4(0,s_addr),tmp4   /* tmp4 = 4th word */
        /* Now store the results !  */
        stbys,b,m   tmp1,4(0,d_addr)   /* tmp1 = 1st word stored d_addr += 16 also take care of front porch. */
        stwm        tmp2,4(0,d_addr)    /* tmp2 = 2nd word stored. */
        stwm        tmp3,4(0,d_addr)   /* tmp3 = 3rd word stored. */
        addibf,<    -16,count,chunks    /* If count is still >= 16 do another loop. */
        stwm        tmp4,4(0,d_addr)   /* tmp4 = 4th word stored. DELAY SLOT */

chekchunk:
        addibt,<,n  12,count,back_porch /* since the count is already decremented by -16 we're testing */
                                        /*   to see if there are at least 4 bytes left ? */
subchunk:
        ldws,ma      4(s_addr),tmp1     /* tmp1 = *s_addr++ */
        addibf,<     -4,count,subchunk  /* count -= 4 */
        stbys,b,m    tmp1,4(d_addr)     /* *d_addr++ = tmp1 */


back_porch:
         addibt,=,n  4,count,done       /* if count = 0 we're, of course, done ! */
         ldws        0(s_addr),tmp1     /* load up the back_porch */
         add         d_addr,count,d_addr/* final store address  is +1 too high ! */
	 bv		0(r2)		/* return--were done. */
         stbys,e     tmp1,0(d_addr)    /* kerplunk! whew !  */

/* Begin non_aligned code. (no refrence to politics) */
not_aligned:
        sub,>=       tmp2,tmp1,tmp3     /* compute the shift quantity again and skip the load if tmp2 > tmp1. */
        ldwm         4(0,s_addr),tmp1   /* load up the first word from the source. tmp1 = *s_addr++ */
        zdep         tmp3,28,29,tmp4    /* compute the number of bits to shift based on the number of bytes above. */
        mtctl        tmp4,11            /* load the shift count into cr11 = shift count register. */

        addibt,<,n   -16,count,chkchnk2 /* first step in pre adjustment of count for looping. */

chunk2:   
        ldwm        	16(0,s_addr),tmp2    /* get either first or second word . tmp2 = *s_addr++ */
	ldw		-12(s_addr),tmp3
	ldw		-8(s_addr),tmp4
	ldw		-4(s_addr),tmp5
        vshd		tmp1,tmp2,tmp6      /* position data !  */
        stbys,b,m	tmp6,4(0,d_addr)    /* store !  */

        vshd		tmp2,tmp3,tmp6      /* position data !  */
        stwm		tmp6,4(0,d_addr)    /* store ! */

        vshd		tmp3,tmp4,tmp6      /* position data ! */
        stwm		tmp6,4(0,d_addr)    /* store ! */

        vshd		tmp4,tmp5,tmp6      /* position data ! */
        stwm   		tmp6,4(0,d_addr)    /* store the data ! */
        addibf,<    -16,count,chunk2    /* If count is still >= 16 do another loop. */
	copy		tmp5,tmp1
        

chkchnk2:
        addibt,<,n  12,count,bp_0       /* if we don't have 4 bytes left then do the back porch (bp_0) */

subchnk2: 
        ldwm        4(0,s_addr),tmp2    /* get next word ! */
        vshd        tmp1,tmp2,tmp3      /* position data ! */
        addibt,<    -4,count,bp_1       /* decrement count and when count < 4 goto back_porch (bp_1) */
        stbys,b,m   tmp3,4(0,d_addr)    /* store ! */

        ldwm        4(0,s_addr),tmp1    /* get 4th word ! */
        vshd        tmp2,tmp1,tmp3      /* position data ! */
        addib,>=    -4,count,subchnk2   /* decrement count and when count <= 4 go to back porch (bp_2) */
        stbys,b,m   tmp3,4(0,d_addr)    /* store the data ! */

bp_0:    copy        tmp1,tmp2           /* switch registers used in the shift process. */
bp_1:    addibt,<=,n  4,count,done        /* if count = -4 this implies that count = 0 -> done  */
        add         d_addr,count,d_addr /* bump destination address to be +1 too high ! */
	mfctl		sar,tmp3	/* suppress final ldwm unless result used */
	extru		tmp3,28,2,tmp3	/* convert bitshift to byteshift */
	sub,<=		count,tmp3,r0	/* bytes unused if (count-byteshift <= 0*/

        ldwm        4(0,s_addr),tmp1    /* get final word !         */
        vshd        tmp2,tmp1,tmp3      /* position data ! */
	bv		0(r2)		/* return */
        stbys,e     tmp3,0(0,d_addr)    /* store the data ! */

/* here we do ye old byte-at-a-time moves. */
byteloop: 
        comb,>=,n    0,count,done

encore:
        ldbs,ma     1(s_addr),tmp1
        addibf,=   -1,count,encore
        stbs,ma     tmp1,1(d_addr) 

done:
EXIT(memcpy)
