/*
(C) Copyright IBM Corp. 2005, 2006

All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
notice, this list of conditions and the following disclaimer in the 
documentation and/or other materials provided with the distribution.
    * Neither the name of IBM nor the names of its contributors may be 
used to endorse or promote products derived from this software without 
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

Author: Andreas Neukoetter (ti95neuk@de.ibm.com)
*/

/*
	int setjmp( jmp_buf env );
*/
	.text
	.align	2
	.global	setjmp
setjmp:
	stqd	$80, 2*16($3)
	stqd	$81, 3*16($3)
	stqd	$82, 4*16($3)
	stqd	$83, 5*16($3)
	stqd	$84, 6*16($3)
	stqd	$85, 7*16($3)
	stqd	$86, 8*16($3)
	stqd	$87, 9*16($3)
	stqd	$88, 10*16($3)
	stqd	$89, 11*16($3)
	stqd	$90, 12*16($3)
	stqd	$91, 13*16($3)
	stqd	$92, 14*16($3)
	stqd	$93, 15*16($3)
	stqd	$94, 16*16($3)
	stqd	$95, 17*16($3)
	stqd	$96, 18*16($3)
	stqd	$97, 19*16($3)
	stqd	$98, 20*16($3)
	stqd	$99, 21*16($3)
	stqd	$100, 22*16($3)
	stqd	$101, 23*16($3)
	stqd	$102, 24*16($3)
	stqd	$103, 25*16($3)
	stqd	$104, 26*16($3)
	stqd	$105, 27*16($3)
	stqd	$106, 28*16($3)
	stqd	$107, 29*16($3)
	stqd	$108, 30*16($3)
	stqd	$109, 31*16($3)
	stqd	$110, 32*16($3)
	stqd	$111, 33*16($3)
	stqd	$112, 34*16($3)
	stqd	$113, 35*16($3)
	stqd	$114, 36*16($3)
	stqd	$115, 37*16($3)
	stqd	$116, 38*16($3)
	stqd	$117, 39*16($3)
	stqd	$118, 40*16($3)
	stqd	$119, 41*16($3)

	hbr	setjmp_ret, $0
	lnop			# pipe1 bubble added for instruction fetch

	stqd	$120, 42*16($3)
	stqd	$121, 43*16($3)
	stqd	$122, 44*16($3)
	stqd	$123, 45*16($3)
	stqd	$124, 46*16($3)
	stqd	$125, 47*16($3)
	stqd	$126, 48*16($3)
	stqd	$127, 49*16($3)
	
	stqd	$0, 0*16($3)
	stqd	$1, 1*16($3)

	il	$3, 0

setjmp_ret:
	bi	$0

/*
	int longjmp( jmp_buf env, int val );
*/
	.text
	.align	2
	.global	longjmp
longjmp:
	lr	$127, $1

	lqd	$0, 0*16($3)
	lqd	$1, 1*16($3)

	sf	$126, $127, $1
	rotqbyi	$126, $126, 12
	fsmbi	$127, 0x0F00
	and	$126, $126, $127
	a	$1, $1, $126

	# restore all the non-volatile registers

	lqd	$80, 2*16($3)
	lqd	$81, 3*16($3)
	lqd	$82, 4*16($3)
	lqd	$83, 5*16($3)
	lqd	$84, 6*16($3)
	lqd	$85, 7*16($3)
	lqd	$86, 8*16($3)
	lqd	$87, 9*16($3)
	lqd	$88, 10*16($3)
	lqd	$89, 11*16($3)
	lqd	$90, 12*16($3)
	lqd	$91, 13*16($3)
	lqd	$92, 14*16($3)
	lqd	$93, 15*16($3)
	lqd	$94, 16*16($3)
	lqd	$95, 17*16($3)
	lqd	$96, 18*16($3)
	lqd	$97, 19*16($3)
	lqd	$98, 20*16($3)
	lqd	$99, 21*16($3)
	lqd	$100, 22*16($3)
	lqd	$101, 23*16($3)
	lqd	$102, 24*16($3)
	lqd	$103, 25*16($3)
	lqd	$104, 26*16($3)
	lqd	$105, 27*16($3)
	lqd	$106, 28*16($3)
	lqd	$107, 29*16($3)
	lqd	$108, 30*16($3)
	lqd	$109, 31*16($3)

	hbr	longjmp_ret, $0

	lqd	$110, 32*16($3)
	lqd	$111, 33*16($3)
	lqd	$112, 34*16($3)
	lqd	$113, 35*16($3)
	lqd	$114, 36*16($3)
	lqd	$115, 37*16($3)
	lqd	$116, 38*16($3)
	lqd	$117, 39*16($3)
	lqd	$118, 40*16($3)
	lqd	$119, 41*16($3)
	lqd	$120, 42*16($3)
	lqd	$121, 43*16($3)
	lqd	$122, 44*16($3)
	lqd	$123, 45*16($3)
	lqd	$124, 46*16($3)
	lqd	$125, 47*16($3)

	ceqi	$5, $4, 0
	lqd	$126, 48*16($3)
	lqd	$127, 49*16($3)

	sf	$3, $5, $4

longjmp_ret:
	bi	$0

