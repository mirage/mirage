; @(#)intrinsi.h	1.4 90/10/14 20:56:06, Copyright 1988, 1989, 1990 AMD
; start of file intrinsi.h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1990 Advanced Micro Devices, Inc.
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
; 
  .title "QTC Intrinsics Header file"
;
;    Floating point library package for AMD 29000 family
;
;    Copyright 1988 Advanced Micro Devices, Inc.
;
;    All rights reserved
;
;    Developed for AMD by Quantitative Technology Corporation
;                         8700 SW Creekside Place Suite D
;                         Beaverton OR 97005
;                         (503) 626-3081
;
;    Version information :
;
; Revision 1.6  89/06/29  16:08:51  jimh
; Fixed two bugs regarding compatiblility with the fpsymbol file.  The
; definitions of ROUND_TO_PLUS/MINUS_INFINITY were reversed.  Set_Rounding
; _Mode was fixed to set the local copy (29000 resident) of rounding mode
; in 29027 mode.
; 
; 
; Revision 1.5  89/04/17  11:20:49  jim
; replaced emfsr and emtsr macro calls with mfsr and mtsr instructions.
; 
; Revision 1.4  89/02/24  15:18:04  jimh
; Added the definitions of FP_ENV_MODE_1_DEFAULT, FP_ENV_MODE_2_DEFAULT, 
; FP_FLAGS_DEFAULT.
; Added macro clear_Flags.
; Changed the operation of set_Invalid_Op_flag, set_Reserved_Op_flag.
; 
; Revision 1.3  89/02/01  18:30:12  jimh
; Changed the way set_Rounding_Mode, extract_Rounding_Mode, set_Invalid_Op_flag
; and set_Reserved_Op_flag are done.  Changed save_FP_regs.
; 
; Revision 1.2  89/01/31  10:01:54  jimh
; Updated to the new standard.  This includes moving in register 
; definitions, changing old symbols to reflect those in fpsymbol.h,
; and changing the include file to smartmac.h.
; 
; 
 .include "../traps/fpenv.h"				; RPD 8/21/89
 .include "sys/smartmac.h"

  .equ DOUBLE_EXP_WIDTH, 11
  .equ DOUBLE_EXTENDED_WIDTH, 56

 .equ SIGNED, 0
 .equ UNSIGNED, 1

  .equ ROUND_TO_NEAREST,        0
  .equ ROUND_TO_MINUS_INFINITY, 1
  .equ ROUND_TO_PLUS_INFINITY,  2
  .equ ROUND_TO_ZERO,           3
  .equ ROUNDING_MODE_POSITION, 14 

 .equ FORMAT_INTEGER, 0
 .equ FORMAT_SINGLE,  1
 .equ FORMAT_DOUBLE,  2
      
 .equ DOUBLE_MSB_MASK,0x00080000
;
; The following are definitions used in the smart macro package, defining
; the 29000 shadow registers for the floating-point register file, and
; some temporary registers used during the library routines
;
 .reg FP0,  gr96
 .reg FP1,  gr98
 .reg FP2,  gr100
 .reg FP3,  gr102
 .reg FP4,  gr104
 .reg FP5,  gr106
 .reg FP6,  gr108
 .reg FP7,  gr110
; 
; GR60 through GR6F are used to return the value of a function
;
 .reg rtn0,  gr96
 .reg rtn1,  gr97
 .reg rtn2,  gr98
 .reg rtn3,  gr99
 .reg rtn4,  gr100
 .reg rtn5,  gr101
 .reg rtn6,  gr102
 .reg rtn7,  gr103
 .reg rtn8,  gr104
 .reg rtn9,  gr105
 .reg rtn10, gr106
 .reg rtn11, gr107
 .reg rtn12, gr108
 .reg rtn13, gr109
 .reg rtn14, gr110
 .reg rtn15, gr111
; 
; GR74..GR78 (116-120)    -  temporaries
;
 .reg t0, gr116
 .reg t1, gr117
 .reg t2, gr118
 .reg t3, gr119
 .reg t4, gr120
; 
; FP_ENV_MODE_1 and FP_ENV_MODE_2 are based on 64-bit 29027 Mode register,
; and thus the fpsymbol.h CP_ constants may be used directly.
; 
; FP_ENV_MODE_1 (Bits 0-31)
; 
;      0-3   - floating-point format select, always 0
;      4     - Saturate enable
;      5     - IEEE Affine/Projective mode (ignored by traps code)
;      6     - IEEE Trap enable
;      7     - IEEE Sudden underflow / FP Environment Fast Float Select
;      8-10  - ignored
;      11    - Integer multiplication signed/unsigned select
;      12-13 - Integer multiplication format adjust
;      14-16 - Rounding mode select
;      17-19 - ignored
;      20    - Pipeline mode select
;      21    - ignored
;      22    - Invalid operation mask bit
;      23    - Reserved operand mask bit
;      24    - Overflow mask bit
;      25    - Underflow mask bit
;      26    - Inexact result mask bit
;      27    - Zero mask bit
;      28-31 - ignored
; 
; FP_ENV_MODE_2 (Bits 32-63) [Hardware configuration register, rarely modified]
; 
;      32-35 - Pipeline timer count
;      36-39 - Timer count for multiply-accumulate operation
;      40-43 - Timer count for save state transaction request
;      44-63 - ignored
; 
; FP_ENV_MODE_1 definitions
;
    .set  FP_ENV_MODE_1_DEFAULT,                      CP_PFF_EQ_IEEE
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_AFF_EQ_IEEE
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_AFFINE_MODE
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_IEEE_TRAPS_DISABLED
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_IEEE_GRADUAL_UFLOW_MODE
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_UNSIGNED_INT_MPY_MODE
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_MF_EQ_LSBS
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_RMS_EQ_NEAREST
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_FLOWTHROUGH_MODE
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_INVALID_OP_EXCP_MASK
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_RESERVED_OP_EXCP_MASK
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_OVERFLOW_EXCP_MASK
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_UNDERFLOW_EXCP_MASK
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_INEXACT_EXCP_MASK
    .set  FP_ENV_MODE_1_DEFAULT,FP_ENV_MODE_1_DEFAULT|CP_ZERO_EXCP_MASK
;
; FP_ENV_MODE_2 definitions
;
    .set  FP_ENV_MODE_2_DEFAULT,                      CP_PLTC_EQ_6
    .set  FP_ENV_MODE_2_DEFAULT,FP_ENV_MODE_2_DEFAULT|CP_MATC_EQ_9
    .set  FP_ENV_MODE_2_DEFAULT,FP_ENV_MODE_2_DEFAULT|CP_MVTC_EQ_3
    .set  FP_ENV_MODE_2_DEFAULT,FP_ENV_MODE_2_DEFAULT|CP_NORMAL_DRDY_MODE
    .set  FP_ENV_MODE_2_DEFAULT,FP_ENV_MODE_2_DEFAULT|CP_HALT_ON_ERROR_DISABLED
    .set  FP_ENV_MODE_2_DEFAULT,FP_ENV_MODE_2_DEFAULT|CP_EXCP_DISABLED
;
; FP_FLAGS_DEFAULT definitions
;
    .equ  FP_FLAGS_DEFAULT,         0x00000000 ; No flags set
;
;  The following macros are used by transcendentals to access the environment.
;
;  MACRO NAME: clear_Flags
;
;  FUNCTION:  to clear the flags on entry to a transcendental routine.
;
;  INPUT PARAMETERS: reg  - temporary working register
;                    reg2 - temporary working register
;
 .macro clear_Flags,reg,reg2
 .endm
;
;  MACRO NAME: set_Invalid_Op_flag
;
;  FUNCTION:  to set the Invalid operation flag in the floating-point status
;             register
;
;  INPUT PARAMETERS: reg  - temporary working register
;                    reg2 - 2nd temporary working register
;
 .macro set_Invalid_Op_flag,reg,reg2
 .endm

;
;  MACRO NAME: set_Reserved_Op_flag
;
;  FUNCTION:  to set the Reserved Op flag in the floating-point status register
;
;  INPUT PARAMETERS: reg - temporary working register
;                    reg2 - 2nd temporary working register
;
 .macro set_Reserved_Op_flag,reg,reg2
 .endm

;
;  MACRO NAME: extract_Rounding_Mode
;
;  FUNCTION: to extract the Rounding Mode portion of the floating-point
;            invironment mode register, shift the value to the range of
;            0-7, and leave it in a register
;
;  INPUT PARAMETERS: reg - destination for the mode
;
 .macro extract_Rounding_Mode,reg
  .ifdef _29027_MODE
  .extern __29027Mode
    const reg,__29027Mode
    consth reg,__29027Mode
    load 0,0,reg,reg
    srl reg,reg,CP_RMS_POSITION
    and reg,reg,CP_RMS_MASK >> CP_RMS_POSITION
  .else
    mfsr reg,FPE
    and reg,reg,FPE_FPRND_MASK
    srl reg,reg,FPE_FPRND_POSITION
  .endif    
 .endm

;
;  MACRO NAME: set_Rounding_Mode
;
;  FUNCTION:  to set the 29027 Rounding Mode to a given value
;
;  INPUT PARAMETERS: reg  - working register
;                    reg2 - second working register
;                    rounding_mode - value of the rounding mode
;                      0 - round to nearest
;                      1 - round to minus infinity
;                      2 - round to plus infinity
;                      3 - round to zero
;
;  NOTES: rounding_mode value is not checked
;         29027 Mode register is NOT written by this macro
;
 .macro set_Rounding_Mode,reg,reg2,mode
  .ifdef _29027_MODE
  .extern __29027Mode
    const reg2,__29027Mode
    consth reg2,__29027Mode
    load 0,0,reg,reg2
    const reg2,CP_RMS_MASK
    consth reg2,CP_RMS_MASK
    andn reg,reg,reg2
    const reg2,mode
    sll reg2,reg2,CP_RMS_POSITION
    or reg,reg,reg2
    const reg2,__29027Mode
    consth reg2,__29027Mode
    store 0,0,reg,reg2
    add reg2,reg2,4
    load 0,0,reg2,reg2
    cp_write_mode reg2,reg
  .else
    mfsr reg,FPE
    andn reg,reg,FPE_FPRND_MASK
    const reg2,mode
    sll reg2,reg2,FPE_FPRND_POSITION
    or reg,reg,reg2
    mtsr FPE,reg
  .endif
 .endm
;
;
;  NOTE:  The 29027 is the floating point coprocessor for the 29000.
;         It contains 8 floating point registers FP0 to FP7.  Three of 
;         these, FP0, FP1, and FP2, are currently designated as scratch,
;         that is, they will not be preserved across calls.  The other 
;         five contain values that must be saved whenever they are used 
;         in code, and restored before the exit of the routine.  The 29027 
;         registers are tagged with a single bit indicating the precision 
;         of the current value.   When numbers are read into the 29027,
;         they are always stored in double precision, so that single 
;         precision values are converted on input.  Only the MOVE instruction
;         fails to do this automatic widening.  If the result from calculations
;         in the 29027 ALU (determined by the result precision bit in the 
;         instruction word) is to be single precision and the result saved in
;         an FP reg, the result precision bit from the instruction gets copied
;         into the precision bit for the register.  If a single precision
;         SNaN is saved from the 29027, it will be converted to a double
;         precision QNaN.  Along the way it will cause an unmasked exception
;         when read off the chip and cause changes to the status register.
;         So the preservation routine will need to modify the mode register to 
;         mask off the exceptions, save the state of the status register before
;         saving the FP regs, and restore the status and mode registers to their
;         original settings when the save is complete.
;
;  REFERENCE:  The instructions to drive the Am29027 are described in the
;         Am29027 manual beginning on page 17.  Table 4 describes the 
;         operation codes and table 3 the multiplexer codes.  Communication
;         with the 29000 is described on pages 11 and 12 of the Am29027
;         manual and chapters 6 and 8 of the Am29000 User's Manual
;
;  MACRO NAME:  save_FP_regs
;
;  FUNCTION:    to save the AMD 29027 floating point register values in the
;               29000 general purpose registers
;
;  INPUT PARAMETERS:  fp_register, one of the 29027 registers FP3 - FP7
;
;  REGISTER USAGE:  the following registers are used in save_FP_regs
;
;         rtn0    this register is used in setting the mode and status registers
;         rtn1    this register is used in setting the mode and status registers
;         rtn6    this register is used to store the MSW when FP3 is saved
;         rtn7    this register is used to store the LSW when FP3 is saved
;         rtn8    this register is used to store the MSW when FP4 is saved
;         rtn9    this register is used to store the LSW when FP4 is saved
;

 .macro save_FP_regs,fp_register
  .ifdef _29027_MODE
    ; 
    ; For 29027 mode, expand the macro into 29027 code to preserve FP register
    ;
    .ifeqs "@fp_register@","FP3"
       const rtn6,__29027Mode                  ; Load the address of FP mode
       consth rtn6,__29027Mode
       load 0,0,rtn0,rtn6                      ; Load MSW of FP mode into rtn0
       add rtn6,rtn6,4                         ; Increment rtn6  + 4
       load 0,0,rtn1,rtn6                      ; Load LSW of FP mode into rtn1
       const rtn6,CP_RESERVED_OP_EXCP_MASK     ; Load mask to disable exception 
       consth rtn6,CP_RESERVED_OP_EXCP_MASK 
       or rtn0,rtn0,rtn6                       ; OR in disable of exception mask
       cp_write_mode rtn1, rtn0                ; Reset mode w/exception disabled
       cp_read_status rtn0                     ; Read status and save in rtn1
       const  rtn6,CP_PASS_P | CP_P_EQ_RF3     ; Instruction is PASS_P from RF3
       consth rtn6,CP_PASS_P | CP_P_EQ_RF3 
                                               ; Load & execute the instruction
                                               ;
       store  1,CP_WRITE_INST | CP_START,rtn6,rtn6
       load   1,CP_READ_MSBS,rtn6,rtn6         ; Read the MSW to first register
       load   1,CP_READ_LSBS,rtn7,rtn7         ; Read the LSW to second register
       cp_write_status rtn0                    ; Restore the original status
       const rtn1,__29027Mode                  ; Load the address of FP mode
       consth rtn1,__29027Mode
       load 0,0,rtn0,rtn1                      ; Load MSW of FP mode into rtn0
       add rtn1,rtn1,4                         ; Increment rtn6 to __29027Mode+4
       load 0,0,rtn1,rtn1                      ; Load LSW of FP mode into rtn1
       cp_write_mode rtn1, rtn0                ; Restore the original write mode
    .endif
    .ifeqs "@fp_register@","FP4"
       const rtn8,__29027Mode                  ; Load the address of FP mode
       consth rtn8,__29027Mode
       load 0,0,rtn0,rtn8                      ; Load MSW of FP mode into rtn0
       add rtn8,rtn8,4                         ; Increment rtn6 + 4
       load 0,0,rtn1,rtn8                      ; Load LSW of FP mode into rtn1
       const rtn8,CP_RESERVED_OP_EXCP_MASK     ; Load mask to disable exception 
       consth rtn8,CP_RESERVED_OP_EXCP_MASK 
       or rtn0,rtn0,rtn8                       ; OR in disable of exception mask
       cp_write_mode rtn1, rtn0                ; Reset mode w/exception disabled
       cp_read_status rtn0                     ; Read status and save in rtn1
       const  rtn8,CP_PASS_P | CP_P_EQ_RF4     ; Instruction is PASS_P from RF4
       consth rtn8,CP_PASS_P | CP_P_EQ_RF4 
                                               ; Load & execute the instruction
                                               ;
       store  1,CP_WRITE_INST | CP_START,rtn8,rtn8
       load   1,CP_READ_MSBS,rtn8,rtn8         ; Read the MSW to first register
       load   1,CP_READ_LSBS,rtn9,rtn9         ; Read the LSW to second register
       cp_write_status rtn0                    ; Restore the original status
       const rtn1,__29027Mode                  ; Load the address of FP mode
       consth rtn1,__29027Mode
       load 0,0,rtn0,rtn1                      ; Load MSW of FP mode into rtn0
       add rtn1,rtn1,4                         ; Increment rtn6 + 4
       load 0,0,rtn1,rtn1                      ; Load LSW of FP mode into rtn1
       cp_write_mode rtn1, rtn0                ; Restore the original write mode
    .endif
  .else
    ; 
    ; For 29000 mode, do nothing
    ;
  .endif
 .endm
;
;  MACRO NAME:  restore_FP_regs
;
;  FUNCTION:    to restore the AMD 29027 floating point register values from the
;               29000 general purpose registers
;
;  INPUT PARAMETERS:  fp_register, one of the 29027 registers FP3 - FP7
;
;  REGISTER USAGE:  the following registers are used in restore_FP_regs
;
;         rtn0    this register is used in setting the mode and status registers
;         rtn6    the value in this register is stored as the MSW of FP3 
;         rtn7    the value in this register is stored as the LSW of FP3 
;         rtn8    the value in this register is stored as the MSW of FP4 
;         rtn9    the value in this register is stored as the LSW of FP4 
;
 .macro restore_FP_regs,fp_register
  .ifdef _29027_MODE
    ;
    ; For 29027 mode, move data from return registers to the correct FP register
    ;
    .ifeqs "@fp_register@","FP3"
       store  1,CP_WRITE_R ,rtn6,rtn7          ; Move the data to the R register
                                               ; Then create the instruction
                                               ;
       const   rtn0,CP_MOVE_P|CP_D_D|CP_P_EQ_R|CP_DEST_EQ_RF3
       consth  rtn0,CP_MOVE_P|CP_D_D|CP_P_EQ_R|CP_DEST_EQ_RF3
                                               ;
                                               ; Perform the write
                                               ;
       store  1,(CP_WRITE_INST | CP_START),rtn0,0
    .endif
    .ifeqs "@fp_register@","FP4"
       store  1,CP_WRITE_R ,rtn8,rtn9          ; Move the data to the R register
                                               ; Then create the instruction
                                               ;
       const   rtn0,CP_MOVE_P|CP_D_D|CP_P_EQ_R|CP_DEST_EQ_RF4
       consth  rtn0,CP_MOVE_P|CP_D_D|CP_P_EQ_R|CP_DEST_EQ_RF4
                                               ;
                                               ; Perform the write
                                               ;
       store  1,(CP_WRITE_INST | CP_START),rtn0,0
    .endif
  .else
    ;
    ; For 29000 mode, do nothing.
    ;
  .endif
 .endm
; 
; end of file intrinsi.h
