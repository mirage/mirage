/* asm.h -- CRX architecture intrinsic functions
 *
 * Copyright (c) 2004 National Semiconductor Corporation
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

#ifndef	_ASM
#define _ASM

/* Note that immediate input values are not checked for validity. It is 
   the user's responsibility to use the intrinsic functions with appropriate
   immediate values. */

/* Absolute Instructions */
#define _absb_(src, dest)  	__asm__("absb %1, %0" : "=r" (dest) : \
                                   "r" ((char)src) , "0" (dest))
#define _absw_(src, dest)  	__asm__("absw %1,%0" : "=r" (dest) : \
                                    "r" ((short)src) , "0" (dest))
#define _absd_(src, dest)  	__asm__("absd %1, %0" : "=r" (dest)  : \
                                    "r" ((int)src) , "0" (dest))

/* Addition Instructions */
#define _addb_(src, dest)	__asm__("addb %1, %0" : "=r" (dest) : \
					"ri" ((unsigned char)src), "0" (dest) : "cc")
#define _addub_(src, dest)	__asm__("addub	%1, %0" : "=r" (dest) : \
					"ri" ((unsigned char)src), "0" (dest) : "cc")
#define _addw_(src, dest)	__asm__("addw %1, %0" : "=r" (dest) : \
					"ri" ((unsigned short)src), "0" (dest) : "cc")
#define _adduw_(src, dest)	__asm__("adduw	%1, %0" : "=r" (dest) : \
					"ri" ((unsigned short)src), "0" (dest) : "cc")
#define _addd_(src, dest)	__asm__("addd %1, %0" : "=r" (dest) : \
					"ri" ((unsigned int)src), "0" (dest) : "cc")
#define _addud_(src, dest)	__asm__("addud	%1, %0" : "=r" (dest) : \
					"ri" ((unsigned int)src), "0" (dest) : "cc")
/* Add with Carry */
#define _addcb_(src, dest)	__asm__("addcb	%1, %0" : "=r" (dest) : \
					"ri" ((unsigned char)src), "0" (dest) : "cc")
#define _addcw_(src, dest)	__asm__("addcw	%1, %0" : "=r" (dest) : \
					"ri" ((unsigned short)src), "0" (dest) : "cc")
#define _addcd_(src, dest)	__asm__("addcd	%1, %0" : "=r" (dest) : \
					"ri" ((unsigned int)src), "0" (dest) : "cc")
/* Q-format Add */
#define _addqb_(src, dest)	__asm__("addqb %1, %0" : "=r" (dest) : \
					"r" ((unsigned char)src), "0" (dest) : "cc")
#define _addqw_(src, dest)	__asm__("addqw %1, %0" : "=r" (dest) : \
					"r" ((unsigned short)src), "0" (dest) : "cc")
#define _addqd_(src, dest)	__asm__("addqd %1, %0" : "=r" (dest) : \
					"r" ((unsigned int)src), "0" (dest) : "cc")

/* Bitwise Logical AND */

#define _andb_(src, dest)  __asm__("andb %1,%0" : "=r" (dest) : \
				   "ri" ((unsigned char)src) , "0" (dest))
#define _andw_(src, dest)  __asm__("andw %1,%0" : "=r" (dest) : \
				   "ri" ((unsigned short)src) , "0" (dest))
#define _andd_(src, dest)  __asm__("andd %1,%0" : "=r" (dest) : \
		 		  "ri" ((unsigned int)src) , "0" (dest))

/* bswap Instruction */
#define _bswap_(src, dest)  	__asm__("bswap %1,%0" : "=r" (dest) : \
                                        "r" ((unsigned int)src) , "0" (dest))
/* cbit (clear bit) Instructions */
#define _cbitb_(pos, dest)  	__asm__("cbitb %1,%0" : "=mr" (dest) : \
                                     	"i" ((unsigned char)pos) , "0" (dest) : "cc")
#define _cbitw_(pos, dest)  	__asm__("cbitw %1,%0" : "=mr" (dest) : \
                                     	"i" ((unsigned char)pos) , "0" (dest) : "cc")
#define _cbitd_(pos, dest)  	__asm__("cbitd %1,%0" : "=r" (dest) : \
				    	"i" ((unsigned char)pos) , "0" (dest) : "cc")

