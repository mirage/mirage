/* Setjmp and longjmp for mmix.

   Copyright (C) 2001 Hans-Peter Nilsson

   Permission to use, copy, modify, and distribute this software is
   freely granted, provided that the above copyright notice, this notice
   and the following disclaimer are preserved with no changes.

   THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.

   jmp_buf[5]:
   0:	fp
   1:	rJ (return-address)
   2:	sp
   3:	rO *before* the setjmp call.
   4:	temporary storage.  Reserved between setjmp and longjmp.  */

#ifdef __MMIX_ABI_GNU__
#define arg1 $231
#define arg2 $232
#define outret $231
#define popval 0
#else
#define arg1 $0
#define arg2 $1
#define outret $0
#define popval 1
#endif

	.section .text.setjmp,"ax",@progbits
	.global setjmp
setjmp:
% Store fp, sp and return address.  Recycle the static-chain and
% structure-return registers as temporary register, since we need to keep
% the jmp_buf (parameter 1) and the return address across a "POP".
	SET  $251,arg1
	STOU $253,$251,0
	GET  $252,rJ
	STOU $252,$251,8
	STOU $254,$251,16
	SETL outret,0

% Jump through hoops to get the value of rO *before* the setjmp call.
	GETA $255,0f
	PUT  rJ,$255
	POP  popval,0
0:
	GET  $255,rO
	STOU $255,$251,24
	GO   $255,$252,0
	.size setjmp,.-setjmp

	.section .text.longjmp,"ax",@progbits
	.global longjmp
longjmp:
% Reset arg2 to 1 if it is 0 (see longjmp(2)) and store it in jmp_buf.
% Save arg1 in a global register, since it will be destroyed by the POPs
% (in the mmixware ABI).
	CSZ  arg2,arg2,1
	STOU arg2,arg1,32
	SET  $251,arg1

% Loop and "POP 0,0" until rO is the expected value, like
% the expansion of nonlocal_goto_receiver, except that we put the return
% value in the right register and make sure that the POP causes it to
% enter the right return-value register as seen by the caller.  For the
% GNU ABI, it is unnecessary to do this in the loop and perhaps the memory
% access can be hoisted outside the loop, but this is safe and simple and
% I see no need to optimize longjmps.
	GETA $255,0f
	PUT  rJ,$255
	LDOU $255,$251,24
0:
	GET  $252,rO
	CMPU $252,$252,$255
	BNP  $252,1f
	LDOU outret,$251,32
	POP  popval,0
1:
	LDOU $253,$251,0
	LDOU $255,$251,8
	LDOU $254,$251,16
	GO   $255,$255,0
 	.size longjmp,.-longjmp
