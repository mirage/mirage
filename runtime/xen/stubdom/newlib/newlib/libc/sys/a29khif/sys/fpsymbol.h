; @(#)fpsymbol.h	1.4 90/10/14 20:55:59, Copyright 1989, 1990 AMD 
; start of fpsymbol.h file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1989, 1990 Advanced Micro Devices, Inc.
;
; This software is the property of Advanced Micro Devices, Inc  (AMD)  which
; specifically  grants the user the right to modify, use and distribute this
; software provided this notice is not removed or altered.  All other rights
; are reserved by AMD.
;
; AMD MAKES NO WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, WITH REGARD TO THIS
; SOFTWARE.  IN NO EVENT SHALL AMD BE LIABLE FOR INCIDENTAL OR CONSEQUENTIAL
; DAMAGES IN CONNECTION WITH OR ARISING FROM THE FURNISHING, PERFORMANCE, OR
; USE OF THIS SOFTWARE.
;
; So that all may benefit from your experience, please report  any  problems
; or  suggestions about this software to the 29K Technical Support Center at
; 800-29-29-AMD (800-292-9263) in the USA, or 0800-89-1131  in  the  UK,  or
; 0031-11-1129 in Japan, toll free.  The direct dial number is 512-462-4118.
;
; Advanced Micro Devices, Inc.
; 29K Support Products
; Mail Stop 573
; 5900 E. Ben White Blvd.
; Austin, TX 78741
; 800-292-9263
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; ______________________________________________________________________
;|______________________________________________________________________|
;|                                                                      |
;|             SYMBOLS FOR DEFINING THE INSTRUCTION WORD                |
;|                                                                      |
;|______________________________________________________________________|
;|______________________________________________________________________|
;
;
; Revision Information:
;------------------------------------------------------------------------
; Date: March 31, 1989
; Author: Roy Carlson per Bob Perlman and Richard Relph
;
; The symbols section describing transactions was modified to contain
; several new symbol values.  The reason for the change was to force the 
; CA bit to be set--and remain set--once code accesses the coprocessor.  
;
; Future operating systems will use the Coprocessor Active (CA) bit in 
; the Old Processor Status Register to determine whether or not to save
; coprocessor state, etc..  This means that the instruction control field 
; Set Coprocessor Active (SA) bit should be used as follows:
; 
;  	(1) any coprocessor STORE must have its SA bit set to 1, 
;		so as to set CA,
; 
; and	(2) any coprocessor LOAD must have its SA bit set to 0, 
;		so as to prevent clearing CA.
;------------------------------------------------------------------------
; Date: 89/01/30 12:32:13;  author: jim;  lines added/del: 5/4
; Corrected CP_IEEE_GRADUAL_UFLOW_MODE and CP_RMS_MASK.
; Added CP_EXCPS_POSITION, the ls bit of the CP_XXX_EXCP ensemble.
; fixed a few typos in comments.
;------------------------------------------------------------------------
; Date: 89/01/23 18:00:26;  author: jim;  lines added/del: 488/468
; Richard O. Parker
; January 5, 1989
; 
; 1) The _cp_prec_field in the "cp_build_inst", "cp_build_inst_h"
;    and "cp_build_inst_l" macros was not being defined in the case
;    of Am29K-supported floating-point instructions (e.g., FADD, FSUB,
;    DADD, etc.).
; 
; 2) The multiplexor select codes in the opcode table entries
;    associated with the "cp_build_inst", "cp_build_inst_h" and
;    "cp_build_inst_l" macros, pertaining to the CONVERT_F_TO_D
;    and CONVERT_D_TO_F instructions were incorrect.
;------------------------------------------------------------------------
; Date: 88/12/20 14:28:26;  author: jim;  lines added/del: 1/1
; Larry Westerman corrected definition of CP_MOVE_P.
; Version required for Release 1.1 of the Intrinsics shipped 12/12/88.
;------------------------------------------------------------------------
; Date: 88/11/18 15:44:45;  author: law; 
; Initial revision
;
;
;========================================================================
;
; The following mnemonics are used to specify the 14 LSBs of the
; instruction word (fields SIP, SIQ, SIT, SIF, IF, and CO).
;
;========================================================================
;
;  floating point operation codes.
;
   .equ  CP_PASS_P,               0x00000000  ;  pass P
   .equ  CP_MINUSP,               0x00000040  ; -P
   .equ  CP_ABSP,                 0x00000080  ; |P|
   .equ  CP_SIGNT_TIMES_ABSP,     0x00000C00  ; SIGN(T) * |P|
;
   .equ  CP_P_PLUS_T,             0x00000001  ;  P + T
   .equ  CP_P_MINUS_T,            0x00000101  ;  P - T
   .equ  CP_MINUSP_PLUS_T,        0x00001001  ; -P + T
   .equ  CP_MINUSP_MINUS_T,       0x00001101  ; -P - T
   .equ  CP_ABS_P_PLUS_T,         0x00000081  ; |P + T|
   .equ  CP_ABS_P_MINUS_T,        0x00000181  ; |P - T|
   .equ  CP_ABSP_PLUS_ABST,       0x00002201  ; |P| + |T|
   .equ  CP_ABSP_MINUS_ABST,      0x00002301  ; |P| - |T|
   .equ  CP_ABS_ABSP_MINUS_ABST,  0x00002381  ; ||P| - |T||
;
   .equ  CP_P_TIMES_Q,            0x00000002  ;  P * Q
   .equ  CP_MINUSP_TIMES_Q,       0x00001002  ; -P * Q
   .equ  CP_ABS_P_TIMES_Q,        0x00000082  ; |P * Q|
;
   .equ  CP_COMPARE_P_AND_T,      0x00000103  ; compare P and T
;
   .equ  CP_MAX_P_AND_T,          0x00000104  ; max P,T
   .equ  CP_MAX_ABSP_AND_ABST,    0x00002304  ; max |P|, |T|
;
   .equ  CP_MIN_P_AND_T,          0x00001005  ; min P,T
   .equ  CP_MIN_ABSP_AND_ABST,    0x00003205  ; min |P|,|T|
   .equ  CP_LIMIT_P_TO_MAGT,      0x00003A05  ; limit P to magnitude of T
;
   .equ  CP_CONVERT_T_TO_INT,     0x00000006  ; convert T to integer
;
   .equ  CP_SCALE_T_TO_INT_BY_Q,  0x00000007  ; scale T to integer by Q
;
   .equ  CP_PQ_PLUS_T,            0x00000008  ; (P * Q) + T
   .equ  CP_MINUSPQ_PLUS_T,       0x00001008  ; (-P * Q) + T
   .equ  CP_PQ_MINUS_T,           0x00000108  ; (P * Q) - T
   .equ  CP_MINUSPQ_MINUS_T,      0x00001108  ; (-P * Q) - T
   .equ  CP_ABSPQ_PLUS_ABST,      0x00002A08  ; |(P * Q)| + T
   .equ  CP_MINUSABSPQ_PLUS_ABST, 0x00003A08  ;-|(P * Q)| + T
   .equ  CP_ABSPQ_MINUS_ABST,     0x00002B08  ; |(P * Q)| - |T|
;
   .equ  CP_ROUND_T_TO_INT,       0x00000009  ; round T to integral value
;
   .equ  CP_RECIPROCAL_OF_P,      0x0000000A  ; reciprocal of P
;
   .equ  CP_CONVERT_T_TO_ALT,     0x0000000B  ; convert T to alt. f.p. format
   .equ  CP_CONVERT_T_FROM_ALT,   0x0000000C  ; convert T to alt. f.p. format
;
;
;  integer operation codes.
;
   .equ  CP_I_PASS_P,             0x00000020  ; integer pass P
   .equ  CP_I_MINUSP,             0x00000060  ; integer -P
   .equ  CP_I_ABSP,               0x000000A0  ; integer |P|
   .equ  CP_I_SIGNT_TIMES_ABSP,   0x00000C20  ; integer SIGN(T) * |P|
;
   .equ  CP_I_P_PLUS_T,           0x00000021  ; integer P + T
   .equ  CP_I_P_MINUS_T,          0x00000121  ; integer P - T
   .equ  CP_I_MINUSP_PLUS_T,      0x00001021  ; integer -P + T
   .equ  CP_I_ABS_P_PLUS_T,       0x000000A1  ; integer |P + T|
   .equ  CP_I_ABS_P_MINUS_T,      0x000001A1  ; integer |P - T|
;
   .equ  CP_I_P_TIMES_Q,          0x00000022  ; integer P * Q
;
   .equ  CP_I_COMPARE_P_AND_T,    0x00000123  ; integer compare P and T
;
   .equ  CP_I_MAX_P_AND_T,        0x00000124  ; integer max P,T
;
   .equ  CP_I_MIN_P_AND_T,        0x00001025  ; integer min P,T
;
   .equ  CP_I_CONVERT_T_TO_FLOAT, 0x00000026  ; integer convert T to f.p.
;
   .equ  CP_I_SCALE_T_TO_FLOAT_BY_Q, 0x00000027  ; integer scale T to f.p. by Q
;
   .equ  CP_I_P_OR_T,             0x00000030  ; integer P OR T
;
   .equ  CP_I_P_AND_T,            0x00000031  ; integer P AND T
;
   .equ  CP_I_P_XOR_T,            0x00000032  ; integer P XOR T
;
   .equ  CP_I_NOT_T,              0x00000032  ; integer NOT T
;
   .equ  CP_I_LSHIFT_P_BY_Q,      0x00000033  ; integer logical shift P by Q
;                                               places
;
   .equ  CP_I_ASHIFT_P_BY_Q,      0x00000034  ; integer arith. shift P by Q
;                                               places
;
   .equ  CP_I_FSHIFT_PT_BY_Q,     0x00000035  ; integer funnel shift PT by Q
;                                               places
;
;
; move instruction (f.p. or integer)
;
   .equ  CP_MOVE_P,               0x00000018  ; move operand P
;
;
;========================================================================
;
;  precision codes for the the operands in registers R and S, and for
;  the result (instruction word fields IPR, RPR).
;
;========================================================================
;
;
   .equ  CP_D_S,                  0x00008000  ;Double result, single input(s)
   .equ  CP_S_D,                  0x00004000  ;Single result, double input(s)
   .equ  CP_D_D,                  0x00000000  ;Double result, double input(s)
   .equ  CP_S_S,                  0x0000C000  ;Single result, single input(s)
;
;========================================================================
;
; The following mnemonics are used to specify the 16 LSBs of an Am29027
; instruction word for floating-point instructions supported by the
; Am29000 instruction set.
;
;========================================================================
;
   .equ  CP_FADD,                 0x0000C001
   .equ  CP_DADD,                 0x00000001
   .equ  CP_FSUB,                 0x0000C101
   .equ  CP_DSUB,                 0x00000101
   .equ  CP_FMUL,                 0x0000C002
   .equ  CP_DMUL,                 0x00000002
   .equ  CP_FEQ,                  0x0000C103
   .equ  CP_DEQ,                  0x00000103
   .equ  CP_FGE,                  0x0000C103
   .equ  CP_DGE,                  0x00000103
   .equ  CP_FGT,                  0x0000C103
   .equ  CP_DGT,                  0x00000103
   .equ  CP_CONVERT_I_TO_F,       0x0000C026  ; CONVERT (int -> s.p.)
   .equ  CP_CONVERT_I_TO_D,       0x00008026  ; CONVERT (int -> d.p.)
   .equ  CP_CONVERT_F_TO_I,       0x0000C006  ; CONVERT (s.p.-> int)
   .equ  CP_CONVERT_D_TO_I,       0x00004006  ; CONVERT (d.p.-> int)
   .equ  CP_CONVERT_F_TO_D,       0x00008000  ; CONVERT (s.p.-> d.p.)
   .equ  CP_CONVERT_D_TO_F,       0x00004000  ; CONVERT (d.p.-> s.p.)
;
;
;========================================================================
;
;  operand select codes (instruction word fields PMS, QMS, TMS).
;
;========================================================================
;
;
   .equ  CP_P_EQ_R,               0x00000000
   .equ  CP_P_EQ_S,               0x01000000
   .equ  CP_P_EQ_0,               0x02000000
   .equ  CP_P_EQ_ONE_HALF,        0x03000000
   .equ  CP_P_EQ_IMINUS1,         0x03000000
   .equ  CP_P_EQ_1,               0x04000000
   .equ  CP_P_EQ_2,               0x05000000
   .equ  CP_P_EQ_3,               0x06000000
   .equ  CP_P_EQ_PI,              0x07000000
   .equ  CP_P_EQ_IMINUSMAX,       0x07000000
   .equ  CP_P_EQ_RF0,             0x08000000
   .equ  CP_P_EQ_RF1,             0x09000000
   .equ  CP_P_EQ_RF2,             0x0A000000
   .equ  CP_P_EQ_RF3,             0x0B000000
   .equ  CP_P_EQ_RF4,             0x0C000000
   .equ  CP_P_EQ_RF5,             0x0D000000
   .equ  CP_P_EQ_RF6,             0x0E000000
   .equ  CP_P_EQ_RF7,             0x0F000000