/* Compare Instructions */
#define _cmpb_(src1, src2)  __asm__("cmpb %0,%1" : /* no output */  : \
				    "ri" ((unsigned char)src1) , "r" (src2) : "cc")
#define _cmpw_(src1,src2)  __asm__("cmpw %0,%1" : /* no output */  \
				   : "ri" ((unsigned short)src1) , "r" (src2) : "cc")
#define _cmpd_(src1,src2)  __asm__("cmpd %0,%1" : /* no output */  \
				   : "ri" ((unsigned int)src1) , "r" (src2) : "cc")

/* cntl Count Leading Ones Instructions */
#define _cntl1b_(src, dest)  	__asm__("cntl1b %1,%0" : "=r" (dest) : \
                                        "r" ((char)src) , "0" (dest))
#define _cntl1w_(src, dest)  	__asm__("cntl1w %1,%0" : "=r" (dest) : \
                                        "r" ((short)src) , "0" (dest))
#define _cntl1d_(src, dest)  	__asm__("cntl1d %1,%0" : "=r" (dest)  : \
                                        "r" ((int)src) , "0" (dest))

/* cntl Count Leading Zeros Instructions */
#define _cntl0b_(src, dest)  	__asm__("cntl0b %1,%0" : "=r" (dest) : \
                                        "r" ((char)src) , "0" (dest))
#define _cntl0w_(src, dest)  	__asm__("cntl0w %1,%0" : "=r" (dest) : \
                                        "r" ((short)src) , "0" (dest))
#define _cntl0d_(src, dest)  	__asm__("cntl0d %1,%0" : "=r" (dest)  : \
                                         "r" ((int)src) , "0" (dest))

/* cntl Count Leading Signs Instructions */
#define _cntlsb_(src, dest)  	__asm__("cntlsb %1,%0" : "=r" (dest) : \
                                        "r" ((char)src) , "0" (dest))
#define _cntlsw_(src, dest)  	__asm__("cntlsw %1,%0" : "=r" (dest) : \
                                        "r" ((short)src) , "0" (dest))
#define _cntlsd_(src, dest)  	__asm__("cntlsd %1,%0" : "=r" (dest)  : \
                                         "r" ((int)src) , "0" (dest))

/* Disable Inerrupts instructions */
#define _di_()       __asm__ volatile ("di\n" :  :  : "cc")
#define _disable_()  __asm__ volatile ("di\n" :  :  : "cc")

/* Enable Inerrupts instructions */
#define _ei_()			__asm__ volatile ("ei\n" :  :  : "cc")
#define _enable_()		__asm__ volatile ("ei\n" :  :  : "cc")

/* Enable Inerrupts instructions and Wait */
#define _eiwait_()  		__asm__ volatile ("eiwait" :  :  : "cc")

/* excp Instructions */
#define _excp_(vector)  	__asm__ volatile ("excp " # vector)

/* getpid Instruction */
#define _getrfid_(dest) 	__asm__("getrfid %0" : "=r" (dest)  : \
                                     	/* No input */ : "cc")

/* Load Instructions */
#define _loadb_(base,dest)	__asm__("loadb %1,%0" : "=r" (dest) : \
					"m" (base) , "0" (dest))
#define _loadw_(base,dest)	__asm__("loadw %1,%0" : "=r" (dest) : \
				        "m" (base) , "0" (dest))
#define _loadd_(base,dest)	__asm__("loadd %1,%0" : "=r" (dest) : \
					"m" (base) , "0" (dest))

/* Load Multiple Instructions */
#define _loadm_(src, mask)  	__asm__("loadm %0,%1" : /* No output */ : \
					"r" ((unsigned int)src) , "i" (mask))
#define _loadmp_(src, mask)  	__asm__("loadmp %0,%1" : /* No output */ : \
					"r" ((unsigned int)src) , "i" (mask))

/* Multiply Accumulate Instrutions */
#define _macsb_(hi, lo, src1, src2)  	__asm__("macsb %1,%0" \
					: =l (lo), =h (hi) \
					: "r" ((char)src1) , "r" (src2))
