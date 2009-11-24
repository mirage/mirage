; @(#)smartmac.h	1.2 90/10/14 20:56:14, AMD
; start of smartmac.h file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1988, 1989, 1990 Advanced Micro Devices, Inc.
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
  .title "AM29000 Smart Macro Package"
;
;    Floating point package for AMD 29000 family
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
;        Version 1.0 - 1 June 1988   - Larry Westerman (smart_macros.h)
; 
; Revision 1.4  89/02/01  18:26:03  jimh
; Changed to relect the new symbols from Bob Perlman, and the new include file.s
; 
; Revision 1.3  89/01/31  10:13:34  jimh
; Updated to use symbols from Bob Perlmans fpsymbol.h file.  This is
; an extensive change.
; 
; Revision 1.2  89/01/26  09:23:50  jimh
; This version checked in previous to substituting Bob Perlman's floating
; point symbols.
; 
; Revision 1.1  89/01/24  13:23:29  jim
; Initial revision
; Replaces smart_macros.h ver 1.11.
; 
; 
; 
;
;  NOTES:
;
;    This package makes the following assumptions about the use of these
;    smart macros:
;
;      1.  These macros will be after the entry code for a transcendental
;          routine.  This entry code will move the original function arguments
;          (by value, if the target language is FORTRAN) into the global
;          registers t0/t1 and t2/t3 (t0 and t2 for single precision
;          routines).
;      2.  The sources of all operands will be one register from the
;          following list:
;            t0 or  t2  - the source is one of the original input operands
;            rtn0       - the source is rtn0, which should be used as the
;                         source for all constant values to be sent to the
;                         AM29027 (when used)
;            FP0 - FP7  - the source is one of the fp registers
;      3.  The destination of all operations will be a register from the
;          following list:
;            rtn0       - the destination is the function return value
;            FP0 - FP7  - the destination is one of the fp registers
;      4.  The additional registers available for temporary use are
;          t4, lrp, and slp.  
;
;    These register definitions are all taken from the file "proregs.a"
;    which was supplied by AMD.  NOTE that the FP0-FP7 registers, for the
;    Am29000 version of the file, overlap with the rtn0-rtn15 registers, so
;    that FP0 corresponds to rtn0/rtn1, FP1 to rtn2/rtn3, and so forth.
;
 .equ ERROR,0
 .equ NO_ERROR,1

 .equ DOUBLE_FUNCTION,0
 .equ SINGLE_FUNCTION,1

 .equ T_OPERATION,0
 .equ Q_OPERATION,1

 .equ R_SOURCE_29000,0
 .equ R_SOURCE_29027,1

 .equ S_SOURCE_29000,0
 .equ S_SOURCE_29027,1

 .equ DESTINATION_29000, 0
 .equ DESTINATION_29027, 1

;
; SMART MACRO : mfadd
;
; FUNCTION : single-precision floating point addition
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mfadd,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mfadd: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE
  ;
  ; For 29027 mode, perform full suite of checking
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_S_S | CP_P_PLUS_T
     .set OPERATION_TYPE, T_OPERATION
     perform_single_operation destination,operand1,operand2
     read_single_result destination
    ;
    ; Save the instruction for the next macro invocation
    ;
     .set PREVIOUS_INSTRUCTION, CURRENT_INSTRUCTION

   .else
  ;
  ; For 29000 mode, simply produce equivalent trap-inducing instruction
  ;
     fadd destination,operand1,operand2

   .endif

 .endm        ; end of mfadd macro definition

;
; SMART MACRO : mfsub
;
; FUNCTION : single-precision floating point subtraction
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mfsub,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mfsub: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE
  ;
  ; For 29027 mode, perform full suite of checking
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_S_S | CP_P_MINUS_T
     .set OPERATION_TYPE, T_OPERATION
     perform_single_operation destination,operand1,operand2
     read_single_result destination
    ;
    ; Save the instruction for the next macro invocation
    ;
     .set PREVIOUS_INSTRUCTION, CURRENT_INSTRUCTION

   .else
  ;
  ; For 29000 mode, simply produce equivalent trap-inducing instruction
  ;
     fsub destination,operand1,operand2

   .endif

 .endm        ; end of mfsub macro definition

;
; SMART MACRO : mfmul
;
; FUNCTION : single-precision floating point multiplication
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mfmul,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mfmul: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE
  ;
  ; For 29027 mode, perform full suite of checking
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_S_S | CP_P_TIMES_Q
     .set OPERATION_TYPE, Q_OPERATION
     perform_single_operation destination,operand1,operand2
     read_single_result destination
    ;
    ; Save the instruction for the next macro invocation
    ;
     .set PREVIOUS_INSTRUCTION, CURRENT_INSTRUCTION

   .else
  ;
  ; For 29000 mode, simply produce equivalent trap-inducing instruction
  ;
     fmul destination,operand1,operand2

   .endif

 .endm        ; end of mfmul macro definition

;
; SMART MACRO : mfdiv
;
; FUNCTION : single-precision floating point divide
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mfdiv,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mfdiv: missing parameter(s)"
     .exitm
   .endif

  ;
  ; Generate the trap instruction in all cases
  ;
   fdiv destination, operand1, operand2

 .endm        ; end of mfdiv macro definition


;
; SMART MACRO : mdadd
;
; FUNCTION : double-precision floating point addition
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mdadd,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mdadd: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE
  ;
  ; For 29027 mode, perform full suite of checking
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_D_D | CP_P_PLUS_T
     .set OPERATION_TYPE, T_OPERATION
     perform_double_operation destination,operand1,operand2
     read_double_result destination
    ;
    ; Save the instruction for the next macro invocation
    ;
     .set PREVIOUS_INSTRUCTION, CURRENT_INSTRUCTION

   .else
  ;
  ; For 29000 mode, simply produce equivalent trap-inducing instruction
  ;
     dadd destination,operand1,operand2

   .endif

 .endm        ; end of mdadd macro definition

;
; SMART MACRO : mdsub
;
; FUNCTION : double-precision floating point subtraction
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mdsub,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mdsub: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE
  ;
  ; For 29027 mode, perform full suite of checking
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_D_D | CP_P_MINUS_T
     .set OPERATION_TYPE, T_OPERATION
     perform_double_operation destination,operand1,operand2
     read_double_result destination
    ;
    ; Save the instruction for the next macro invocation
    ;
     .set PREVIOUS_INSTRUCTION, CURRENT_INSTRUCTION

   .else
  ;
  ; For 29000 mode, simply produce equivalent trap-inducing instruction
  ;
     dsub destination,operand1,operand2

   .endif

 .endm        ; end of mdsub macro definition

;
; SMART MACRO : mdmul
;
; FUNCTION : double-precision floating point multiplication
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mdmul,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mdmul: missing parameter(s)"
     .exitm
   .endif
   
   .ifdef _29027_MODE
 ;
 ; For 29027 mode, perform full suite of checking
 ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_D_D | CP_P_TIMES_Q
     .set OPERATION_TYPE, Q_OPERATION
     perform_double_operation destination,operand1,operand2
     read_double_result destination
   ;
   ; Save the instruction for the next macro invocation
   ;
     .set PREVIOUS_INSTRUCTION, CURRENT_INSTRUCTION

   .else
 ;
 ; For 29000 mode, simply produce equivalent trap-inducing instruction
 ;
     dmul destination,operand1,operand2

   .endif

 .endm        ; end of mdmul macro definition

;
; SMART MACRO : mddiv
;
; FUNCTION : double-precision floating point divide
;
; Required arguments : destination - one of possible destinations
;                      operand1    - one of possible sources
;                      operand2    - one of possible sources
;
 .macro mddiv,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "mddiv: missing parameter(s)"
     .exitm
   .endif

 ;
 ; Generate the trap instruction in all cases
 ;
   ddiv destination, operand1, operand2

 .endm        ; end of mfdiv macro definition

;
;  SMART MACRO: mconvert
;
;  FUNCTION: Floating point/integer conversion
;
;  PARAMETERS:  destination           -  one of the possible destinations
;               source                -  one of the possible sources
;               sign_flag             -  one of SIGNED or UNSIGNED
;               rounding_mode         -  one of ROUND_TO_NEAREST, ROUND_TO_PLUS,
;                                         ROUND_TO_MINUS, ROUND_TO_ZERO
;               destination_precision -  one of FORMAT_INTEGER, FORMAT_DOUBLE,
;                                         or FORMAT_SINGLE
;               source_precision      -  one of FORMAT_INTEGER, FORMAT_DOUBLE,
;                                         or FORMAT_SINGLE
;
 .macro mconvert, destination, source, sign_flag, rounding_mode, destination_precision, source_precision

   .if $narg!=6
     .err
     .print "mconvert: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .if ( destination_precision == FORMAT_INTEGER )
       .set CURRENT_INSTRUCTION, CP_CONVERT_T_TO_INT
       select_T_operand source
       .if ( source_precision == FORMAT_DOUBLE )
         .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_S_D
       .else
         .if ( source_precision == FORMAT_SINGLE )
           .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_S_S
         .else
           .err
           .print "mconvert: invalid source type"
           .exitm
         .endif
       .endif
     .else
       .if ( destination_precision == FORMAT_DOUBLE )
         .if ( source_precision == FORMAT_SINGLE )
           .set CURRENT_INSTRUCTION, CP_PASS_P | CP_P_EQ_R | CP_D_S
           select_P_operand source
         .else
           .if ( source_precision == FORMAT_INTEGER )
             .set CURRENT_INSTRUCTION, CP_I_CONVERT_T_TO_FLOAT | CP_D_S
             select_T_operand source
           .else
             .err
             .print "mconvert: invalid source type"
             .exitm
           .endif
         .endif
       .else
         .if ( destination_precision == FORMAT_SINGLE )
           .if ( source_precision == FORMAT_DOUBLE )
             .set CURRENT_INSTRUCTION, CP_PASS_P | CP_P_EQ_R | CP_S_D
             select_P_operand source
           .else
             .if ( source_precision == FORMAT_INTEGER )
               .set CURRENT_INSTRUCTION, CP_I_CONVERT_T_TO_FLOAT | CP_S_S
               select_T_operand source
             .else
               .err
               .print "mconvert: invalid source type"
               .exitm
             .endif
           .endif
         .else
           .err
           .print "mconvert: invalid destination type "
           .exitm
         .endif
       .endif
     .endif
    ;
    ; Perform the operation, using a 29027 dummy register as the second
    ; source operand, to avoid writing any data inappropriately to the
    ; 29027
    ;
     select_destination destination
     .set S_SOURCE, S_SOURCE_29027
     .if ( source_precision == FORMAT_DOUBLE )
       write_and_execute_double_operation source, FP0
     .else
       write_and_execute_single_operation source, FP0
     .endif
     .if ( destination_precision == FORMAT_DOUBLE )
       read_double_result destination
     .else
       .if ( destination_precision == FORMAT_SINGLE )
         read_single_result destination
       .else
         read_integer_result destination
       .endif
     .endif
   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     convert destination,source,sign_flag,rounding_mode,destination_precision,source_precision
  
   .endif

 .endm       ; end of mfeq macro definition

;
;  SMART MACRO: mfeq
;
;  FUNCTION: Single precision, floating point compare
;
;  PARAMETERS:  destination  -  one of the possible destinations
;               operand1     -  one of the possible sources
;               operand2     -  one of the possible sources
;
 .macro mfeq, destination, operand1, operand2

   .if $narg!=3
     .err
     .print "mfeq: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_S_S  | CP_COMPARE_P_AND_T
     .set OPERATION_TYPE,  T_OPERATION
     select_destination destination
    ;
    ; 29027 registers are not valid destinations for compare operations
    ; If the destination is a 29000 register, write the appropriate
    ; Boolean value to that register.
    ;
     .if ( DESTINATION == DESTINATION_29027 )
       .err
       .print "29027 destinations invalid for compares - @destination@"
       .exitm
     .else
       perform_single_operation destination, operand1, operand2
       cp_read_flags destination
       srl  destination,  destination, CP_EQUAL_FLAG_POSITION
       sll  destination,  destination,  31
     .endif

   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     feq destination,operand1,operand2

   .endif

 .endm       ; end of mfeq macro definition

;
;  SMART MACRO: mfge
;
;  FUNCTION: Single precision, floating point compare
;
;  PARAMETERS:  destination  -  one of the possible destinations
;               operand1     -  one of the possible sources
;               operand2     -  one of the possible sources
;
 .macro mfge, destination, operand1, operand2

   .if $narg!=3
     .err
     .print "mfge: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_S_S  | CP_COMPARE_P_AND_T
     .set OPERATION_TYPE,  T_OPERATION
     select_destination destination
    ;
    ; 29027 registers are not valid destinations for compare operations
    ; If the destination is a 29000 register, write the appropriate
    ; Boolean value to that register.
    ;
     .if ( DESTINATION == DESTINATION_29027 )
       .err
       .print "29027 destinations invalid for compares - @destination@"
       .exitm
     .else
        perform_single_operation destination, operand1, operand2
        cp_read_flags destination
        and   destination, destination, CP_EQUAL_FLAG | CP_GREATER_THAN_FLAG
        cpneq destination, destination, 0x0
     .endif

   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     fge destination,operand1,operand2

   .endif

 .endm       ; end of mfge macro definition

;
;  SMART MACRO: mfgt
;
;  FUNCTION: Single precision, floating point compare
;
;  PARAMETERS:  destination  -  one of the possible destinations
;               operand1     -  one of the possible sources
;               operand2     -  one of the possible sources
;
 .macro mfgt, destination, operand1, operand2

   .if $narg!=3
     .err
     .print "mfgt: missing parameter(s)"
     .exitm
   .endif

   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_S_S  | CP_COMPARE_P_AND_T
     .set OPERATION_TYPE,  T_OPERATION
     select_destination destination
    ;
    ; 29027 registers are not valid destinations for compare operations
    ; If the destination is a 29000 register, write the appropriate
    ; Boolean value to that register.
    ;
     .if ( DESTINATION == DESTINATION_29027 )
       .err
       .print "29027 destinations invalid for compares - @destination@"
       .exitm
     .else
        perform_single_operation destination, operand1, operand2
        cp_read_flags destination
        srl  destination,  destination, CP_GREATER_THAN_FLAG_POSITION
        sll  destination,  destination,  31
     .endif

   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     fgt destination,operand1,operand2

   .endif

 .endm       ; end of mfgt macro definition

;
;  SMART MACRO: mdeq
;
;  FUNCTION: Double precision, floating point compare
;
;  PARAMETERS:  destination  -  one of the possible destinations
;               operand1     -  one of the possible sources
;               operand2     -  one of the possible sources
;
 .macro mdeq, destination, operand1, operand2

   .if $narg!=3
     .err
     .print "mdeq: missing parameter(s)"
     .exitm
   .endif


   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_D_D  | CP_COMPARE_P_AND_T
     .set OPERATION_TYPE,  T_OPERATION
     select_destination destination
    ;
    ; 29027 registers are not valid destinations for compare operations
    ; If the destination is a 29000 register, write the appropriate
    ; Boolean value to that register.
    ;
     .if ( DESTINATION == DESTINATION_29027 )
       .err
       .print "29027 destinations invalid for compare - @destination@"
       .exitm
     .else
       perform_double_operation destination, operand1, operand2
       cp_read_flags destination
       srl  destination,  destination, CP_EQUAL_FLAG_POSITION
       sll  destination,  destination,  31
     .endif
   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     deq destination,operand1,operand2

   .endif

 .endm        ; end of mdeq macro definition

;
;  SMART MACRO: mdge
;
;  FUNCTION: Double precision, floating point compare
;
;  PARAMETERS:  destination  -  one of the possible destinations
;               operand1     -  one of the possible sources
;               operand2     -  one of the possible sources
;
 .macro mdge, destination, operand1, operand2

   .if $narg!=3
     .err
     .print "mdge: missing parameter(s)"
     .exitm
   .endif


   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_D_D  | CP_COMPARE_P_AND_T
     .set OPERATION_TYPE,  T_OPERATION
     select_destination destination
    ;
    ; 29027 registers are not valid destinations for compare operations
    ; If the destination is a 29000 register, write the appropriate
    ; Boolean value to that register.
    ;
     .if ( DESTINATION == DESTINATION_29027 )
       .err
       .print "29027 destinations invalid for compare - @destination@"
       .exitm
     .else
       perform_double_operation destination, operand1, operand2
       cp_read_flags destination
       and   destination,  destination,  CP_EQUAL_FLAG | CP_GREATER_THAN_FLAG
       cpneq destination,  destination,  0x0
     .endif
   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     dge destination,operand1,operand2

   .endif

 .endm        ; end of mdge macro definition

;
;  SMART MACRO: mdgt
;
;  FUNCTION: Double precision, floating point compare
;
;  PARAMETERS:  destination  -  one of the possible destinations
;               operand1     -  one of the possible sources
;               operand2     -  one of the possible sources
;
 .macro mdgt, destination, operand1, operand2

   .if $narg!=3
     .err
     .print "mdgt: missing parameter(s)"
     .exitm
   .endif


   .ifdef _29027_MODE   
  ;
  ; Generate in line 29027 code
  ;
     initialize_previous_instruction
     .set CURRENT_INSTRUCTION, CP_D_D  | CP_COMPARE_P_AND_T
     .set OPERATION_TYPE,  T_OPERATION
     select_destination destination
    ;
    ; 29027 registers are not valid destinations for compare operations
    ; If the destination is a 29000 register, write the appropriate
    ; Boolean value to that register.
    ;
     .if ( DESTINATION == DESTINATION_29027 )
       .err
       .print "29027 destinations invalid for compare - @destination@"
       .exitm
     .else
       perform_double_operation destination, operand1, operand2
       cp_read_flags destination
       srl  destination,  destination,  CP_GREATER_THAN_FLAG_POSITION
       sll  destination,  destination,  31
     .endif
   .else
  ;
  ; For 29000 mode (the default) just invoke the trap-inducing instruction
  ;
     dgt destination,operand1,operand2

   .endif

 .endm    ; end of mdgt macro definition

;
; MACRO NAME : perform_double_operation
;
; FUNCTION : After the instruction base is set up, do the appropriate checking
;            to send the instruction if necessary, send the double-precision
;            operands if necessary, and start the operation
;
; PARAMETERS : destination - one of possible destination operands
;              operand1    - one of possible source operands
;              operand2    - one of possible source operands
;
 .macro perform_double_operation,destination,operand1,operand2

   .if $narg!=3
     .err
     .print "perform_double_operation: missing parameter(s)"
     .exitm
   .endif

  ;
  ; Start defining the instruction
  ;
   select_destination destination
   select_P_operand   operand1
   select_S_operand   operand2

   write_and_execute_double_operation operand1, operand2

 .endm      ; End of perform_double_operation macro definition

;
; MACRO NAME : perform_single_operation
;
; FUNCTION : After the instruction base is set up, do the appropriate checking
;            to send the instruction if necessary, send the single-precision
;            operands if necessary and start the operation
;
; PARAMETERS : destination - one of possible destination operands
;              operand1    - one of possible source operands
;              operand2    - one of possible source operands
;
 .macro perform_single_operation,destination,operand1,operand2

  ;
  ; Start defining the instruction
  ;
   select_destination destination
   select_P_operand operand1
   select_S_operand operand2
   write_and_execute_single_operation operand1,operand2

 .endm      ; End of perform_single_operation macro definition

;
; MACRO NAME : write_and_execute_double_operation
;
; FUNCTION : Write the instruction and operands for a double-precision
;            operation, and start the operation
;
; PARAMETER : operand1 - first operand of double-precision operation
;             operand2 - second operand of operation
;
 .macro write_and_execute_double_operation,operand1,operand2
   .if ( ( R_SOURCE == R_SOURCE_29027 ) && ( S_SOURCE == S_SOURCE_29027 ) )
  ;
  ; If both sources are within the 29027, write the instruction
  ; and start the operation
  ;
       const  t4, CURRENT_INSTRUCTION
       consth t4, CURRENT_INSTRUCTION
       cp_write_inst t4, START
   .else
  ;
  ; One or both of the sources must be written first, so check the
  ; previous instruction
  ;
       const  t4, CURRENT_INSTRUCTION
       consth t4, CURRENT_INSTRUCTION
       cp_write_inst t4
     .if ( R_SOURCE == R_SOURCE_29000 ) && ( S_SOURCE == S_SOURCE_29027 )
       .ifeqs "@operand1@","t0"
         cp_write_r t0, t1, START
       .else
         .ifeqs "@operand1@","t2"
           cp_write_r t2, t3, START
         .else
           .ifeqs "@operand1@","rtn0"
             cp_write_r rtn0, rtn1, START
           .else
             .err
             .print "Invalid source for double operation - @operand1@"
             .exitm
           .endif
         .endif
       .endif
     .endif
     .if ( R_SOURCE == R_SOURCE_29027 ) && ( S_SOURCE == S_SOURCE_29000 )
       .ifeqs "@operand2@","t0"
         cp_write_s t0, t1, START
       .else
         .ifeqs "@operand2@","t2"
           cp_write_s t2, t3, START
         .else
           .ifeqs "@operand2@","rtn0"
             cp_write_s rtn0, rtn1, START
           .else
             .err
             .print "Invalid source for double operation - @operand1@"
             .exitm
           .endif
         .endif
       .endif
     .endif
     .if ( R_SOURCE == R_SOURCE_29000 ) && ( S_SOURCE == S_SOURCE_29000 )
       .ifeqs "@operand1@","t0"
         cp_write_r t0, t1
       .else
         .ifeqs "@operand1@","t2"
           cp_write_r t2, t3
         .else
           .ifeqs "@operand1@","rtn0"
             cp_write_r rtn0, rtn1
           .else
             .err
             .print "Invalid source for double operation - @operand1@"
             .exitm
           .endif
         .endif
       .endif
       .ifeqs "@operand2@","t0"
         cp_write_s t0, t1, START
       .else
         .ifeqs "@operand2@","t2"
           cp_write_s t2, t3, START
         .else
           .ifeqs "@operand2@","rtn0"
             cp_write_s rtn0, rtn1, START
           .else
             .err
             .print "Invalid source for double operation - @operand1@"
             .exitm
           .endif
         .endif
       .endif
     .endif
   .endif

 .endm       ; end of write_and_execute_double_operation macro definition

;
; MACRO NAME : write_and_execute_single_operation
;
; FUNCTION : If necessary, read the result from the 29027 into a
;            register on the 29000
;
; PARAMETER : operand1 - first source for single-precision operation
;             operand2 - second source for operation
;
 .macro write_and_execute_single_operation,operand1,operand2

   .if ( ( R_SOURCE == R_SOURCE_29027 ) && ( S_SOURCE == S_SOURCE_29027 ) )
  ;
  ; If both sources are within the 29027, write the instruction
  ; and start the operation
  ;
       const  t4, CURRENT_INSTRUCTION
       consth t4, CURRENT_INSTRUCTION
       cp_write_inst t4, START
   .else
  ;
  ; One or both of the sources must be written first, so check the
  ; previous instruction
  ;
     const  t4,CURRENT_INSTRUCTION
     consth t4,CURRENT_INSTRUCTION
     cp_write_inst t4, START
     .if ( R_SOURCE == R_SOURCE_29000 ) && ( S_SOURCE == S_SOURCE_29027 )
       cp_write_r operand1, operand1, START
     .endif
     .if ( R_SOURCE == R_SOURCE_29027 ) && ( S_SOURCE == S_SOURCE_29000 )
       cp_write_s operand2, operand2, START
     .endif
     .if ( R_SOURCE == R_SOURCE_29000 ) && ( S_SOURCE == S_SOURCE_29000 )
       cp_write_rs operand1, operand2, START
     .endif
   .endif

 .endm      ; End of write_and_execute_single_operation macro definition

;
; MACRO NAME : read_double_result
;
; FUNCTION : If necessary, read the result from the 29027 into a
;            register on the 29000
;
; PARAMETER : destination - one of the possible destination registers
;
 .macro read_double_result,destination
   .if ( DESTINATION == DESTINATION_29000 )
  ;
  ; If the destination is not within the 29027 register file, read
  ; the result and store it into the correct register in the 29000
  ;
     .ifeqs "@destination@","rtn0"
       cp_read_dp rtn0, rtn1
     .else
       .err
       .print "Invalid destination for double result - @destination@"
       .exitm
     .endif
   .endif

 .endm       ; End of read_double_result macro definition

;
; MACRO NAME : read_single_result
;
; FUNCTION : If necessary, read the result from the 29027 into a
;            register on the 29000
;
; PARAMETER : destination
;
 .macro read_single_result,destination

   .if ( DESTINATION == DESTINATION_29000 )
  ;
  ; If the destination is not within the 29027 register file, read
  ; the result and store it into the correct register in the 29000
  ;
     .ifeqs "@destination@","rtn0"
       cp_read_sp rtn0
     .else
       .err
       .print "Invalid destination for single result - @destination@"
       .exitm
     .endif
   .endif

 .endm       ; End of read_single_result macro definition

;
; MACRO NAME : read_integer_result
;
; FUNCTION : If necessary, read the result from the 29027 into a
;            register on the 29000
;
; PARAMETER : destination
;
 .macro read_integer_result,destination

   .if ( DESTINATION == DESTINATION_29000 )
  ;
  ; If the destination is not within the 29027 register file, read
  ; the result and store it into the correct register in the 29000
  ;
     .ifeqs "@destination@","rtn0"
       cp_read_int rtn0
     .else
       .err
       .print "Invalid destination for single result - @destination@"
       .exitm
     .endif
   .endif

 .endm       ; End of read_integer_result macro definition

;
; MACRO NAME : select_P_operand
;
; FUNCTION : Given an operand, determine if the operand is from the
;            register file, and if so, set the appropriate bits in
;            the current instruction word.  In addition, set the
;            variable R_SOURCE to 0 for local register file, or 1 for
;            floating-point register file.
;
; PARAMETER : operand1 - one of the possible source operands
;
 .macro select_P_operand,operand1
   .ifeqs "@operand1@","t0"
     .set R_SOURCE,R_SOURCE_29000
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_R
     .exitm
   .endif
   .ifeqs "@operand1@","t2"
     .set R_SOURCE,R_SOURCE_29000
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_R
     .exitm
   .endif
   .ifeqs "@operand1@","rtn0"
     .set R_SOURCE,R_SOURCE_29000
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_R
     .exitm
   .endif
   .ifeqs "@operand1@","FP0"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF0
     .exitm
   .endif
   .ifeqs "@operand1@","FP1"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF1
     .exitm
   .endif
   .ifeqs "@operand1@","FP2"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF2
     .exitm
   .endif
   .ifeqs "@operand1@","FP3"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF3
     .exitm
   .endif
   .ifeqs "@operand1@","FP4"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF4
     .exitm
   .endif
   .ifeqs "@operand1@","FP5"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF5
     .exitm
   .endif
   .ifeqs "@operand1@","FP6"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF6
     .exitm
   .endif
   .ifeqs "@operand1@","FP7"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_P_EQ_RF7
     .exitm
   .endif
   .err
   .print "@operand1@ - Invalid operand"

 .endm        ; end of select_P_operand macro definition

;
; MACRO NAME : select_S_operand
;
; FUNCTION : Given an operand, determine if the operand is from the
;            register file, and if so, set the appropriate bits in
;            the current instruction word.  In addition, set the
;            variable S_SOURCE to S_SOURCE_29000 or S_SOURCE_29027
;            as appropriate
;
; PARAMETER : operand2 - one of the possible source operands
;
 .macro select_S_operand,operand2
   .ifeqs "@operand2@","t0"
     .set S_SOURCE,S_SOURCE_29000
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_S
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_S
     .endif     
     .exitm
   .endif
   .ifeqs "@operand2@","t2"
     .set S_SOURCE,S_SOURCE_29000
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_S
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_S
     .endif     
     .exitm
   .endif
   .ifeqs "@operand2@","rtn0"
     .set S_SOURCE,S_SOURCE_29000
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_S
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_S
     .endif     
     .exitm
   .endif
   .ifeqs "@operand2@","FP0"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF0
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF0
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP1"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF1
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF1
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP2"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF2
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF2
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP3"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF3
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF3
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP4"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF4
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF4
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP5"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF5
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF5
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP6"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF6
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF6
     .endif
     .exitm
   .endif
   .ifeqs "@operand2@","FP7"
     .set S_SOURCE,S_SOURCE_29027
     .if ( OPERATION_TYPE == T_OPERATION )
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF7
     .else
       .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_Q_EQ_RF7
     .endif
     .exitm
   .endif
   .err
   .print "@operand2@ - Invalid operand"

 .endm        ; end of select_S_operand macro definition

;
; MACRO NAME : select_T_operand
;
; FUNCTION : Given an operand, determine if the operand is from the
;            register file, and if so, set the appropriate bits in
;            the current instruction word, to read the corresponding
;            source into the T operand.  In addition, set the
;            variable R_SOURCE to 0 for local register file, or 1 for
;            floating-point register file.
;
; PARAMETER : operand1 - one of the possible source operands
;
 .macro select_T_operand,operand1
   .ifeqs "@operand1@","t0"
     .set R_SOURCE,R_SOURCE_29000
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_R
     .exitm
   .endif
   .ifeqs "@operand1@","t2"
     .set R_SOURCE,R_SOURCE_29000
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_R
     .exitm
   .endif
   .ifeqs "@operand1@","rtn0"
     .set R_SOURCE,R_SOURCE_29000
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_R
     .exitm
   .endif
   .ifeqs "@operand1@","FP0"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF0
     .exitm
   .endif
   .ifeqs "@operand1@","FP1"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF1
     .exitm
   .endif
   .ifeqs "@operand1@","FP2"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF2
     .exitm
   .endif
   .ifeqs "@operand1@","FP3"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF3
     .exitm
   .endif
   .ifeqs "@operand1@","FP4"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF4
     .exitm
   .endif
   .ifeqs "@operand1@","FP5"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF5
     .exitm
   .endif
   .ifeqs "@operand1@","FP6"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF6
     .exitm
   .endif
   .ifeqs "@operand1@","FP7"
     .set R_SOURCE,R_SOURCE_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_T_EQ_RF7
     .exitm
   .endif
   .err
   .print "@operand1@ - Invalid operand"

 .endm        ; end of select_T_operand macro definition

;
; MACRO NAME : select_destination
;
; FUNCTION : Given a destination, determine if the operand is from the
;            register file, and if so, set the appropriate bits in
;            the current instruction word.  In addition, set the
;            variable DESTINATION to DESTINATION_29000 or
;            DESTINATION_29027 as appropriate
;
; PARAMETER : destination - one of the possible destination operands
;
 .macro select_destination,destination
   .ifeqs "@destination@","rtn0"
     .set DESTINATION,DESTINATION_29000
     .exitm
   .endif
   .ifeqs "@destination@","FP0"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF0
     .exitm
   .endif
   .ifeqs "@destination@","FP1"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF1
     .exitm
   .endif
   .ifeqs "@destination@","FP2"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF2
     .exitm
   .endif
   .ifeqs "@destination@","FP3"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF3
     .exitm
   .endif
   .ifeqs "@destination@","FP4"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF4
     .exitm
   .endif
   .ifeqs "@destination@","FP5"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF5
     .exitm
   .endif
   .ifeqs "@destination@","FP6"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF6
     .exitm
   .endif
   .ifeqs "@destination@","FP7"
     .set DESTINATION,DESTINATION_29027
     .set CURRENT_INSTRUCTION, CURRENT_INSTRUCTION | CP_DEST_EQ_RF7
     .exitm
   .endif
   .err
   .print "@destination@ - Invalid operand"

 .endm        ; end of select_destination macro definition

; MACRO NAME : initialize_previous_instruction
;
; FUNCTION : Make sure the previous instruction is defined and set to zero
;
 .macro initialize_previous_instruction

   .ifndef PREVIOUS_INSTRUCTION
  ;
  ; Make sure that the previous instruction variable is initialized
  ;
     .set PREVIOUS_INSTRUCTION,0
   .endif

 .endm        ; end of initialize_previous_instruction macro definition


; MACRO NAME : prepare_function_parameters
;
; FUNCTION : To place the input parameters into the correct position for
;            use by the function body.  When the target language is
;            FORTRAN, the values of the input arguments are read from the
;            supplied addresses and moved to the t0-t3 temporary area.
;            When the target language is C or Pascal, the values of the
;            input arguments are simply moved to the t0-t3 temporary area.
;
 .macro prepare_function_parameters,arg1,arg2

   .if $narg==0
     .err
     .print "Missing function argument(s)"
     .exitm
   .endif

   .if $narg>2
     .err
     .print "Too many function arguments
     .exitm
   .endif

   .if $narg>=1
     .if $isreg(@arg1)
       .ifdef FORTRAN
         load 0,0,t0,arg1
         .if ( FUNCTION_TYPE == DOUBLE_FUNCTION )
           add t1,arg1,4
           load 0,0,t1,t1
         .endif
       .else
         add t0,arg1,0
         .if ( FUNCTION_TYPE == DOUBLE_FUNCTION )
           add t1,%%(&arg1+1),0
         .endif         
       .endif
     .else
       .err
       .print "Function argument not register - @arg1@"
     .endif
   .endif
   .if $narg==2
     .if $isreg (@arg2)
       .ifdef FORTRAN
         load 0,0,t2,arg2
         .if ( FUNCTION_TYPE == DOUBLE_FUNCTION )
           add t3,arg2,4
           load 0,0,t3,t3
         .endif
       .else
         add t2,arg2,0
         .if ( FUNCTION_TYPE == DOUBLE_FUNCTION )
           add t3,%%(&arg2+1),0
         .endif
       .endif
     .else
       .err
       .print "Function argument not register - @arg2@"
     .endif
   .endif

 .endm ; end of prepare_function_parameters macro definition

; end of smartmac.h file