;
   .equ  CP_Q_EQ_R,               0x00000000
   .equ  CP_Q_EQ_S,               0x00100000
   .equ  CP_Q_EQ_0,               0x00200000
   .equ  CP_Q_EQ_ONE_HALF,        0x00300000
   .equ  CP_Q_EQ_IMINUS1,         0x00300000
   .equ  CP_Q_EQ_1,               0x00400000
   .equ  CP_Q_EQ_2,               0x00500000
   .equ  CP_Q_EQ_3,               0x00600000
   .equ  CP_Q_EQ_PI,              0x00700000
   .equ  CP_Q_EQ_IMINUSMAX,       0x00700000
   .equ  CP_Q_EQ_RF0,             0x00800000
   .equ  CP_Q_EQ_RF1,             0x00900000
   .equ  CP_Q_EQ_RF2,             0x00A00000
   .equ  CP_Q_EQ_RF3,             0x00B00000
   .equ  CP_Q_EQ_RF4,             0x00C00000
   .equ  CP_Q_EQ_RF5,             0x00D00000
   .equ  CP_Q_EQ_RF6,             0x00E00000
   .equ  CP_Q_EQ_RF7,             0x00F00000
;
   .equ  CP_T_EQ_R,               0x00000000
   .equ  CP_T_EQ_S,               0x00010000
   .equ  CP_T_EQ_0,               0x00020000
   .equ  CP_T_EQ_ONE_HALF,        0x00030000
   .equ  CP_T_EQ_IMINUS1,         0x00030000
   .equ  CP_T_EQ_1,               0x00040000
   .equ  CP_T_EQ_2,               0x00050000
   .equ  CP_T_EQ_3,               0x00060000
   .equ  CP_T_EQ_PI,              0x00070000
   .equ  CP_T_EQ_IMINUSMAX,       0x00070000
   .equ  CP_T_EQ_RF0,             0x00080000
   .equ  CP_T_EQ_RF1,             0x00090000
   .equ  CP_T_EQ_RF2,             0x000A0000
   .equ  CP_T_EQ_RF3,             0x000B0000
   .equ  CP_T_EQ_RF4,             0x000C0000
   .equ  CP_T_EQ_RF5,             0x000D0000
   .equ  CP_T_EQ_RF6,             0x000E0000
   .equ  CP_T_EQ_RF7,             0x000F0000
;
;
;========================================================================
;
;  destination select codes (instruction word fields RF, RFS)
;
;========================================================================
;
;
   .equ  CP_DEST_EQ_GP,           0x00000000
   .equ  CP_DEST_EQ_RF0,          0x80000000
   .equ  CP_DEST_EQ_RF1,          0x90000000
   .equ  CP_DEST_EQ_RF2,          0xA0000000
   .equ  CP_DEST_EQ_RF3,          0xB0000000
   .equ  CP_DEST_EQ_RF4,          0xC0000000
   .equ  CP_DEST_EQ_RF5,          0xD0000000
   .equ  CP_DEST_EQ_RF6,          0xE0000000
   .equ  CP_DEST_EQ_RF7,          0xF0000000
;
;
; ______________________________________________________________________
;|______________________________________________________________________|
;|                                                                      |
;|    SYMBOLS FOR DEFINING THE MODE REGISTER DOUBLE WORD                |
;|                                                                      |
;|______________________________________________________________________|
;|______________________________________________________________________|
;
;
;
    .equ  CP_PFF_MASK,            0x00000003  ; primary f.p. format mask
    .equ  CP_PFF_EQ_IEEE,         0x00000000  ; primary f.p. format = IEEE
    .equ  CP_PFF_EQ_DECD,         0x00000001  ; primary f.p. format = DEC D
    .equ  CP_PFF_EQ_DECG,         0x00000002  ; primary f.p. format = DEC G
    .equ  CP_PFF_EQ_IBM,          0x00000003  ; primary f.p. format = IBM
    .equ  CP_PFF_POSITION,        0
;
    .equ  CP_AFF_MASK,            0x0000000C  ; alternate f.p. format mask
    .equ  CP_AFF_EQ_IEEE,         0x00000000  ; alternate f.p. format = IEEE
    .equ  CP_AFF_EQ_DECD,         0x00000004  ; alternate f.p. format = DEC D
    .equ  CP_AFF_EQ_DECG,         0x00000008  ; alternate f.p. format = DEC G
    .equ  CP_AFF_EQ_IBM,          0x0000000C  ; alternate f.p. format = IBM
    .equ  CP_AFF_POSITION,        2
;
    .equ  CP_SAT_MASK,            0x00000010  ; saturate mode (SAT) mask
    .equ  CP_SATURATE_MODE,       0x00000010  ; enable saturate mode (SAT=1)
    .equ  CP_SAT_POSITION,        4
;
    .equ  CP_AP_MASK,             0x00000020  ; affine/proj. mode (AP) mask
    .equ  CP_AFFINE_MODE,         0x00000020  ; enable affine mode (AP=1)
    .equ  CP_PROJECTIVE_MODE,     0x00000000  ; enable projective mode (AP=0)
    .equ  CP_AP_POSITION,         5
;
    .equ  CP_TRP_MASK,            0x00000040  ; IEEE trap mode (TRP) mask
    .equ  CP_IEEE_TRAPS_ENABLED,  0x00000040  ; IEEE trap mode enabled (TRP=1)
    .equ  CP_IEEE_TRAPS_DISABLED, 0x00000000  ; IEEE trap mode disabled (TRP=0)
    .equ  CP_TRP_POSITION,        6
;
    .equ  CP_SU_MASK,                0x00000080  ; IEEE sud. uflow (SU) mask
    .equ  CP_IEEE_SUDDEN_UFLOW_MODE, 0x00000080  ; IEEE sud. uflow mode (SU=1)
    .equ  CP_IEEE_GRADUAL_UFLOW_MODE,0x00000000  ; IEEE grad uflow mode (SU=0)
    .equ  CP_SU_POSITION,            7
;
    .equ  CP_BS_MASK,             0x00000100  ; IBM sig. mask (BS)
    .equ  CP_BS_POSITION,         8
;
    .equ  CP_BU_MASK,             0x00000200  ; IBM underflow mask (BU)
    .equ  CP_BU_POSITION,         9
;
    .equ  CP_MS_MASK,                0x00000800  ; signed int. mpy (MS) mask
    .equ  CP_SIGNED_INT_MPY_MODE,    0x00000800  ; signed int. mpy mode (MS=1)
    .equ  CP_UNSIGNED_INT_MPY_MODE,  0x00000000  ; unsigned int. mpy mode (MS=0)
    .equ  CP_MS_POSITION,            11
;
    .equ  CP_MF_MASK,             0x00003000  ; int. mult. fmt. mode (MF) mask
    .equ  CP_MF_EQ_LSBS,          0x00000000  ; int. mult. fmt. = LSBs
    .equ  CP_MF_EQ_LSBSFA,        0x00001000  ; int. mult. fmt. = LSBs,fmt. adj.
    .equ  CP_MF_EQ_MSBS,          0x00002000  ; int. mult. fmt. = MSBs
    .equ  CP_MF_EQ_MSBSFA,        0x00003000  ; int. mult. fmt. = MSBs,fmt. adj.
    .equ  CP_MF_POSITION,         12
;
    .equ  CP_RMS_MASK,            0x0001C000  ; round mode (RMS) mask
    .equ  CP_RMS_EQ_NEAREST,      0x00000000  ; round mode = to nearest
    .equ  CP_RMS_EQ_MINUS_INF,    0x00004000  ; round mode = toward -oo
    .equ  CP_RMS_EQ_PLUS_INF,     0x00008000  ; round mode = toward +oo
    .equ  CP_RMS_EQ_ZERO,         0x0000C000  ; round mode = toward zero
    .equ  CP_RMS_POSITION,        14
;
    .equ  CP_PL_MASK,             0x00100000  ; pipeline mode (PL) mask
    .equ  CP_FLOWTHROUGH_MODE,    0x00000000  ; select flow-through mode
    .equ  CP_PIPELINE_MODE,       0x00100000  ; select pipeline mode
    .equ  CP_PL_POSITION,         20
;
    .equ  CP_INVALID_OP_EXCP_MASK, 0x00400000  ; invalid operation excp. mask(IM)
    .equ  CP_RESERVED_OP_EXCP_MASK,0x00800000  ; reserved operand excp. mask(RM)
    .equ  CP_OVERFLOW_EXCP_MASK,   0x01000000  ; overflow exception mask (VM)
    .equ  CP_UNDERFLOW_EXCP_MASK,  0x02000000  ; underflow exception mask(UM)
    .equ  CP_INEXACT_EXCP_MASK,    0x04000000  ; inexact result excp. mask(XM)
    .equ  CP_ZERO_EXCP_MASK,       0x08000000  ; zero result exception mask (ZM)
    .equ  CP_EXCPS_POSITION,       22
;
    .equ  CP_PLTC_MASK,           0x0000000F  ; pipeline timer count (PLTC) mask
    .equ  CP_PLTC_EQ_2,           0x00000002  ; pipeline timer count = 2
    .equ  CP_PLTC_EQ_3,           0x00000003  ; pipeline timer count = 3
    .equ  CP_PLTC_EQ_4,           0x00000004  ; pipeline timer count = 4
    .equ  CP_PLTC_EQ_5,           0x00000005  ; pipeline timer count = 5
    .equ  CP_PLTC_EQ_6,           0x00000006  ; pipeline timer count = 6
    .equ  CP_PLTC_EQ_7,           0x00000007  ; pipeline timer count = 7
    .equ  CP_PLTC_EQ_8,           0x00000008  ; pipeline timer count = 8
    .equ  CP_PLTC_EQ_9,           0x00000009  ; pipeline timer count = 9
    .equ  CP_PLTC_EQ_10,          0x0000000A  ; pipeline timer count = 10
    .equ  CP_PLTC_EQ_11,          0x0000000B  ; pipeline timer count = 11
    .equ  CP_PLTC_EQ_12,          0x0000000C  ; pipeline timer count = 12
    .equ  CP_PLTC_EQ_13,          0x0000000D  ; pipeline timer count = 13
    .equ  CP_PLTC_EQ_14,          0x0000000E  ; pipeline timer count = 14
    .equ  CP_PLTC_EQ_15,          0x0000000F  ; pipeline timer count = 15
    .equ  CP_PLTC_POSITION,       0
;
    .equ  CP_MATC_MASK,           0x000000F0  ; mpy-acc timer count (MATC) mask
    .equ  CP_MATC_EQ_2,           0x00000020  ; mpy-acc timer count = 2
    .equ  CP_MATC_EQ_3,           0x00000030  ; mpy-acc timer count = 3
    .equ  CP_MATC_EQ_4,           0x00000040  ; mpy-acc timer count = 4
    .equ  CP_MATC_EQ_5,           0x00000050  ; mpy-acc timer count = 5
    .equ  CP_MATC_EQ_6,           0x00000060  ; mpy-acc timer count = 6
    .equ  CP_MATC_EQ_7,           0x00000070  ; mpy-acc timer count = 7
    .equ  CP_MATC_EQ_8,           0x00000080  ; mpy-acc timer count = 8
    .equ  CP_MATC_EQ_9,           0x00000090  ; mpy-acc timer count = 9
    .equ  CP_MATC_EQ_10,          0x000000A0  ; mpy-acc timer count = 10
    .equ  CP_MATC_EQ_11,          0x000000B0  ; mpy-acc timer count = 11
    .equ  CP_MATC_EQ_12,          0x000000C0  ; mpy-acc timer count = 12
    .equ  CP_MATC_EQ_13,          0x000000D0  ; mpy-acc timer count = 13
    .equ  CP_MATC_EQ_14,          0x000000E0  ; mpy-acc timer count = 14
    .equ  CP_MATC_EQ_15,          0x000000F0  ; mpy-acc timer count = 15
    .equ  CP_MATC_POSITION,       4