#define _macsw_(hi, lo, src1, src2)  	__asm__("macsw %1,%0" \
					: =l (lo), =h (hi) \
					: "r" ((short)src1) , "r" (src2))
#define _macsd_(hi, lo, src1, src2)  	__asm__("macsd %1,%0" \
					: =l (lo), =h (hi) \
					: "r" ((int)src1) , "r" (src2))
#define _macub_(hi, lo, src1, src2)  	__asm__("macub %1,%0" \
  					: =l (lo), =h (hi) \
					:"r" ((unsigned char)src1) , "r" (src2))
#define _macuw_(hi, lo, src1, src2)  	__asm__("macuw %1,%0" \
  					: =l (lo), =h (hi) \
					: "r" ((unsigned short)src1) , "r" (src2))
#define _macud_(hi, lo, src1, src2)  	__asm__("macud %1,%0" \
  					: =l (lo), =h (hi) \
					: "r" ((unsigned int)src1) , "r" (src2))

/* Q-Format Multiply Accumulate Instrutions */
#define _macqb_(src1, src2)  	__asm__("macqb %1,%0" \
  					: =l (lo), =h (hi) \
					:"r" ((char)src1) , "r" (src2))
#define _macqw_(src1, src2)  	__asm__("macqw %1,%0" \
  					: =l (lo), =h (hi) \
					:"r" ((short)src1) , "r" (src2))
#define _macqd_(src1, src2)  	__asm__("macqd %1,%0" \
  					: =l (lo), =h (hi) \
					:"r" ((int)src1) , "r" (src2))

/* Maximum Instructions */
#define _maxsb_(src, dest)  	__asm__("maxsb %1,%0" : "=r" (dest) : \
					"r" ((char)src) , "0" (dest))
#define _maxsw_(src, dest)  	__asm__("maxsw %1,%0" : "=r" (dest) : \
					"r" ((short)src) , "0" (dest))
#define _maxsd_(src, dest)  	__asm__("maxsd %1,%0" : "=r" (dest)  : \
					"r" ((int)src) , "0" (dest))
#define _maxub_(src, dest)  	__asm__("maxub %1,%0" : "=r" (dest) : \
					"r" ((unsigned char)src) , "0" (dest))
#define _maxuw_(src, dest)  	__asm__("maxuw %1,%0" : "=r" (dest) : \
					"r" ((unsigned short)src) , "0" (dest))
#define _maxud_(src, dest)  	__asm__("maxud %1,%0" : "=r" (dest)  : \
					"r" ((unsigned int)src) , "0" (dest))

/* Minimum Instructions */
#define _minsb_(src, dest)  	__asm__("minsb %1,%0" : "=r" (dest) : \
					"r" ((char)src) , "0" (dest))
#define _minsw_(src, dest)  	__asm__("minsw %1,%0" : "=r" (dest) : \
					"r" ((short)src) , "0" (dest))
#define _minsd_(src, dest)  	__asm__("minsd %1,%0" : "=r" (dest)  : \
					"r" ((int)src) , "0" (dest))
#define _minub_(src, dest)  	__asm__("minub %1,%0" : "=r" (dest) : \
					"r" ((unsigned char)src) , "0" (dest))
#define _minuw_(src, dest)  	__asm__("minuw %1,%0" : "=r" (dest) : \
					"r" ((unsigned short)src) , "0" (dest))
#define _minud_(src, dest)  	__asm__("minud %1,%0" : "=r" (dest)  : \
					"r" ((unsigned int)src) , "0" (dest))

/* Move Instructions */
#define _movb_(src, dest)  	__asm__("movb %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _movw_(src, dest)  	__asm__("movw %1,%0" : "=r" (dest) : \
					"ri" ((unsigned short)src) , "0" (dest))
#define _movd_(src, dest)  	__asm__("movd %1,%0" : "=r" (dest)  : \
					"ri" ((unsigned int)src) , "0" (dest))

/* mtpr and mfpr Insturctions */
#define _mtpr_(procregd, src)  __asm__("mtpr\t%0," procregd : /* no output */ : \
				       "r" (src) : "cc")
#define _mfpr_(procregd, dest) __asm__("mfpr\t" procregd ",%0" : "=r" (dest) : \
				       /* no input */ "0" (dest) : "cc")

