 ##############################################################################
 # setjmp.S -- CRX setjmp routine                                             #
 #                                                                            #
 # Copyright (c) 2004 National Semiconductor Corporation                      #
 #                                                                            #
 # The authors hereby grant permission to use, copy, modify, distribute,      #
 # and license this software and its documentation for any purpose, provided  #
 # that existing copyright notices are retained in all copies and that this   #
 # notice is included verbatim in any distributions. No written agreement,    #
 # license, or royalty fee is required for any of the authorized uses.        #
 # Modifications to this software may be copyrighted by their authors         #
 # and need not follow the licensing terms described here, provided that      #
 # the new terms are clearly indicated on the first page of each file where   #
 # they apply.                                                                #
 #                                                                            #
 # C library -- setjmp, longjmp                                               #
 # longjmp(a,v)                                                               #
 # will generate a "return(v)"                                                #
 # from the last call to                                                      #
 # setjmp(a)                                                                  #
 # by restoring r7-ra, sp,                                                    #
 # and pc from 'a'                                                            #
 # and doing a return. (Makes sure that longjmp never returns 0).             #
 ##############################################################################

	.text
	.file	"setjmp.s"
        .align 4

        .globl _setjmp
        .align 4
_setjmp:
        #r2: .blkw
        storm r2,{r7,r8,r9,r10,r11,r12,r13,r14}
	stord sp,0(r2)
        movd  $0,r0
        jump  ra

        .globl _longjmp
_longjmp:
        #r2: .blkw # pointer save area
        #r3: .blkw # ret vlaue
        loadm r2, {r7,r8,r9,r10,r11,r12,r13,ra}
        loadd 0(r2), sp
        movd r3, r0
        cmpd $0, r3
        bne end1
        movd $1, r0
end1:
        jump ra
        .align 4