;
    .equ  CP_MVTC_MASK,           0x00000F00  ; MOVE P timer count (MVTC) mask
    .equ  CP_MVTC_EQ_2,           0x00000200  ; MOVE P timer count = 2
    .equ  CP_MVTC_EQ_3,           0x00000300  ; MOVE P timer count = 3
    .equ  CP_MVTC_EQ_4,           0x00000400  ; MOVE P timer count = 4
    .equ  CP_MVTC_EQ_5,           0x00000500  ; MOVE P timer count = 5
    .equ  CP_MVTC_EQ_6,           0x00000600  ; MOVE P timer count = 6
    .equ  CP_MVTC_EQ_7,           0x00000700  ; MOVE P timer count = 7
    .equ  CP_MVTC_EQ_8,           0x00000800  ; MOVE P timer count = 8
    .equ  CP_MVTC_EQ_9,           0x00000900  ; MOVE P timer count = 9
    .equ  CP_MVTC_EQ_10,          0x00000A00  ; MOVE P timer count = 10
    .equ  CP_MVTC_EQ_11,          0x00000B00  ; MOVE P timer count = 11
    .equ  CP_MVTC_EQ_12,          0x00000C00  ; MOVE P timer count = 12
    .equ  CP_MVTC_EQ_13,          0x00000D00  ; MOVE P timer count = 13
    .equ  CP_MVTC_EQ_14,          0x00000E00  ; MOVE P timer count = 14
    .equ  CP_MVTC_EQ_15,          0x00000F00  ; MOVE P timer count = 15
    .equ  CP_MVTC_POSITION,       8
;
    .equ  CP_AD_MASK,             0x00001000  ;
    .equ  CP_ADVANCE_DRDY_MODE,   0x00001000  ;
    .equ  CP_NORMAL_DRDY_MODE,    0x00000000  ;
    .equ  CP_AD_POSITION,         12
;
    .equ  CP_HE_MASK,               0x00002000  ; Halt-on-error mask (HE)
    .equ  CP_HALT_ON_ERROR_ENABLED, 0x00002000  ; Halt-on-error enabled (HE=1)
    .equ  CP_HALT_ON_ERROR_DISABLED,0x00000000  ; Halt-on-error disabled (HE=0)
    .equ  CP_HE_POSITION,           13
;
    .equ  CP_EX_MASK,             0x00004000  ; EXCP enable mask (EX)
    .equ  CP_EXCP_ENABLED,        0x00004000  ; EXCP enabled (EX=1)
    .equ  CP_EXCP_DISABLED,       0x00000000  ; EXCP disabled (EX=0)
    .equ  CP_EX_POSITION,         14
;
;
;
; ______________________________________________________________________
;|______________________________________________________________________|
;|                                                                      |
;|      SYMBOLS FOR DEFINING THE STATUS REGISTER WORD                   |
;|                                                                      |
;|______________________________________________________________________|
;|______________________________________________________________________|
;
;
   .equ CP_INVALID_OP_EXCP,           0x00000001
   .equ CP_INVALID_OP_EXCP_POSITION,  0
;
   .equ CP_RESERVED_OP_EXCP,          0x00000002
   .equ CP_RESERVED_OP_EXCP_POSITION, 1
;
   .equ CP_OVERFLOW_EXCP,             0x00000004
   .equ CP_OVERFLOW_EXCP_POSITION,    2
;
   .equ CP_UNDERFLOW_EXCP,            0x00000008
   .equ CP_UNDERFLOW_EXCP_POSITION,   3
;
   .equ CP_INEXACT_EXCP,              0x00000010
   .equ CP_INEXACT_EXCP_POSITION,     4
;
   .equ CP_ZERO_EXCP,                 0x00000020
   .equ CP_ZERO_EXCP_POSITION,        5
;
   .equ CP_EXCP_STATUS_MASK,          0x00000040
   .equ CP_EXCP_STATUS_FLAG_POSITION, 6
;
   .equ CP_R_TEMP_VALID_MASK,         0x00000080
   .equ R_TEMP_VALID_POSITION,        7
;
   .equ CP_S_TEMP_VALID_MASK,         0x00000100
   .equ CP_S_TEMP_VALID_POSITION,     8
;
   .equ CP_I_TEMP_VALID_FLAG,         0x00000200
   .equ CP_I_TEMP_VALID_POSITION,     9
;
   .equ CP_OPERATION_PENDING_MASK,    0x00000400
   .equ CP_OPERATION_PENDING_POSITION,10
;
;
; ______________________________________________________________________
;|______________________________________________________________________|
;|                                                                      |
;|      SYMBOLS FOR DEFINING THE FLAG REGISTER WORD                     |
;|                                                                      |
;|______________________________________________________________________|
;|______________________________________________________________________|
;
;
   .equ CP_INVALID_OP_FLAG,           0x00000001
   .equ CP_INVALID_OP_FLAG_POSITION,  0
;
   .equ CP_CARRY_FLAG,                0x00000001
   .equ CP_CARRY_FLAG_POSITION,       0
;
   .equ CP_RESERVED_OP_FLAG,          0x00000002
   .equ CP_RESERVED_OP_FLAG_POSITION, 1
;
   .equ CP_OVERFLOW_FLAG,             0x00000004
   .equ CP_OVERFLOW_FLAG_POSITION,    2
;
   .equ CP_UNORDERED_FLAG,            0x00000004
   .equ CP_UNORDERED_FLAG_POSITION,   2
;
   .equ CP_UNDERFLOW_FLAG,            0x00000008
   .equ CP_UNDERFLOW_FLAG_POSITION,   3
;
   .equ CP_LESS_THAN_FLAG,            0x00000008
   .equ CP_LESS_THAN_POSITION,        3
;
   .equ CP_WINNER_FLAG,               0x00000008
   .equ CP_WINNER_FLAG_POSITION,      3
;
   .equ CP_INEXACT_FLAG,              0x00000010
   .equ CP_INEXACT_FLAG_POSITION,     4
;
   .equ CP_GREATER_THAN_FLAG,         0x00000010
   .equ CP_GREATER_THAN_FLAG_POSITION,4
;
   .equ CP_ZERO_FLAG,                 0x00000020
   .equ CP_ZERO_FLAG_POSITION,        5
;
   .equ CP_EQUAL_FLAG,                0x00000020
   .equ CP_EQUAL_FLAG_POSITION,       5
;
   .equ CP_SIGN_FLAG,                 0x00000040
   .equ CP_SIGN_FLAG_POSITION,        6
;
;
; ______________________________________________________________________
;|______________________________________________________________________|
;|                                                                      |
;|                 SYMBOLS FOR TRANSACTION REQUEST TYPES                |
;|                                                                      |
;|______________________________________________________________________|
;|______________________________________________________________________|
;
;
; write requests
;
; Note: Each WRITE_* transaction request, plus ADV_TEMPS sets the CA
; (Coprocessor Active) bit in the 29000 Current Processor Status Register.
;
   .equ  CP_WRITE_R,              0x20  ;write sing or doub to R register
   .equ  CP_WRITE_S,              0x21  ;write sing or doub to S register
   .equ  CP_WRITE_RS,             0x22  ;write sing operands to R and S
   .equ  CP_WRITE_MODE,           0x23  ;write mode double word to 29027
   .equ  CP_WRITE_STATUS,         0x24  ;write status word to 29027
   .equ  CP_WRITE_PREC,           0x25  ;write reg. file precision word
                                        ; to 29027
   .equ  CP_WRITE_INST,           0x26  ;write instruction to 29027
   .equ  CP_ADV_TEMPS,            0x27  ;move R-Temp, S-Temp into R,S
;
; read requests
;
   .equ  CP_READ_MSBS,            0x00  ;read sing result or MSB of doub
   .equ  CP_READ_LSBS,            0x01  ;read LSB of doub result
   .equ  CP_READ_FLAGS,           0x02  ;read 29027 flag register
   .equ  CP_READ_STATUS,          0x03  ;read 29027 status register
   .equ  CP_SAVE_STATE,           0x04  ;read one word of 29027 state
;
; "start operation" symbol; this is "OR"ed with a WRITE_R, WRITE_S,
;    WRITE_RS, or WRITE_INST symbol.
;

   .equ  CP_START,                0b1000000  ;bit to start 29027 operation
;
; "suppress exceptions reporting" symbol; this is "OR"ed with a ed
;
;

   .equ  CP_NO_ERR,               0b1000000  ;suppress exception reporting