/* Multiplication Instructions */
#define _mulsbw_(src, dest)  	__asm__("mulsbw %1,%0" : "=r" (dest) : \
                                   	"r" ((char)src) , "0" (dest))
#define _mulubw_(src, dest)  	__asm__("mulubw %1,%0" : "=r" (dest) : \
                                   	"r" ((unsigned char)src) , "0" (dest))
#define _mulswd_(src, dest)  	__asm__("mulswd %1,%0" : "=r" (dest) : \
                                   	"r" ((short)src) , "0" (dest))
#define _muluwd_(src, dest)  	__asm__("muluwd %1,%0" : "=r" (dest) : \
                                   	"r" ((unsigned short)src) , "0" (dest))
#define _mulb_(src, dest)  	__asm__("mulb %1,%0" : "=r" (dest) : \
					"ri" ((char)src) , "0" (dest))
#define _mulw_(src, dest)  	__asm__("mulw %1,%0" : "=r" (dest) : \
					"ri" ((short)src) , "0" (dest))
#define _muld_(src, dest)  	__asm__("muld %1,%0" : "=r" (dest)  : \
					"ri" ((int)src) , "0" (dest))
#define _mullsd_(hi, lo, src1, src2)  	__asm__("mullsd %2,%3" \
  					: =l (lo), =h (hi) \
					: "r" ((unsigned int)src1) , "r" ((unsigned int)src2))
#define _mullud_(hi, lo, src1, src2)  	__asm__("mullud %2,%3" \
  					: =l (lo), =h (hi) \
					: "r" ((int)src1) , "r" ((int)src2))

/* Q-Format Multiplication Instructions */
#define _mulqb_(src, dest)  	__asm__("mulqb %1,%0" : "=r" (dest) : \
					"r" ((char)src) , "0" (dest))
#define _mulqw_(src, dest)  	__asm__("mulqw %1,%0" : "=r" (dest) : \
					"r" ((short)src) , "0" (dest))

/* nop Instruction */
#define _nop_()  __asm__("nop")

/* Negate Instructions */
#define _negb_(src, dest)  	__asm__("negb %1,%0" : "=r" (dest) : \
					"r" ((char)src) , "0" (dest))
#define _negw_(src, dest)  	__asm__("negw %1,%0" : "=r" (dest) : \
					"r" ((short)src) , "0" (dest))
#define _negd_(src, dest)  	__asm__("negd %1,%0" : "=r" (dest) : \
					"r" ((int)src) , "0" (dest))

/* or Instructions */
#define _orb_(src, dest)  	__asm__("orb %1,%0" : "=r" (dest) : \
                                   "ri" ((unsigned char)src) , "0" (dest))
#define _orw_(src, dest)  	__asm__("orw %1,%0" : "=r" (dest) : \
                                    "ri" ((unsigned short)src) , "0" (dest))
#define _ord_(src, dest)  	__asm__("ord %1,%0" : "=r" (dest)  : \
                                    "ri" ((unsigned int)src) , "0" (dest))

/* Pop 1's Count Instructions */
#define _popcntb_(src, dest)  	__asm__("popcntb %1,%0" : "=r" (dest) : \
					"r" ((char)src) , "0" (dest))
#define _popcntw_(src, dest)  	__asm__("popcntw %1,%0" : "=r" (dest) : \
					"r" ((short)src) , "0" (dest))
#define _popcntd_(src, dest)  	__asm__("popcntd %1,%0" : "=r" (dest)  : \
                                    "r" ((int)src) , "0" (dest))

/* Rotate and Mask Instructions */ 
#define _ram_(shift, end, begin, dest, src) __asm__("ram %1, %2, %3, %0, %4" : \
						    "=r" (dest) : \
						    "i" ((unsigned char) shift), \
						    "i" (end), "i" (begin), \
						    "r" (src), "0" (dest))
#define _rim_(shift, end, begin, dest, src) __asm__("rim %1, %2, %3, %0, %4" : \
						    "=r" (dest) : \
						    "i" ((unsigned char) shift), \
						    "i" (end), "i" (begin), \
						    "r" (src), "0" (dest))

