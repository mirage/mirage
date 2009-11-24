/*
 * cf-isv.c -- 
 *
 * Copyright (c) 2006 CodeSourcery Inc
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

/* This file contains default interrupt handlers code for the
   interrupt vector.  All but one of the interrupts are user
   replaceable.

   These interrupt handlers are entered whenever the associated
   interrupt occurs.  All they do is stop the debugger to give the user
   the opportunity to determine where the problem was.  */


/* Each ISR is a loop containing a halt instruction  */
#define ISR_DEFINE(NAME) 					\
void __attribute__((interrupt_handler)) NAME (void)		\
{								\
  while (1)							\
    __asm__ __volatile__ ("halt" ::: "memory");			\
}								\
struct eat_trailing_semicolon

#if defined (L_other_interrupt)
static ISR_DEFINE (__other_interrupt);
#define ALIAS __other_interrupt
#define PREFIX interrupt
#define ALIASES A(6) A(7) \
	A(15) A(16) A(17) A(18) A(19) A(20) A(21) A(22) A(23) \
     	A(25) A(26) A(27) A(28) A(29) A(30) A(31) \
	A(56) A(57) A(58) A(59) A(60) A(62) A(63) \
	A(64) A(65) A(66) A(67) A(68) A(69) A(70) A(71) \
	A(72) A(73) A(74) A(75) A(76) A(77) A(78) A(79) \
	A(80) A(81) A(82) A(83) A(84) A(85) A(86) A(87) \
	A(88) A(89) A(90) A(91) A(92) A(93) A(94) A(95) \
	A(96) A(97) A(98) A(99) A(100) A(101) A(102) A(103) \
	A(104) A(105) A(106) A(107) A(108) A(109) A(110) A(111) \
	A(112) A(113) A(114) A(115) A(116) A(117) A(118) A(119) \
	A(120) A(121) A(122) A(123) A(124) A(125) A(126) A(127) \
	A(128) A(129) A(130) A(131) A(132) A(133) A(134) A(135) \
	A(136) A(137) A(138) A(139) A(140) A(141) A(142) A(143) \
	A(144) A(145) A(146) A(147) A(148) A(149) A(150) A(151) \
	A(152) A(153) A(154) A(155) A(156) A(157) A(158) A(159) \
	A(160) A(161) A(162) A(163) A(164) A(165) A(166) A(167) \
	A(168) A(169) A(170) A(171) A(172) A(173) A(174) A(175) \
	A(176) A(177) A(178) A(179) A(180) A(181) A(182) A(183) \
	A(184) A(185) A(186) A(187) A(188) A(189) A(190) A(191) \
	A(192) A(193) A(194) A(195) A(196) A(197) A(198) A(199) \
	A(200) A(201) A(202) A(203) A(204) A(205) A(206) A(207) \
	A(208) A(209) A(210) A(211) A(212) A(213) A(214) A(215) \
	A(216) A(217) A(218) A(219) A(220) A(221) A(222) A(223) \
	A(224) A(225) A(226) A(227) A(228) A(229) A(230) A(231) \
	A(232) A(233) A(234) A(235) A(236) A(237) A(238) A(239) \
	A(240) A(241) A(242) A(243) A(244) A(245) A(246) A(247) \
	A(248) A(249) A(250) A(251) A(252) A(253) A(254) A(255)
#endif

#if defined (L_access_error)
ISR_DEFINE (__access_error);
#define DEFINED __access_error
#endif

#if defined (L_address_error)
ISR_DEFINE (__address_error);
#define DEFINED __address_error
#endif

#if defined (L_illegal_instruction)
ISR_DEFINE (__illegal_instruction);
#define DEFINED __illegal_instruction
#endif

#if defined (L_divide_by_zero)
ISR_DEFINE (__divide_by_zero);
#define DEFINED __divide_by_zero
#endif

#if defined (L_privilege_violation)
ISR_DEFINE (__privilege_violation);
#define DEFINED __privilege_violation
#endif

#if defined (L_trace)
ISR_DEFINE (__trace);
#define DEFINED __trace
#endif

#if defined (L_unimplemented_opcode)
static ISR_DEFINE (__unimplemented_opcode);
#define ALIAS __unimplemented_opcode
#define PREFIX unimplemented_
#define SUFFIX _opcode
#define ALIASES A(line_a) A(line_f)
#endif

#if defined (L_breakpoint_debug_interrupt)
static ISR_DEFINE (__breakpoint_debug_interrupt);
#define ALIAS __breakpoint_debug_interrupt
#define SUFFIX _breakpoint_debug_interrupt
#define ALIASES A(non_pc) A(pc)
#endif

#if defined (L_format_error)
ISR_DEFINE (__format_error);
#define DEFINED __format_error
#endif

#if defined (L_spurious_interrupt)
ISR_DEFINE (__spurious_interrupt);
#define DEFINED __spurious_interrupt
#endif

#if defined (L_trap_interrupt)
static ISR_DEFINE (__trap_interrupt);
#define ALIAS __trap_interrupt
#define PREFIX trap
#define ALIASES A(0) A(1) A(2) A(3) A(4) A(5) A(6) A(7) \
	A(8) A(9) A(10) A(11) A(12) A(13) A(14) A(15)
#endif

#if defined (L_fp_interrupt)
static ISR_DEFINE (__fp_interrupt);
#define ALIAS __fp_interrupt
#define PREFIX fp_
#define ALIASES A(branch_unordered) A(inexact_result) A(divide_by_zero) \
	A(underflow) A(operand_error) A(overflow) A(input_not_a_number)	\
	A(input_denormalized_number)
#endif

#if defined (L_unsupported_instruction)
ISR_DEFINE (__unsupported_instruction);
#define DEFINED __unsupported_instruction
#endif

#if defined(ALIAS)
#ifndef PREFIX
#define PREFIX
#endif
#ifndef SUFFIX
#define SUFFIX
#endif
#define STRING_(a) #a
#define STRING(a) STRING_(a)
#define PASTE4_(a,b,c,d) a##b##c##d
#define PASTE4(a,b,c,d) PASTE4_(a,b,c,d)
#define A(N) \
  void __attribute__((weak, alias(STRING(ALIAS)))) PASTE4(__,PREFIX,N,SUFFIX) (void);
ALIASES
#elif !defined(DEFINED)
#error "No interrupt routine requested"
#endif