;                                            ;   during load.
;       cp_write_r       - transfers 32- or 64-bit operand to Am29027
;                          register R
;       cp_write_s       - transfers 32- or 64-bit operand to Am29027
;                          register S
;       cp_write_rs      - transfers two 32-bit floating-point operands to
;                          Am29027 registers R and S
;       cp_write_prec    - transfers a word to the Am29027 precision register
;       cp_write_status  - transfers a word to the Am29027 status register
;       cp_write_inst    - transfers an instruction to the Am29027
;                          instruction register
;       cp_advance_temps - transfers the contents of the Am29027 temporary
;                          registers to the corresponding working registers
;       cp_write_mode    - transfers a mode specification the the Am29027
;                          mode register
;       cp_read_dp       - read a double-precision floating-point result
;                          from the Am29027
;       cp_read_sp       - read a single-precision floating-point result
;                          from the Am29027
;       cp_read_int      - read an integer result from the Am29027
;       cp_read_flags    - read the contents of the Am29027 flag register
;       cp_read_status   - read the contents of the Am29027 status register
;       cp_read_state_wd - read a single Am29027 state word
;       cp_save_state    - save Am29027 state
;       cp_restore_state - restore Am29027 state
;       cp_build_inst    - build an Am29027 instruction
;       cp_build_inst_h  - build 16 MSBs of an Am29027 instruction
;       cp_build_inst_l  - build 16 LSBs of an Am29027 instruction
;
;
;
;============================================================================
;  MACRO NAME: cp_write_r
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 16, 1988
;
;  FUNCTION:   Transfers a 32- or 64-bit operand to Am29027 input register R
;
;  PARAMETERS:
;    reg      - the Am29000 g.p. register containing the 32-bit operand to be
;               transferred, or the 32 MSBs of the 64-bit operand to be
;               transferred.
;
;    LSB_reg  - the Am29000 g.p. register containing the 32 LSBs of the
;               64-bit operand to be transferred
;
;    INT      - indicates that the operand to be transferred is a 32-bit
;               integer
;
;    START    - indicates that a new Am29027 operation is to be started
;               once the operand has been transferred
;
;
;  USAGE:
;
;    cp_write_r  reg [,LSB_reg] [,START]       for floating-point operands
; or cp_write_r  reg, INT [,START]             for integer operands
;
;    Transferring double-precision floating-point operands - Either of
;       two forms is acceptable:
;
;               cp_write_r   reg
;          or   cp_write_r   reg, LSB_reg
;
;       If LSB_reg is omitted, the LSBs are taken from the next g.p.
;       register.
;
;       Ex:     cp_write_r   lr2     Transfers the contents of lr2 to
;                                    the most-significant half of Am29027
;                                    register R, and the contents of lr3
;                                    to the least-significant half.
;
;               cp_write_r   lr2,lr5 Transfers the contents of lr2 to
;                                    the most-significant half of Am29027
;                                    register R, and the contents of lr5
;                                    to the least-significant half.
;
;
;    Transferring single-precision floating-point operands - Use the
;       form:
;
;               cp_write_r   reg
;
;
;       Ex:     cp_write_r   lr2     Transfers the contents of lr2 to
;                                    the most-significant half of Am29027
;                                    register R, (the contents of lr3
;                                    will be transferred to the least-
;                                    significant half of register R, but
;                                    these bits are don't cares).
;
;
;    Transferring integer operands - Use the form:
;
;               cp_write_r   reg,INT
;
;
;       Ex:     cp_write_r   lr2,INT Transfers the contents of lr2 to
;                                    the least-significant half of Am29027
;                                    register R, (the contents of lr2
;                                    will also be transferred to the most-
;                                    significant half of register R, but
;                                    these bits are don't cares).
;
;
;    Starting an Am29027 operation - Any of the forms above may be
;       appended with parameter START, e.g.:
;
;               cp_write_r   lr2,START
;
;               cp_write_r   lr2,lr5,START
;
;               cp_write_r   lr2,INT,START
;
;
;============================================================================
;
 .macro cp_write_r,p1,p2,p3
;
   .if $narg==0
     .err
     .print "cp_WRITE_R: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     store 1,CP_WRITE_R,p1,%%((&p1)+1)
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","INT"
       store 1,CP_WRITE_R,p1,p1
       .exitm
     .endif
;
     .ifeqs "@p2@","START"
       store 1,CP_WRITE_R|CP_START,p1,%%((&p1)+1)
       .exitm
     .endif
;
     store 1,CP_WRITE_R,p1,p2
     .exitm
;
   .endif
;
;
   .if $narg==3
;
     .ifeqs "@p2@","START"
       .ifeqs "@p3@","INT"
         store 1,CP_WRITE_R|CP_START,p1,p1
       .else
         .err
         .print "cp_write_r: bad parameter list"
       .endif
       .exitm
     .endif
;
     .ifeqs "@p2@","INT"
       .ifeqs "@p3@","START"
         store 1,CP_WRITE_R|CP_START,p1,p1
       .else
         .err
         .print "cp_write_r: bad parameter list"
       .endif
       .exitm
     .endif
;
     .ifeqs "@p3@","START"
       store 1,CP_WRITE_R|CP_START,p1,p2
     .else
       .err
       .print "cp_write_r: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=4
     .err
     .print "cp_write_r: too many parameters"
   .endif
;
 .endm
;
;
;
;
;
;============================================================================
;  MACRO NAME: cp_write_s
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 16, 1988
;
;  FUNCTION:   Transfers a 32- or 64-bit operand to Am29027 input register S
;
;  PARAMETERS:
;    reg      - the Am29000 g.p. register containing the 32-bit operand to be
;               transferred, or the 32 MSBs of the 64-bit operand to be
;               transferred.
;
;    LSB_reg  - the Am29000 g.p. register containing the 32 LSBs of the
;               64-bit operand to be transferred
;
;    INT      - indicates that the operand to be transferred is a 32-bit
;               integer
;
;    START    - indicates that a new Am29027 operation is to be started
;               once the operand has been transferred
;
;
;  USAGE:
;
;    cp_write_s  reg [,LSB_reg] [,START]       for floating-point operands
; or cp_write_s  reg, INT [,START]             for integer operands
;
;    Transferring double-precision floating-point operands - Either of
;       two forms is acceptable:
;
;               cp_write_s   reg
;          or   cp_write_s   reg, LSB_reg
;
;       If LSB_reg is omitted, the LSBs are taken from the next g.p.
;       register.
;
;       Ex:     cp_write_s   lr2     Transfers the contents of lr2 to
;                                    the most-significant half of Am29027
;                                    register S, and the contents of lr3
;                                    to the least-significant half.
;
;               cp_write_s   lr2,lr5 Transfers the contents of lr2 to
;                                    the most-significant half of Am29027
;                                    register S, and the contents of lr5
;                                    to the least-significant half.
;
;
;    Transferring single-precision floating-point operands - Use the
;       form:
;
;               cp_write_s   reg
;
;
;       Ex:     cp_write_s   lr2     Transfers the contents of lr2 to
;                                    the most-significant half of Am29027
;                                    register S, (the contents of lr3
;                                    will be transferred to the least-
;                                    significant half of register S, but
;                                    these bits are don't cares).
;
;
;    Transferring integer operands - Use the form:
;
;               cp_write_s   reg,INT
;
;
;       Ex:     cp_write_s   lr2,INT Transfers the contents of lr2 to
;                                    the least-significant half of Am29027
;                                    register S, (the contents of lr2
;                                    will also be transferred to the most-
;                                    significant half of register S, but
;                                    these bits are don't cares).
;
;
;    Starting an Am29027 operation - Any of the forms above may be
;       appended with parameter START, e.g.:
;
;               cp_write_s   lr2,START
;
;               cp_write_s   lr2,lr5,START
;
;               cp_write_s   lr2,INT,START
;
;
;============================================================================
;
 .macro cp_write_s,p1,p2,p3
;
   .if $narg==0
     .err
     .print "cp_write_s: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     store 1,CP_WRITE_S,p1,%%((&p1)+1)
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","INT"
       store 1,CP_WRITE_S,p1,p1
       .exitm
     .endif
;
     .ifeqs "@p2@","START"
       store 1,CP_WRITE_S|CP_START,p1,%%((&p1)+1)
       .exitm
     .endif
;
     store 1,CP_WRITE_S,p1,p2
     .exitm
;
   .endif
;
;
   .if $narg==3
;
     .ifeqs "@p2@","START"
       .ifeqs "@p3@","INT"
         store 1,CP_WRITE_S|CP_START,p1,p1
       .else
         .err
         .print "cp_write_s: bad parameter list"
       .endif
       .exitm
     .endif
;
     .ifeqs "@p2@","INT"
       .ifeqs "@p3@","START"
         store 1,CP_WRITE_S|CP_START,p1,p1
       .else
         .err
         .print "cp_write_s: bad parameter list"
       .endif
       .exitm
     .endif
;
     .ifeqs "@p3@","START"
       store 1,CP_WRITE_S|CP_START,p1,p2
     .else
       .err
       .print "cp_write_s: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=4
     .err
     .print "cp_write_s: too many parameters"
   .endif
;
 .endm
;
;
;
;
;============================================================================
;  MACRO NAME: cp_write_rs
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 16, 1988
;
;  FUNCTION:   Transfers two 32-bit floating-point operands to Am29027
;              input registers R and S
;
;  PARAMETERS:
;    reg1     - the Am29000 g.p. register containing the 32-bit operand to be
;               transferred to register R
;
;    reg2     - the Am29000 g.p. register containing the 32-bit operand to be
;               transferred to register S
;
;    START    - indicates that a new Am29027 operation is to be started
;               once the operands have been transferred
;
;
;  USAGE:
;
;    cp_write_rs  reg1, reg2 [,START]
;
;       Ex: cp_write_rs  lr2,lr5       Transfers the contents of lr2 to
;                                      the most-significant half of Am29027
;                                      register R, and the contents of lr5
;                                      to the most-significant half of Am29027
;                                      register S.
;
;           cp_write_rs  lr2,lr5,START Transfers the contents of lr2 to
;                                      the most-significant half of Am29027
;                                      register R, and the contents of lr5
;                                      to the most-significant half of Am29027
;                                      register S; a new operation is started
;                                      once the transfer is complete.
;
;
;
;============================================================================
;
 .macro cp_write_rs,p1,p2,p3
;
;
   .if $narg<=1
     .err
     .print "cp_write_rs: missing parameter(s)"
     .exitm
   .endif
;
;
   .if $narg==2
     .ifeqs "@p2@","START"
       .err
       .print "cp_write_rs: bad parameter list"
     .else
       store 1,CP_WRITE_RS,p1,p2
     .endif
     .exitm
   .endif
;
;
   .if $narg==3
     .ifeqs "@p3@","START"
       store 1,CP_WRITE_RS|CP_START,p1,p2
     .else
       .err
       .print "cp_write_rs: bad parameter list"
     .endif
     .exitm
   .endif
;
;
   .if $narg>=4
     .err
     .print "cp_write_rs: too many parameters"
     .exitm
   .endif
;
 .endm
;
;
;
;
;
;
;============================================================================
;  MACRO NAME: cp_write_prec
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 16, 1988
;
;  FUNCTION:   Transfers a word to the Am29027 precision register
;
;  PARAMETERS:
;    reg      - the Am29000 g.p. register containing the word to be
;               transferred to the Am29027 precision register
;
;  USAGE:
;
;    cp_write_prec  reg
;
;       Ex: cp_write_prec  lr2         Transfers the contents of lr2 to
;                                      the Am29027 precision register.
;
;
;============================================================================
;
 .macro cp_write_prec,p1
;
;
   .if $narg!=1
     .err
     .print "cp_write_prec: bad parameter list"
   .else
     store 1,CP_WRITE_PREC,p1,0
   .endif
;
 .endm
;
;
;
;
;
;
;============================================================================
;  MACRO NAME: cp_write_status
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 16, 1988
;
;  FUNCTION:   Transfers a word to the Am29027 precision register
;
;  PARAMETERS:
;    reg        - the Am29000 g.p. register containing the word to be
;                 transferred to the Am29027 status register
;
;    RESTORE    - indicates that this is the last step of a state restoration
;                 sequence (flow-through mode only)
;
;    INVALIDATE - indicates that the current contents of the ALU pipeline
;                 register are to be invalidated (pipeline mode only)
;
;  USAGE:
;
;    cp_write_status  reg [,RESTORE|INVALIDATE]
;
;       Ex: cp_write_status  lr2            Transfers the contents of lr2 to
;                                           the Am29027 status register.
;
;
;           cp_write_status  lr2,RESTORE    Transfers the contents of lr2 to
;                                           the Am29027 status register, and
;                                           completes the state restore
;                                           sequence
;
;           cp_write_status  lr2,INVALIDATE Transfers the contents of lr2 to
;                                           the Am29027 status register, and
;                                           invalidates the contents of the
;                                           ALU pipeline.
;
;
;============================================================================
;
 .macro cp_write_status,p1,p2
;
   .if $narg==0
     .err
     .print "cp_write_status: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     store 1,CP_WRITE_STATUS,p1,0
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","RESTORE"
       store 1,CP_WRITE_STATUS|CP_START,p1,0
       .exitm
     .endif
;
     .ifeqs "@p2@","INVALIDATE"
       store 1,CP_WRITE_STATUS|CP_START,p1,0
       .exitm
     .endif
;
     .err
     .print "cp_write_status: bad parameter list"
     .exitm
;
   .endif
;
;
   .if $narg >=3
     .err
     .print "cp_write_status: too many parameters"
     .exitm
   .endif
;
 .endm
;
;
;
;
;
;============================================================================
;  MACRO NAME: cp_write_inst
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 16, 1988
;
;  FUNCTION:   Transfers an instruction word to the Am29027 instruction
;              register
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register containing the word to be
;              transferred to the Am29027 instruction register
;
;    START   - indicates that a new Am29027 operation is to be started
;              once the instruction word has been transferred
;
;  USAGE:
;
;    cp_write_inst  reg [,START]
;
;       Ex: cp_write_inst  lr2            Transfers the contents of lr2 to
;                                         the Am29027 instruction register.
;
;
;           cp_write_inst  lr2,START      Transfers the contents of lr2 to
;                                         the Am29027 status register; a
;                                         new operation is started once the
;                                         transfer is complete.
;
;
;============================================================================
;
 .macro cp_write_inst,p1,p2
;
   .if $narg==0
     .err
     .print "cp_write_inst: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     store 1,CP_WRITE_INST,p1,p1
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","START"
       store 1,CP_WRITE_INST|CP_START,p1,p1
     .else
       .err
       .print "cp_write_inst: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg >=3
     .err
     .print "cp_write_inst: too many parameters"
     .exitm
   .endif
;
 .endm
;
;
;
;
;
;
;============================================================================
;  MACRO NAME: cp_advance_temps
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 17, 1988
;
;  FUNCTION:   Transfers the contents of Am29027 registers R-Temp, S-Temp,
;              and I-Temp to register R, register S, and the instruction
;              register, respectively.
;
;  PARAMETERS: none
;
;  USAGE:
;
;    cp_advance_temps
;
;
;
;============================================================================
;
 .macro cp_advance_temps
;
;
   .if $narg!=0
     .err
     .print "cp_advance_temp: takes no parameters"
   .else
     store 1,CP_ADV_TEMPS,gr1,0 ; use gr1 because it's never protected
   .endif
;
 .endm
;
;
;
;
;============================================================================
;  MACRO NAME:  cp_write_mode
;
;  WRITTEN BY:  Bob Perlman
;
;  MOST RECENT UPDATE:  April 17, 1988
;
;  FUNCTION:    Transfers a 64-bit mode specification to the Am29027 mode
;               register
;
;  PARAMETERS:
;    reg      - the Am29000 g.p. register containing the 32 MSBs of the
;               64-bit mode specification to be transferred.
;
;    LSB_reg  - the Am29000 g.p. register containing the 32 LSBs of the
;               64-bit mode specification to be transferred.
;
;  USAGE:
;
;    cp_write_mode  reg [,LSB_reg]
;
;    Either of two forms is acceptable:
;
;               cp_write_mode   reg
;          or   cp_write_mode   reg, LSB_reg
;
;       If LSB_reg is omitted, the LSBs are taken from the next g.p.
;       register.
;
;       Ex:     cp_write_mode  lr2     Transfers the contents of lr2 to
;                                      the most-significant half of the Am29027
;                                      mode register, and the contents of lr3
;                                      to the least-significant half.
;
;               cp_write_mode  lr2,lr5 Transfers the contents of lr2 to
;                                      the most-significant half of the Am29027
;                                      mode register, and the contents of lr5
;                                      to the least-significant half.
;
;
;
;============================================================================
;
 .macro cp_write_mode,p1,p2
;
   .if $narg==0
     .err
     .print "cp_write_mode: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     store 1,CP_WRITE_MODE,%%((&p1)+1),p1
     .exitm
   .endif
;
;
   .if $narg==2
     store 1,CP_WRITE_MODE,p2,p1
     .exitm
   .endif
;
;
   .if $narg>=3
     .err
     .print "cp_write_mode: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_read_dp
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 17, 1988
;
;  FUNCTION:   Transfers the current Am29027 double-precison floating-point
;              result to the Am29000
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register into which the 32 MSBs of the
;              current Am29027 result are to be written.
;
;    LSB_reg - the Am29000 g.p. register into which the 32 LSBs of the
;              current Am29027 result are to be written.
;
;    NO_ERR  - indicates that exception reporting is to be suppressed for this
;              transfer.
;
;  USAGE:
;
;    cp_read_dp  reg [,LSB_reg] [,START]
;
;    Either of two forms is acceptable:
;
;               cp_read_dp   reg
;          or   cp_read_dp   reg, LSB_reg
;
;     If LSB_reg is omitted, the LSBs are written to the next g.p. register.
;
;       Ex:     cp_read_dp   lr2     Transfers the 32 MSBs of the current
;                                    Am29027 result to lr2, and the 32 LSBs
;                                    to lr3.
;
;               cp_read_dp   lr2,lr5 Transfers the 32 MSBs of the current
;                                    Am29027 result to lr2, and the 32 LSBs
;                                    to lr5.
;
;    Exception reporting can be suppressed by appending NO_ERR to either
;    of the above, e.g.:
;
;               cp_read_dp   lr2,NO_ERR
;               cp_read_dp   lr2,lr5,NO_ERR
;
;
;============================================================================
;
 .macro cp_read_dp,p1,p2,p3
;
   .if $narg==0
     .err
     .print "cp_read_dp: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     load 1,CP_READ_LSBS,%%((&p1)+1),0
     load 1,CP_READ_MSBS,p1,0
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","NO_ERR"
       load 1,CP_READ_LSBS|CP_NO_ERR,%%((&p1)+1),0
       load 1,CP_READ_MSBS|CP_NO_ERR,p1,0
       .exitm
     .endif
;
     load 1,CP_READ_LSBS,p2,0
     load 1,CP_READ_MSBS,p1,0
     .exitm
;
   .endif
;
;
   .if $narg==3
;
     .ifeqs "@p3@","NO_ERR"
       load 1,CP_READ_LSBS|CP_NO_ERR,p2,0
       load 1,CP_READ_MSBS|CP_NO_ERR,p1,0
     .else
       .err
       .print "cp_read_dp: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=4
     .err
     .print "cp_read_dp: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_read_sp
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 17, 1988
;
;  FUNCTION:   Transfers the current Am29027 single-precison floating-point
;              result to the Am29000
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register into which the current Am29027
;              result is to be written.
;
;    NO_ERR  - indicates that exception reporting is to be suppressed for this
;              transfer.
;
;  USAGE:
;
;    cp_read_sp  reg [,START]
;
;       Ex:     cp_read_sp   lr2        Transfers the current Am29027 result
;                                       to lr2.
;
;               cp_read_sp   lr2,NO_ERR Transfers the current Am29027 result
;                                       to lr2, and suppresses exception
;                                       reporting for this transfer.
;
;
;============================================================================
;
 .macro cp_read_sp,p1,p2
;
   .if $narg==0
     .err
     .print "cp_read_sp: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     load 1,CP_READ_MSBS,p1,0
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","NO_ERR"
       load 1,CP_READ_MSBS|CP_NO_ERR,p1,0
     .else
       .err
       .print "cp_read_sp: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=3
     .err
     .print "cp_read_sp: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_read_int
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 17, 1988
;
;  FUNCTION:   Transfers the current Am29027 integer result to the Am29000
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register into which the current Am29027
;              result is to be written.
;
;    NO_ERR  - indicates that exception reporting is to be suppressed for this
;              transfer.
;
;  USAGE:
;
;    cp_read_int  reg [,START]
;
;       Ex:     cp_read_int  lr2        Transfers the current Am29027 result
;                                       to lr2.
;
;               cp_read_int  lr2,NO_ERR Transfers the current Am29027 result
;                                       to lr2, and suppresses exception
;                                       reporting for this transfer.
;
;
;============================================================================
;
 .macro cp_read_int,p1,p2
;
   .if $narg==0
     .err
     .print "cp_read_int: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     load 1,CP_READ_LSBS,p1,0
     nop                    ; leave a cycle for the MSBs to come out
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","NO_ERR"
       load 1,CP_READ_LSBS|CP_NO_ERR,p1,0
       nop                    ; leave a cycle for the MSBs to come out
     .else
       .err
       .print "cp_read_int: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=3
     .err
     .print "cp_read_int: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_read_flags
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 17, 1988
;
;  FUNCTION:   Transfers the contents of the Am29027 flag register
;              to the Am29000
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register into which the current Am29027
;              flag register contents are to be written.
;
;    NO_ERR  - indicates that exception reporting is to be suppressed for this
;              transfer.
;
;  USAGE:
;
;    cp_read_flags  reg [,START]
;
;       Ex:     cp_read_flags  lr2        Transfers the Am29027 flag register
;                                         contents to lr2.
;
;               cp_read_flags  lr2,NO_ERR Transfers the Am29027 flag register
;                                         contents to lr2, and suppresses
;                                         exception reporting for this
;                                         transfer.
;
;
;============================================================================
;
 .macro cp_read_flags,p1,p2
;
   .if $narg==0
     .err
     .print "cp_read_flags: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     load 1,CP_READ_FLAGS,p1,0
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","NO_ERR"
       load 1,CP_READ_FLAGS|CP_NO_ERR,p1,0
     .else
       .err
       .print "cp_read_flags: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=3
     .err
     .print "cp_read_flags: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_read_status
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 18, 1988
;
;  FUNCTION:   Transfers the contents of the Am29027 status register
;              to the Am29000
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register into which the current Am29027
;              status register contents are to be written.
;
;    NO_ERR  - indicates that exception reporting is to be suppressed for this
;              transfer.
;
;  USAGE:
;
;    cp_read_status  reg [,START]
;
;       Ex:     cp_read_status  lr2        Transfers the Am29027 status register
;                                          contents to lr2.
;
;               cp_read_status  lr2,NO_ERR Transfers the Am29027 status register
;                                          contents to lr2, and suppresses
;                                          exception reporting for this
;                                          transfer.
;
;
;============================================================================
;
 .macro cp_read_status,p1,p2
;
   .if $narg==0
     .err
     .print "cp_read_status: missing parameter(s)"
   .endif
;
;
   .if $narg==1
     load 1,CP_READ_STATUS,p1,0
     .exitm
   .endif
;
;
   .if $narg==2
;
     .ifeqs "@p2@","NO_ERR"
       load 1,CP_READ_STATUS|CP_NO_ERR,p1,0
     .else
       .err
       .print "cp_read_status: bad parameter list"
     .endif
     .exitm
;
   .endif
;
;
   .if $narg>=3
     .err
     .print "cp_read_status: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_read_state_wd
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 18, 1988
;
;  FUNCTION:   Transfers the next Am29027 state word to the Am29000
;
;  PARAMETERS:
;    reg     - the Am29000 g.p. register into which the next Am29027
;              state word contents are to be written.
;
;  USAGE:
;
;    cp_read_state_wd  reg
;
;       Ex:     cp_read_state_wd  lr2  Transfers the next Am29027 state word
;                                      to lr2.
;
;============================================================================
;
 .macro cp_read_state_wd,p1
;
   .if $narg==0
     .err
     .print "cp_read_state_wd: missing parameter"
   .endif
;
;
   .if $narg==1
     load 1,CP_SAVE_STATE,p1,0
     .exitm
   .endif
;
;
   .if $narg>=2
     .err
     .print "cp_read_state_wd: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_save_state
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 18, 1988
;
;  FUNCTION:   Transfers the current Am29027 state to the Am29000
;
;  PARAMETERS:
;    reg     - the first of 30 Am29000 g.p. registers in which Am29027 state
;              is saved.
;
;  USAGE:
;
;    cp_save_state  reg
;
;    This macro transfers the current Am29027 state to a block of 30 Am29000
;    registers.  State is stored in the following order:
;
;              reg      instruction register
;              reg+1    I-Temp
;              reg+2    R MSBs
;              reg+3    R LSBs
;              reg+4    S MSBs
;              reg+5    S LSBs
;              reg+6    R-Temp MSBs
;              reg+7    R-Temp LSBs
;              reg+8    S-Temp MSBs
;              reg+9    S-Temp LSBs
;              reg+10   status
;              reg+11   precision
;              reg+12   RF0 MSBs
;              reg+13   RF0 LSBs
;                .         .
;                .         .
;                .         .
;              reg+26   RF7 MSBs
;              reg+27   RF7 LSBs
;              reg+28   mode MSBs
;              reg+29   mode LSBs
;
;
;       Ex:     cp_save_state  lr2     Transfers the current Am29027 state to
;                                      the Am29000, starting at lr2.
;
;  NOTES:
;       1) This macro stores all 64-bit quantities in "big-endian" order,
;          i.e. MSBs first.  For example, the 32 MSBs of register R are
;          stored in reg+2, and the 32 LSBs are stored in reg+3.  The Am29027
;          transfers these quantites in "little-endian" order; the macro
;          is responsible for swapping MS and LS words.
;
;============================================================================
;
 .macro cp_save_state,p1
;
   .if $narg==0
     .err
     .print "cp_save_state: missing parameter"
   .endif
;
;
   .if $narg==1
     cp_read_sp p1,NO_ERR
                                    ;guarantee that we're at beginning of
                                    ; save state sequence
     cp_read_state_wd %%((&p1)+ 0)  ; instruction
     cp_read_state_wd %%((&p1)+ 1)  ; I-Temp
     cp_read_state_wd %%((&p1)+ 3)  ; R MSBs
     cp_read_state_wd %%((&p1)+ 2)  ; R LSBs
     cp_read_state_wd %%((&p1)+ 5)  ; S MSBs
     cp_read_state_wd %%((&p1)+ 4)  ; S LSBs
     cp_read_state_wd %%((&p1)+ 7)  ; R-Temp MSBs
     cp_read_state_wd %%((&p1)+ 6)  ; R-Temp LSBs
     cp_read_state_wd %%((&p1)+ 9)  ; S-Temp MSBs
     cp_read_state_wd %%((&p1)+ 8)  ; S-Temp LSBs
     cp_read_state_wd %%((&p1)+10)  ; status
     cp_read_state_wd %%((&p1)+11)  ; precision
     cp_read_state_wd %%((&p1)+13)  ; RF0 MSBs
     cp_read_state_wd %%((&p1)+12)  ; RF0 LSBs
     cp_read_state_wd %%((&p1)+15)  ; RF1 MSBs
     cp_read_state_wd %%((&p1)+14)  ; RF1 LSBs
     cp_read_state_wd %%((&p1)+17)  ; RF2 MSBs
     cp_read_state_wd %%((&p1)+16)  ; RF2 LSBs
     cp_read_state_wd %%((&p1)+19)  ; RF3 MSBs
     cp_read_state_wd %%((&p1)+18)  ; RF3 LSBs
     cp_read_state_wd %%((&p1)+21)  ; RF4 MSBs
     cp_read_state_wd %%((&p1)+20)  ; RF4 LSBs
     cp_read_state_wd %%((&p1)+23)  ; RF5 MSBs
     cp_read_state_wd %%((&p1)+22)  ; RF5 LSBs
     cp_read_state_wd %%((&p1)+25)  ; RF6 MSBs
     cp_read_state_wd %%((&p1)+24)  ; RF6 LSBs
     cp_read_state_wd %%((&p1)+27)  ; RF7 MSBs
     cp_read_state_wd %%((&p1)+26)  ; RF7 LSBs
     cp_read_state_wd %%((&p1)+29)  ; mode MSBs
     cp_read_state_wd %%((&p1)+28)  ; mode LSBs
     .exitm
   .endif
;
;
   .if $narg>=2
     .err
     .print "cp_save_state: too many parameters"
   .endif
;
 .endm
;
;
;
;
;
;============================================================================
;  MACRO NAME: cp_restore_state
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 18, 1988
;
;  FUNCTION:   Restores Am29027 state
;
;  PARAMETERS:
;    reg     - the first of 30 Am29000 g.p. registers containing Am29027
;              state.
;
;    temp    - a scratch register used by cp_restore_state
;
;  USAGE:
;
;    cp_restore_state  reg,temp
;
;    This macro restores Am29027 state by transferring 30 words to the
;    Am29027; these words are taken from a block of Am29000 g.p. registers
;    starting at "reg."  The words are assumed to be stored in the following
;    order:
;
;              reg      instruction register
;              reg+1    I-Temp
;              reg+2    R MSBs
;              reg+3    R LSBs
;              reg+4    S MSBs
;              reg+5    S LSBs
;              reg+6    R-Temp MSBs
;              reg+7    R-Temp LSBs
;              reg+8    S-Temp MSBs
;              reg+9    S-Temp LSBs
;              reg+10   status
;              reg+11   precision
;              reg+12   RF0 MSBs
;              reg+13   RF0 LSBs
;                .         .
;                .         .
;                .         .
;              reg+26   RF7 MSBs
;              reg+27   RF7 LSBs
;              reg+28   mode MSBs
;              reg+29   mode LSBs
;
;
;       Ex:     cp_restore_state  lr2,gr70  Restores Am29027 state by
;                                           transferring a block of 30 words
;                                           that begins at lr2.  Register gr70
;                                           is used as scratch storage by this
;                                           macro.
;
;
;============================================================================
;
 .macro cp_restore_state,p1,p2
;
   .if $narg<=1
     .err
     .print "cp_restore_state: missing parameter(s)"
   .endif
;
;
   .if $narg==2

     const p2,0                     ;clear the status register
     cp_write_status p2
;
     cp_write_mode %%((&p1)+28)     ;restore the mode register
;
     const  p2,0x80000018           ; restore RF0
     consth p2,0x80000018
     cp_write_inst p2
     cp_write_r %%((&p1)+12),START
;
     consth p2,0x90000018           ; restore RF1
     cp_write_inst p2
     cp_write_r %%((&p1)+14),START
;
     consth p2,0xA0000018           ; restore RF2
     cp_write_inst p2
     cp_write_r %%((&p1)+16),START
;
     consth p2,0xB0000018           ; restore RF3
     cp_write_inst p2
     cp_write_r %%((&p1)+18),START
;
     consth p2,0xC0000018           ; restore RF4
     cp_write_inst p2
     cp_write_r %%((&p1)+20),START
;
     consth p2,0xD0000018           ; restore RF5
     cp_write_inst p2
     cp_write_r %%((&p1)+22),START
;
     consth p2,0xE0000018           ; restore RF6
     cp_write_inst p2
     cp_write_r %%((&p1)+24),START
;
     consth p2,0xF0000018           ; restore RF7
     cp_write_inst p2
     cp_write_r %%((&p1)+26),START
;
     cp_read_sp p2                  ; do a dummy read, to guarantee that
                                    ; the last operation is complete
;
     cp_write_prec %%((&p1)+11)     ; restore precision
;
     cp_write_r %%((&p1)+2)         ; restore R
     cp_write_s %%((&p1)+4)         ; restore S
     cp_write_inst %%((&p1)+0)      ; restore instruction
     cp_advance_temps               ; move R,S, and inst. to working registers
;
     cp_write_r %%((&p1)+6)         ; restore R-Temp
     cp_write_s %%((&p1)+8)         ; restore S-Temp
     cp_write_inst %%((&p1)+1)      ; restore I-Temp
;
; restore the status register, retime last operation
;
     cp_write_status %%((&p1)+10),RESTORE
;
     .exitm
   .endif
;
;
   .if $narg>=3
     .err
     .print "cp_restore_state: too many parameters"
   .endif
;
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_build_inst
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 24, 1988
;                    :  January 4, 1989 Rich Parker
;
;  FUNCTION:   Builds a 32-bit Am29027 instruction in an Am29000 g.p.
;              register.
;
;  PARAMETERS:
;    reg       - the Am29000 g.p. register into which the instruction word
;                is to be written
;
;    op_code   - mnemonic specifying the operation to be performed
;                (e.g. FADD, P_TIMES_Q)
;
;    precision - precision specification for destination, source operands:
;                  D_S - double-prec. result, single-prec. input(s)
;                  D_D - double-prec. result, double-prec. input(s)
;                  S_S - single-prec. result, single-prec. input(s)
;                  S_D - single-prec. result, double-prec. input(s)
;
;    dest      - destination for the operation result:
;                  RF0 - store result in Am29027 register file location RF0
;                  RF1 - store result in Am29027 register file location RF1
;                  RF2 - store result in Am29027 register file location RF2
;                  RF3 - store result in Am29027 register file location RF3
;                  RF4 - store result in Am29027 register file location RF4
;                  RF5 - store result in Am29027 register file location RF5
;                  RF6 - store result in Am29027 register file location RF6
;                  RF7 - store result in Am29027 register file location RF7
;                  GP  - result is to be stored in an Am29000 g.p. register
;                          with a read_dp, read_sp, or read_int macro.
;
;    source1,
;    source2,
;    source3   - source operand specifications:
;                  R    - take source from Am29027 register R
;                  S    - take source from Am29027 register S
;                  RF0  - take source from Am29027 register file location RF0
;                  RF1  - take source from Am29027 register file location RF1
;                  RF2  - take source from Am29027 register file location RF2
;                  RF3  - take source from Am29027 register file location RF3
;                  RF4  - take source from Am29027 register file location RF4
;                  RF5  - take source from Am29027 register file location RF5
;                  RF6  - take source from Am29027 register file location RF6
;                  RF7  - take source from Am29027 register file location RF7
;                  0    - source is 0
;                  ONE_HALF - source is constant .5 (f.p. operations only)
;                  IMINUS1 - source is constant -1 (integer operations only)
;                  1    - source is constant 1
;                  2    - source is constant 2
;                  3    - source is constant 3
;                  PI   - source is constant pi (f.p. operations only)
;                  IMINUSMAX - source is -(2**63) (integer operations only)
;
;
;  USAGE:
;
;    cp_build_inst  reg,op_code,[precision,]dest,source1[,source2][,source3]
;
;    Op-codes fall into two categories: those that correspond to Am29000
;    floating-point op-codes, and for which the precision is implicit (e.g.
;    FADD, DMUL); and those that correspond to Am29027 base operations
;    (e.g. P_PLUS_T, P_TIMES_Q), and which require an explicit precision
;    specification.
;
;    Every operation specified must have a destination; if the operation
;    does not write a result to the Am29027 register file, destination GP
;    must be specified.  The number of source operands specified must agree
;    with the number of source operands required by the operation specified.
;
;    Ex:
;
;       cp_build_inst lr2,FADD,RF7,R,S
;                                         Builds an instruction word to
;                                         perform the operation:
;                                            RF7 <- R + S
;                                         where R, S, and RF7 are single-
;                                         precision f.p. operands.  The
;                                         instruction word is placed in lr2.
;
;       cp_build_inst gr119,DMUL,GP,R,ONE_HALF
;                                         Builds an instruction word to
;                                         perform the operation:
;                                                R * .5
;                                         where R, .5, and the result
;                                         are double-precision f.p. operands.
;                                         The result is not written to the
;                                         Am29027 register file.  The
;                                         instruction word is written to
;                                         gr119.
;
;
;       cp_build_inst lr3,MIN_P_AND_T,S_D,RF7,R,S
;                                         Builds an instruction word to
;                                         perform the operation:
;                                            RF7 <- smaller of(R,S)
;                                         where R and S are double-precision
;                                         f.p. operands, and RF7 is a single-
;                                         precison f.p. operand.  The
;                                         instruction word is written to
;                                         lr3.
;
;
;       cp_build_inst gr97,I_P_TIMES_Q,S_S,GP,R,2
;                                         Builds an instruction word to
;                                         perform the operation:
;                                                R * 2
;                                         where R, .5, and the result
;                                         are single-precision integer operands.
;                                         The result is not written to the
;                                         Am29027 register file.  The
;                                         instruction word is written to
;                                         gr97
;
;
;       cp_build_inst lr7,ABS_P,D_D,RF6,S
;                                         Builds an instruction word to
;                                         perform the operation:
;                                                RF6 <- |S|
;                                         where S and RF7 are double-precision
;                                         f.p. operands.  The instruction
;                                         word is written to gr7.
;
;
;       cp_build_inst gr127,PQ_PLUS_T,D_D,RF6,R,S,RF6
;                                         Builds an instruction word to
;                                         perform the operation:
;                                           RF6 <- (R * S) + RF6
;                                         where R, S and the result are
;                                         double-precision f.p. operands.
;                                         The instruction word is written
;                                         to gr127.
;
;
;
;============================================================================
;
 .macro cp_build_inst,p1,p2,p3,p4,p5,p6,p7
;
   .if $narg<=3
     .err
     .print "cp_build_inst: missing parameter(s)"
     .exitm
   .endif
;
; classify operation type
;
   .set _cp_op_type,255

   _cp_set_op_params  p2,FADD,1,5,4,0,5
   _cp_set_op_params  p2,DADD,1,5,4,0,5
   _cp_set_op_params  p2,FSUB,1,5,4,0,5
   _cp_set_op_params  p2,DSUB,1,5,4,0,5
   _cp_set_op_params  p2,FMUL,1,5,4,5,0
   _cp_set_op_params  p2,DMUL,1,5,4,5,0
   _cp_set_op_params  p2,FEQ,1,5,4,0,5
   _cp_set_op_params  p2,DEQ,1,5,4,0,5
   _cp_set_op_params  p2,FGE,1,5,4,0,5
   _cp_set_op_params  p2,DGE,1,5,4,0,5
   _cp_set_op_params  p2,FGT,1,5,4,0,5
   _cp_set_op_params  p2,DGT,1,5,4,0,5
   _cp_set_op_params  p2,CONVERT_I_TO_F,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_I_TO_D,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_F_TO_I,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_D_TO_I,1,4,0,0,4
;
; The next two lines were corrected on 1-4-89, Rich Parker
;
   _cp_set_op_params  p2,CONVERT_F_TO_D,1,4,4,0,0
   _cp_set_op_params  p2,CONVERT_D_TO_F,1,4,4,0,0
;
   _cp_set_op_params  p2,PASS_P,0,5,5,0,0
   _cp_set_op_params  p2,MINUSP,0,5,5,0,0
   _cp_set_op_params  p2,ABSP,0,5,5,0,0
   _cp_set_op_params  p2,SIGNT_TIMES_ABSP,0,6,6,0,5
   _cp_set_op_params  p2,P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,MINUSP_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,MINUSP_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABS_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABS_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABSP_PLUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,ABSP_MINUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,ABS_ABSP_MINUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,MINUSP_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,ABS_P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,COMPARE_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MAX_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MAX_ABSP_AND_ABST,0,6,5,0,6
   _cp_set_op_params  p2,MIN_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MIN_ABSP_AND_ABST,0,6,5,0,6
   _cp_set_op_params  p2,LIMIT_P_TO_MAGT,0,6,5,0,6
   _cp_set_op_params  p2,CONVERT_T_TO_INT,0,5,0,0,5
   _cp_set_op_params  p2,SCALE_T_TO_INT_BY_Q,0,6,0,6,5
   _cp_set_op_params  p2,PQ_PLUS_T,0,7,5,6,7
   _cp_set_op_params  p2,MINUSPQ_PLUS_T,0,7,5,6,7
   _cp_set_op_params  p2,PQ_MINUS_T,0,7,5,6,7
   _cp_set_op_params  p2,MINUSPQ_MINUS_T,0,7,5,6,7
   _cp_set_op_params  p2,ABSPQ_PLUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,MINUSABSPQ_PLUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,ABSPQ_MINUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,ROUND_T_TO_INT,0,5,0,0,5
   _cp_set_op_params  p2,RECIPROCAL_OF_P,0,5,5,0,0
   _cp_set_op_params  p2,CONVERT_T_TO_ALT,0,5,0,0,5
   _cp_set_op_params  p2,CONVERT_T_FROM_ALT,0,5,0,0,5
   _cp_set_op_params  p2,I_PASS_P,0,5,5,0,0
   _cp_set_op_params  p2,I_MINUSP,0,5,5,0,0
   _cp_set_op_params  p2,I_ABSP,0,5,5,0,0
   _cp_set_op_params  p2,I_SIGNT_TIMES_ABSP,0,6,6,0,5
   _cp_set_op_params  p2,I_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MINUSP_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_ABS_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_ABS_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_COMPARE_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MAX_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MIN_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_CONVERT_T_TO_FLOAT,0,5,0,0,5
   _cp_set_op_params  p2,I_SCALE_T_TO_FLOAT_BY_Q,0,6,0,6,5
   _cp_set_op_params  p2,I_P_OR_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_XOR_T,0,6,5,0,6
   _cp_set_op_params  p2,I_NOT_T,0,5,0,0,5
   _cp_set_op_params  p2,I_LSHIFT_P_BY_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_ASHIFT_P_BY_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_FSHIFT_PT_BY_Q,0,7,5,7,6
   _cp_set_op_params  p2,MOVE_P,0,5,5,0,0
;
;
; if we couldn't find the op_code, flag an error
;
    .if _cp_op_type>=2
      .err
      .print "cp_build_inst: invalid Am29027 instruction mnemonic"
      .exitm
    .endif
;
; if number of parameters is incorrect, flag error
;
    .if $narg!=_cp_no_params
      .err
      .print "cp_build_inst: incorrect number of parameters"
      .exitm
    .endif
;
; find correct value for precision field, if appropriate
;
    .set _cp_prec_field,0 ; ** CORRECTION (1/4/89 ROP)
    .if _cp_op_type==0    ; need to look for precision
      .set _cp_found_precision,0
      .ifeqs "@p3@","D_D"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","D_S"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","S_D"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","S_S"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .if _cp_found_precision==0
        .err
        .print "cp_build_inst: missing precision field"
        .exitm
      .endif
    .endif
;
; find value for destination field
;
    .if _cp_op_type==0
      .set _cp_dest_field_val,CP_DEST_EQ_@p4
    .else
      .set _cp_dest_field_val,CP_DEST_EQ_@p3
    .endif
;
; find correct value for p select field
;
     .if _cp_p_paramno==0
       .set _cp_p_field_val,0x00000000
     .endif
     .if _cp_p_paramno==4
       .set _cp_p_field_val,CP_P_EQ_@p4
     .endif
     .if _cp_p_paramno==5
       .set _cp_p_field_val,CP_P_EQ_@p5
     .endif
     .if _cp_p_paramno==6
       .set _cp_p_field_val,CP_P_EQ_@p6
     .endif
     .if _cp_p_paramno==7
       .set _cp_p_field_val,CP_P_EQ_@p7
     .endif
     .ifeqs "@p2@","I_NOT_T"
       .set _cp_p_field_val,CP_P_EQ_IMINUS1
     .endif
;
; find correct value for q select field
;
     .if _cp_q_paramno==0
       .set _cp_q_field_val,0x00000000
     .endif
     .if _cp_q_paramno==4
       .set _cp_q_field_val,CP_Q_EQ_@p4
     .endif
     .if _cp_q_paramno==5
       .set _cp_q_field_val,CP_Q_EQ_@p5
     .endif
     .if _cp_q_paramno==6
       .set _cp_q_field_val,CP_Q_EQ_@p6
     .endif
     .if _cp_q_paramno==7
       .set _cp_q_field_val,CP_Q_EQ_@p7
     .endif
;
; find correct value for t select field
;
     .if _cp_t_paramno==0
       .set _cp_t_field_val,0x00000000
     .endif
     .if _cp_t_paramno==4
       .set _cp_t_field_val,CP_T_EQ_@p4
     .endif
     .if _cp_t_paramno==5
       .set _cp_t_field_val,CP_T_EQ_@p5
     .endif
     .if _cp_t_paramno==6
       .set _cp_t_field_val,CP_T_EQ_@p6
     .endif
     .if _cp_t_paramno==7
       .set _cp_t_field_val,CP_T_EQ_@p7
     .endif
;
;
     .set _cp_inst_word,CP_@p2@|_cp_prec_field|_cp_dest_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_p_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_q_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_t_field_val

     const  p1,_cp_inst_word
     consth p1,_cp_inst_word
;
 .endm
;
;
;
 .macro _cp_set_op_params,par1,par2,par3,par4,par5,par6,par7
   .ifeqs "@par1@","@par2@"
     .set _cp_op_type,par3
     .set _cp_no_params,par4
     .set _cp_p_paramno,par5
     .set _cp_q_paramno,par6
     .set _cp_t_paramno,par7
    .endif
 .endm
;
;
;
;============================================================================
;  MACRO NAME: cp_build_inst_h
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 24, 1988
;                    :  January 4, 1989 Rich Parker
;
;  FUNCTION:   Builds a 16 MSBs of a 32-bit Am29027 instruction in an
;              Am29000 g.p. register.
;
;  PARAMETERS:
;    reg       - the Am29000 g.p. register into which the instruction word
;                is to be written
;
;    op_code   - mnemonic specifying the operation to be performed
;                (e.g. FADD, P_TIMES_Q)
;
;    precision - precision specification for destination, source operands:
;                  D_S - double-prec. result, single-prec. input(s)
;                  D_D - double-prec. result, double-prec. input(s)
;                  S_S - single-prec. result, single-prec. input(s)
;                  S_D - single-prec. result, double-prec. input(s)
;
;    dest      - destination for the operation result:
;                  RF0 - store result in Am29027 register file location RF0
;                  RF1 - store result in Am29027 register file location RF1
;                  RF2 - store result in Am29027 register file location RF2
;                  RF3 - store result in Am29027 register file location RF3
;                  RF4 - store result in Am29027 register file location RF4
;                  RF5 - store result in Am29027 register file location RF5
;                  RF6 - store result in Am29027 register file location RF6
;                  RF7 - store result in Am29027 register file location RF7
;                  GP  - result is to be stored in an Am29000 g.p. register
;                          with a read_dp, read_sp, or read_int macro.
;
;    source1,
;    source2,
;    source3   - source operand specifications:
;                  R    - take source from Am29027 register R
;                  S    - take source from Am29027 register S
;                  RF0  - take source from Am29027 register file location RF0
;                  RF1  - take source from Am29027 register file location RF1
;                  RF2  - take source from Am29027 register file location RF2
;                  RF3  - take source from Am29027 register file location RF3
;                  RF4  - take source from Am29027 register file location RF4
;                  RF5  - take source from Am29027 register file location RF5
;                  RF6  - take source from Am29027 register file location RF6
;                  RF7  - take source from Am29027 register file location RF7
;                  0    - source is 0
;                  ONE_HALF - source is constant .5 (f.p. operations only)
;                  IMINUS1 - source is constant -1 (integer operations only)
;                  1    - source is constant 1
;                  2    - source is constant 2
;                  3    - source is constant 3
;                  PI   - source is constant pi (f.p. operations only)
;                  IMINUSMAX - source is -(2**63) (integer operations only)
;
;
;  USAGE:
;
;    cp_build_inst_h reg,op_code,[precision,]dest,source1[,source2][,source3]
;
;    This macro is similar to cp_build_inst, but creates only the 16 MSBs
;    of the 32-bit Am29027 instruction word.  This macro is useful in cases
;    where the 16 LSBs of instruction word, which specify the operation
;    to be performed, already exist in an Am29000 g.p. register, but where
;    the 16 MSBs, which specify operand sources and destination, must be
;    changed.  In such cases, one Am29000 instruction can be saved by using
;    cp_build_inst_h instead of cp_build_inst.
;
;    Syntax and usage are identical to that of cp_build_inst.
;
;    NOTE: This macro references macro _cp_set_op_params, which appears
;          in the assembly listing for macro _cp_build_inst.
;
;
;
;
;============================================================================
;
 .macro cp_build_inst_h,p1,p2,p3,p4,p5,p6,p7
;
   .if $narg<=3
     .err
     .print "cp_build_inst_h: missing parameter(s)"
     .exitm
   .endif
;
; classify operation type
;
   .set _cp_op_type,255

   _cp_set_op_params  p2,FADD,1,5,4,0,5
   _cp_set_op_params  p2,DADD,1,5,4,0,5
   _cp_set_op_params  p2,FSUB,1,5,4,0,5
   _cp_set_op_params  p2,DSUB,1,5,4,0,5
   _cp_set_op_params  p2,FMUL,1,5,4,5,0
   _cp_set_op_params  p2,DMUL,1,5,4,5,0
   _cp_set_op_params  p2,FEQ,1,5,4,0,5
   _cp_set_op_params  p2,DEQ,1,5,4,0,5
   _cp_set_op_params  p2,FGE,1,5,4,0,5
   _cp_set_op_params  p2,DGE,1,5,4,0,5
   _cp_set_op_params  p2,FGT,1,5,4,0,5
   _cp_set_op_params  p2,DGT,1,5,4,0,5
   _cp_set_op_params  p2,CONVERT_I_TO_F,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_I_TO_D,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_F_TO_I,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_D_TO_I,1,4,0,0,4
;
; The next two lines were corrected on 1-4-89, Rich Parker
;
   _cp_set_op_params  p2,CONVERT_F_TO_D,1,4,4,0,0
   _cp_set_op_params  p2,CONVERT_D_TO_F,1,4,4,0,0
;
   _cp_set_op_params  p2,PASS_P,0,5,5,0,0
   _cp_set_op_params  p2,MINUSP,0,5,5,0,0
   _cp_set_op_params  p2,ABSP,0,5,5,0,0
   _cp_set_op_params  p2,SIGNT_TIMES_ABSP,0,6,6,0,5
   _cp_set_op_params  p2,P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,MINUSP_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,MINUSP_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABS_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABS_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABSP_PLUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,ABSP_MINUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,ABS_ABSP_MINUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,MINUSP_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,ABS_P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,COMPARE_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MAX_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MAX_ABSP_AND_ABST,0,6,5,0,6
   _cp_set_op_params  p2,MIN_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MIN_ABSP_AND_ABST,0,6,5,0,6
   _cp_set_op_params  p2,LIMIT_P_TO_MAGT,0,6,5,0,6
   _cp_set_op_params  p2,CONVERT_T_TO_INT,0,5,0,0,5
   _cp_set_op_params  p2,SCALE_T_TO_INT_BY_Q,0,6,0,6,5
   _cp_set_op_params  p2,PQ_PLUS_T,0,7,5,6,7
   _cp_set_op_params  p2,MINUSPQ_PLUS_T,0,7,5,6,7
   _cp_set_op_params  p2,PQ_MINUS_T,0,7,5,6,7
   _cp_set_op_params  p2,MINUSPQ_MINUS_T,0,7,5,6,7
   _cp_set_op_params  p2,ABSPQ_PLUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,MINUSABSPQ_PLUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,ABSPQ_MINUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,ROUND_T_TO_INT,0,5,0,0,5
   _cp_set_op_params  p2,RECIPROCAL_OF_P,0,5,5,0,0
   _cp_set_op_params  p2,CONVERT_T_TO_ALT,0,5,0,0,5
   _cp_set_op_params  p2,CONVERT_T_FROM_ALT,0,5,0,0,5
   _cp_set_op_params  p2,I_PASS_P,0,5,5,0,0
   _cp_set_op_params  p2,I_MINUSP,0,5,5,0,0
   _cp_set_op_params  p2,I_ABSP,0,5,5,0,0
   _cp_set_op_params  p2,I_SIGNT_TIMES_ABSP,0,6,6,0,5
   _cp_set_op_params  p2,I_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MINUSP_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_ABS_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_ABS_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_COMPARE_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MAX_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MIN_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_CONVERT_T_TO_FLOAT,0,5,0,0,5
   _cp_set_op_params  p2,I_SCALE_T_TO_FLOAT_BY_Q,0,6,0,6,5
   _cp_set_op_params  p2,I_P_OR_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_XOR_T,0,6,5,0,6
   _cp_set_op_params  p2,I_NOT_T,0,5,0,0,5
   _cp_set_op_params  p2,I_LSHIFT_P_BY_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_ASHIFT_P_BY_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_FSHIFT_PT_BY_Q,0,7,5,7,6
   _cp_set_op_params  p2,MOVE_P,0,5,5,0,0
;
;
; if we couldn't find the op_code, flag an error
;
    .if _cp_op_type>=2
      .err
      .print "cp_build_inst_h: invalid Am29027 instruction mnemonic"
      .exitm
    .endif
;
; if number of parameters is incorrect, flag error
;
    .if $narg!=_cp_no_params
      .err
      .print "cp_build_inst_h: incorrect number of parameters"
      .exitm
    .endif
;
; find correct value for precision field, if appropriate
;
    .set _cp_prec_field,0 ; ** CORRECTION (1-4-89 Rich Parker)
    .if _cp_op_type==0    ; need to look for precision
      .set _cp_found_precision,0
      .ifeqs "@p3@","D_D"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","D_S"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","S_D"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","S_S"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .if _cp_found_precision==0
        .err
        .print "cp_build_inst_h: missing precision field"
        .exitm
      .endif
    .endif
;
; find value for destination field
;
    .if _cp_op_type==0
      .set _cp_dest_field_val,CP_DEST_EQ_@p4
    .else
      .set _cp_dest_field_val,CP_DEST_EQ_@p3
    .endif
;
; find correct value for p select field
;
     .if _cp_p_paramno==0
       .set _cp_p_field_val,0x00000000
     .endif
     .if _cp_p_paramno==4
       .set _cp_p_field_val,CP_P_EQ_@p4
     .endif
     .if _cp_p_paramno==5
       .set _cp_p_field_val,CP_P_EQ_@p5
     .endif
     .if _cp_p_paramno==6
       .set _cp_p_field_val,CP_P_EQ_@p6
     .endif
     .if _cp_p_paramno==7
       .set _cp_p_field_val,CP_P_EQ_@p7
     .endif
     .ifeqs "@p2@","I_NOT_T"
       .set _cp_p_field_val,CP_P_EQ_IMINUS1
     .endif
;
; find correct value for q select field
;
     .if _cp_q_paramno==0
       .set _cp_q_field_val,0x00000000
     .endif
     .if _cp_q_paramno==4
       .set _cp_q_field_val,CP_Q_EQ_@p4
     .endif
     .if _cp_q_paramno==5
       .set _cp_q_field_val,CP_Q_EQ_@p5
     .endif
     .if _cp_q_paramno==6
       .set _cp_q_field_val,CP_Q_EQ_@p6
     .endif
     .if _cp_q_paramno==7
       .set _cp_q_field_val,CP_Q_EQ_@p7
     .endif
;
; find correct value for t select field
;
     .if _cp_t_paramno==0
       .set _cp_t_field_val,0x00000000
     .endif
     .if _cp_t_paramno==4
       .set _cp_t_field_val,CP_T_EQ_@p4
     .endif
     .if _cp_t_paramno==5
       .set _cp_t_field_val,CP_T_EQ_@p5
     .endif
     .if _cp_t_paramno==6
       .set _cp_t_field_val,CP_T_EQ_@p6
     .endif
     .if _cp_t_paramno==7
       .set _cp_t_field_val,CP_T_EQ_@p7
     .endif
;
;
     .set _cp_inst_word,CP_@p2@|_cp_prec_field|_cp_dest_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_p_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_q_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_t_field_val
;
     consth p1,_cp_inst_word
;
 .endm
;
;
;
;
;============================================================================
;  MACRO NAME: cp_build_inst_l
;
;  WRITTEN BY: Bob Perlman
;
;  MOST RECENT UPDATE:  April 24, 1988
;                    :  January 4, 1989 Rich Parker
;
;  FUNCTION:   Builds a 16 LSBs of a 32-bit Am29027 instruction in an
;              Am29000 g.p. register; the 16 MSBs of the register are
;              set to 0..
;
;  PARAMETERS:
;    reg       - the Am29000 g.p. register into which the instruction word
;                is to be written
;
;    op_code   - mnemonic specifying the operation to be performed
;                (e.g. FADD, P_TIMES_Q)
;
;    precision - precision specification for destination, source operands:
;                  D_S - double-prec. result, single-prec. input(s)
;                  D_D - double-prec. result, double-prec. input(s)
;                  S_S - single-prec. result, single-prec. input(s)
;                  S_D - single-prec. result, double-prec. input(s)
;
;    dest      - destination for the operation result:
;                  RF0 - store result in Am29027 register file location RF0
;                  RF1 - store result in Am29027 register file location RF1
;                  RF2 - store result in Am29027 register file location RF2
;                  RF3 - store result in Am29027 register file location RF3
;                  RF4 - store result in Am29027 register file location RF4
;                  RF5 - store result in Am29027 register file location RF5
;                  RF6 - store result in Am29027 register file location RF6
;                  RF7 - store result in Am29027 register file location RF7
;                  GP  - result is to be stored in an Am29000 g.p. register
;                          with a read_dp, read_sp, or read_int macro.
;
;    source1,
;    source2,
;    source3   - source operand specifications:
;                  R    - take source from Am29027 register R
;                  S    - take source from Am29027 register S
;                  RF0  - take source from Am29027 register file location RF0
;                  RF1  - take source from Am29027 register file location RF1
;                  RF2  - take source from Am29027 register file location RF2
;                  RF3  - take source from Am29027 register file location RF3
;                  RF4  - take source from Am29027 register file location RF4
;                  RF5  - take source from Am29027 register file location RF5
;                  RF6  - take source from Am29027 register file location RF6
;                  RF7  - take source from Am29027 register file location RF7
;                  0    - source is 0
;                  ONE_HALF - source is constant .5 (f.p. operations only)
;                  IMINUS1 - source is constant -1 (integer operations only)
;                  1    - source is constant 1
;                  2    - source is constant 2
;                  3    - source is constant 3
;                  PI   - source is constant pi (f.p. operations only)
;                  IMINUSMAX - source is -(2**63) (integer operations only)
;
;
;  USAGE:
;
;    cp_build_inst_l reg,op_code,[precision,]dest,source1[,source2][,source3]
;
;    This macro is similar to cp_build_inst, but creates only the 16 LSBs
;    of the 32-bit Am29027 instruction word; the 16 MSBs of the target
;    register are set to 0.  This macro is useful in cases
;    where it is helpful to specify instruction LSBs and MSBs separately,
;    to improve instruction scheduling.
;
;    Syntax and usage are identical to that of cp_build_inst.
;
;    NOTE: This macro references macro _cp_set_op_params, which appears
;          in the assembly listing for macro _cp_build_inst.
;
;
;============================================================================
;
 .macro cp_build_inst_l,p1,p2,p3,p4,p5,p6,p7
;
   .if $narg<=3
     .err
     .print "cp_build_inst_h: missing parameter(s)"
     .exitm
   .endif
;
; classify operation type
;
   .set _cp_op_type,255

   _cp_set_op_params  p2,FADD,1,5,4,0,5
   _cp_set_op_params  p2,DADD,1,5,4,0,5
   _cp_set_op_params  p2,FSUB,1,5,4,0,5
   _cp_set_op_params  p2,DSUB,1,5,4,0,5
   _cp_set_op_params  p2,FMUL,1,5,4,5,0
   _cp_set_op_params  p2,DMUL,1,5,4,5,0
   _cp_set_op_params  p2,FEQ,1,5,4,0,5
   _cp_set_op_params  p2,DEQ,1,5,4,0,5
   _cp_set_op_params  p2,FGE,1,5,4,0,5
   _cp_set_op_params  p2,DGE,1,5,4,0,5
   _cp_set_op_params  p2,FGT,1,5,4,0,5
   _cp_set_op_params  p2,DGT,1,5,4,0,5
   _cp_set_op_params  p2,CONVERT_I_TO_F,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_I_TO_D,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_F_TO_I,1,4,0,0,4
   _cp_set_op_params  p2,CONVERT_D_TO_I,1,4,0,0,4
;
; The next two lines were corrected on 1-4-89, Rich Parker
;
   _cp_set_op_params  p2,CONVERT_F_TO_D,1,4,4,0,0
   _cp_set_op_params  p2,CONVERT_D_TO_F,1,4,4,0,0
;
   _cp_set_op_params  p2,PASS_P,0,5,5,0,0
   _cp_set_op_params  p2,MINUSP,0,5,5,0,0
   _cp_set_op_params  p2,ABSP,0,5,5,0,0
   _cp_set_op_params  p2,SIGNT_TIMES_ABSP,0,6,6,0,5
   _cp_set_op_params  p2,P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,MINUSP_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,MINUSP_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABS_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABS_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,ABSP_PLUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,ABSP_MINUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,ABS_ABSP_MINUS_ABST,0,6,5,0,6
   _cp_set_op_params  p2,P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,MINUSP_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,ABS_P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,COMPARE_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MAX_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MAX_ABSP_AND_ABST,0,6,5,0,6
   _cp_set_op_params  p2,MIN_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,MIN_ABSP_AND_ABST,0,6,5,0,6
   _cp_set_op_params  p2,LIMIT_P_TO_MAGT,0,6,5,0,6
   _cp_set_op_params  p2,CONVERT_T_TO_INT,0,5,0,0,5
   _cp_set_op_params  p2,SCALE_T_TO_INT_BY_Q,0,6,0,6,5
   _cp_set_op_params  p2,PQ_PLUS_T,0,7,5,6,7
   _cp_set_op_params  p2,MINUSPQ_PLUS_T,0,7,5,6,7
   _cp_set_op_params  p2,PQ_MINUS_T,0,7,5,6,7
   _cp_set_op_params  p2,MINUSPQ_MINUS_T,0,7,5,6,7
   _cp_set_op_params  p2,ABSPQ_PLUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,MINUSABSPQ_PLUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,ABSPQ_MINUS_ABST,0,7,5,6,7
   _cp_set_op_params  p2,ROUND_T_TO_INT,0,5,0,0,5
   _cp_set_op_params  p2,RECIPROCAL_OF_P,0,5,5,0,0
   _cp_set_op_params  p2,CONVERT_T_TO_ALT,0,5,0,0,5
   _cp_set_op_params  p2,CONVERT_T_FROM_ALT,0,5,0,0,5
   _cp_set_op_params  p2,I_PASS_P,0,5,5,0,0
   _cp_set_op_params  p2,I_MINUSP,0,5,5,0,0
   _cp_set_op_params  p2,I_ABSP,0,5,5,0,0
   _cp_set_op_params  p2,I_SIGNT_TIMES_ABSP,0,6,6,0,5
   _cp_set_op_params  p2,I_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MINUSP_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_ABS_P_PLUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_ABS_P_MINUS_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_TIMES_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_COMPARE_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MAX_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_MIN_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_CONVERT_T_TO_FLOAT,0,5,0,0,5
   _cp_set_op_params  p2,I_SCALE_T_TO_FLOAT_BY_Q,0,6,0,6,5
   _cp_set_op_params  p2,I_P_OR_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_AND_T,0,6,5,0,6
   _cp_set_op_params  p2,I_P_XOR_T,0,6,5,0,6
   _cp_set_op_params  p2,I_NOT_T,0,5,0,0,5
   _cp_set_op_params  p2,I_LSHIFT_P_BY_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_ASHIFT_P_BY_Q,0,6,5,6,0
   _cp_set_op_params  p2,I_FSHIFT_PT_BY_Q,0,7,5,7,6
   _cp_set_op_params  p2,MOVE_P,0,5,5,0,0
;
;
; if we couldn't find the op_code, flag an error
;
    .if _cp_op_type>=2
      .err
      .print "cp_build_inst_h: invalid Am29027 instruction mnemonic"
      .exitm
    .endif
;
; if number of parameters is incorrect, flag error
;
    .if $narg!=_cp_no_params
      .err
      .print "cp_build_inst_h: incorrect number of parameters"
      .exitm
    .endif
;
; find correct value for precision field, if appropriate
;
    .set _cp_prec_field,0 ; CORRECTION (1-4-89 Rich Parker)
    .if _cp_op_type==0    ; need to look for precision
      .set _cp_found_precision,0
      .ifeqs "@p3@","D_D"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","D_S"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","S_D"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .ifeqs "@p3@","S_S"
        .set _cp_prec_field,CP_@p3
        .set _cp_found_precision,1
      .endif
      .if _cp_found_precision==0
        .err
        .print "cp_build_inst_h: missing precision field"
        .exitm
      .endif
    .endif
;
; find value for destination field
;
    .if _cp_op_type==0
      .set _cp_dest_field_val,CP_DEST_EQ_@p4
    .else
      .set _cp_dest_field_val,CP_DEST_EQ_@p3
    .endif
;
; find correct value for p select field
;
     .if _cp_p_paramno==0
       .set _cp_p_field_val,0x00000000
     .endif
     .if _cp_p_paramno==4
       .set _cp_p_field_val,CP_P_EQ_@p4
     .endif
     .if _cp_p_paramno==5
       .set _cp_p_field_val,CP_P_EQ_@p5
     .endif
     .if _cp_p_paramno==6
       .set _cp_p_field_val,CP_P_EQ_@p6
     .endif
     .if _cp_p_paramno==7
       .set _cp_p_field_val,CP_P_EQ_@p7
     .endif
     .ifeqs "@p2@","I_NOT_T"
       .set _cp_p_field_val,CP_P_EQ_IMINUS1
     .endif
;
; find correct value for q select field
;
     .if _cp_q_paramno==0
       .set _cp_q_field_val,0x00000000
     .endif
     .if _cp_q_paramno==4
       .set _cp_q_field_val,CP_Q_EQ_@p4
     .endif
     .if _cp_q_paramno==5
       .set _cp_q_field_val,CP_Q_EQ_@p5
     .endif
     .if _cp_q_paramno==6
       .set _cp_q_field_val,CP_Q_EQ_@p6
     .endif
     .if _cp_q_paramno==7
       .set _cp_q_field_val,CP_Q_EQ_@p7
     .endif
;
; find correct value for t select field
;
     .if _cp_t_paramno==0
       .set _cp_t_field_val,0x00000000
     .endif
     .if _cp_t_paramno==4
       .set _cp_t_field_val,CP_T_EQ_@p4
     .endif
     .if _cp_t_paramno==5
       .set _cp_t_field_val,CP_T_EQ_@p5
     .endif
     .if _cp_t_paramno==6
       .set _cp_t_field_val,CP_T_EQ_@p6
     .endif
     .if _cp_t_paramno==7
       .set _cp_t_field_val,CP_T_EQ_@p7
     .endif
;
;
     .set _cp_inst_word,CP_@p2@|_cp_prec_field|_cp_dest_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_p_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_q_field_val
     .set _cp_inst_word,_cp_inst_word|_cp_t_field_val
;
     const p1,_cp_inst_word
;
 .endm
;
; end of file fpsymbol.h