/* retx Instruction */
#define _retx_()  __asm__("retx")

/* Rotate Instructions */
#define _rotb_(shift, dest)  __asm__("rotb %1,%0" : "=r" (dest) : \
				     "i" ((unsigned char)shift) , "0" (dest))
#define _rotw_(shift, dest)  __asm__("rotw %1,%0" : "=r" (dest) : \
				     "i" ((unsigned char)shift) , "0" (dest))
#define _rotd_(shift, dest)  __asm__("rotd %1,%0" : "=r" (dest)  : \
				     "i" ((unsigned char)shift) , "0" (dest))
#define _rotlb_(shift, dest) __asm__("rotlb %1,%0" : "=r" (dest) : \
				     "r" ((unsigned char)shift) , "0" (dest))
#define _rotlw_(shift, dest) __asm__("rotlw %1,%0" : "=r" (dest) : \
				     "r" ((unsigned char)shift) , "0" (dest))
#define _rotld_(shift, dest) __asm__("rotld %1,%0" : "=r" (dest)  : \
				     "r" ((unsigned char)shift) , "0" (dest))
#define _rotrb_(shift, dest) __asm__("rotrb %1,%0" : "=r" (dest) : \
				     "r" ((unsigned char)shift) , "0" (dest))
#define _rotrw_(shift, dest) __asm__("rotrw %1,%0" : "=r" (dest) : \
				     "r" ((unsigned char)shift) , "0" (dest))
#define _rotrd_(shift, dest) __asm__("rotrd %1,%0" : "=r" (dest)  : \
				     "r" ((unsigned char)shift) , "0" (dest))

/* Set Bit Instructions */
#define _sbitb_(pos,dest)  __asm__("sbitb %1,%0" : "=mr" (dest) : \
				   "i" ((unsigned char)pos) , "0" (dest) : "cc")
#define _sbitw_(pos,dest)  __asm__("sbitw %1,%0" : "=mr" (dest) : \
                                   "i" ((unsigned char)pos) , "0" (dest) : "cc")
#define _sbitd_(pos,dest)  __asm__("sbitd %1,%0" : "=mr" (dest) : \
                                   "i" ((unsigned char)pos) , "0" (dest) : "cc")

/* setrfid Instruction */
#define _setrfid_(src)		__asm__("setrfid %0" : /* No output */  : \
					"r" (src) : "cc")

/* Sign Extend Instructions */
#define _sextbw_(src, dest)  	__asm__("sextbw %1,%0" : "=r" (dest) : \
                                   "r" ((char)src) , "0" (dest) )
#define _sextbd_(src, dest)  	__asm__("sextbd %1,%0" : "=r" (dest) : \
                                    "r" ((char)src) , "0" (dest) )
#define _sextwd_(src, dest)  	__asm__("sextwd %1,%0" : "=r" (dest) : \
                                    "r" ((short)src) , "0" (dest) )

/* Shift Left Logical Instructions */
#define _sllb_(src, dest)  	__asm__("sllb %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _sllw_(src, dest)  	__asm__("sllw %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _slld_(src, dest)  	__asm__("slld %1,%0" : "=r" (dest)  : \
					"ri" ((unsigned char)src) , "0" (dest))
/* Shift Right Arithmetic Instructions */
#define _srab_(src, dest)  	__asm__("srab %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _sraw_(src, dest)  	__asm__("sraw %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _srad_(src, dest)  	__asm__("srad %1,%0" : "=r" (dest)  : \
					"ri" ((unsigned char)src) , "0" (dest))

/* Shift Right Logical Instructions */
#define _srlb_(src, dest)  	__asm__("srlb %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _srlw_(src, dest)  	__asm__("srlw %1,%0" : "=r" (dest) : \
					"ri" ((unsigned char)src) , "0" (dest))
#define _srld_(src, dest)  	__asm__("srld %1,%0" : "=r" (dest)  : \
					"ri" ((unsigned char)src) , "0" (dest))
				
/* Store Instructions */
#define _storb_(src,address)  	__asm__("storb %1,%0" : "=m" (address) : \
					"ri" ((unsigned int)src))
#define _storw_(src,address)  	__asm__("storw %1,%0" : "=m" (address) : \
					"ri" ((unsigned int)src))
#define _stord_(src,address)  	__asm__("stord %1,%0" : "=m" (address) : \
					"ri" ((unsigned int)src))

/* Store Multiple Instructions */
#define _storm_(mask, src)  	__asm__("storm %1,%0" : /* No output here */ : \
					"i" (mask) , "r" ((unsigned int)src))
#define _stormp_(mask, src)  	__asm__("stormp %1,%0" : /* No output here */ : \
					"i" (mask) , "r" ((unsigned int)src))

/* Substruct Instructions */
#define _subb_(src, dest)  __asm__("subb	%1, %0" : "=r" (dest) : \
			           "ri" ((unsigned char)src), "0" (dest) : "cc")
#define _subw_(src, dest)  __asm__("subw	%1, %0" : "=r" (dest) : \
			           "ri" ((unsigned short)src), "0" (dest) : "cc")
#define _subd_(src, dest)  __asm__("subd	%1, %0" : "=r" (dest) : \
				   "ri" ((unsigned int)src), "0" (dest) : "cc")

/* Substruct with Carry Instructions */
#define _subcb_(src, dest) __asm__("subcb	%1, %0" : "=r" (dest) : \
			           "ri" ((unsigned char)src), "0" (dest) : "cc")
#define _subcw_(src, dest) __asm__("subcw	%1, %0" : "=r" (dest) : \
				   "ri" ((unsigned short)src), "0" (dest) : "cc")
#define _subcd_(src, dest) __asm__("subcd	%1, %0" : "=r" (dest) : \
			           "ri" ((unsigned int)src), "0" (dest) : "cc")

/* Q-Format Substruct Instructions */
#define _subqb_(src, dest)  	__asm__("subqw %1,%0" : "=r" (dest)  : \
                                        "r" ((char)src) , "0" (dest))
#define _subqw_(src, dest)  	__asm__("subqw %1,%0" : "=r" (dest)  : \
                                        "r" ((short)src) , "0" (dest))
#define _subqd_(src, dest)  	__asm__("subqd %1,%0" : "=r" (dest)  : \
                                        "r" ((short)src) , "0" (dest))

/* Test Bit Instructions */
#define _tbitb_(pos,dest)  __asm__("tbitb %0,%1" : /* No output */ : \
                                   "i" ((unsigned char)pos) , "rm" (dest) : "cc")
#define _tbitw_(pos,dest)  __asm__("tbitw %0,%1" : /* No output */ : \
                                   "i" ((unsigned char)pos) , "rm" (dest) : "cc")
#define _tbitd_(pos,dest)  __asm__("tbitd %0,%1" : /* No output */ : \
                                   "i" ((unsigned char)pos) , "rm" (dest) : "cc")

/* wait Instruction*/
#define _wait_()  		__asm__ volatile ("wait" :  :  : "cc")

/* xor Instructions */
#define _xorb_(src, dest)  	__asm__("xorb %1,%0" : "=r" (dest) : \
                                   "ri" ((unsigned char)src) , "0" (dest))
#define _xorw_(src, dest)  	__asm__("xorw %1,%0" : "=r" (dest) : \
                                    "ri" ((unsigned short)src) , "0" (dest))
#define _xord_(src, dest)  	__asm__("xord %1,%0" : "=r" (dest)  : \
                                    "ri" ((unsigned int)src) , "0" (dest))

/* Zero Extend Instructions */
#define _zextbw_(src, dest)  	__asm__("zextbw %1,%0" : "=r" (dest) : \
					"r" ((unsigned char)src) , "0" (dest))
#define _zextbd_(src, dest)  	__asm__("zextbd %1,%0" : "=r" (dest) : \
					"r" ((unsigned char)src) , "0" (dest))
#define _zextwd_(src, dest)  	__asm__("zextwd %1,%0" : "=r" (dest) : \
					"r" ((unsigned short)src) , "0" (dest))

#define _save_asm_(x) \
  __asm__ volatile (x ::: "memory","cc", \
		    "r0","r1","r2","r3","r4","r5","r6","r7", \
		    "r8","r9","r10","r11","r12","r13")

#endif  /* _ASM */


