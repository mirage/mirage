        /* Run-time exception support */
#if !defined(__thumb2__)
#include "swi.h"

/* .text is used instead of .section .text so it works with arm-aout too.  */
	.text
        .align 0
        .global __rt_stkovf_split_big
        .global __rt_stkovf_split_small

/* The following functions are provided for software stack checking.
   If hardware stack-checking is being used then the code can be
   compiled without the PCS entry checks, and simply rely on VM
   management to extend the stack for a thread.

   The stack extension event occurs when the PCS function entry code
   would result in a stack-pointer beneath the stack-limit register
   value.  The system relies on the following map:

        +-----------------------------------+ <-- end of stack block
        | ...                               |
        | ...                               |
        | active stack                      |
        | ...                               | <-- sp (stack-pointer) somewhere in here
        | ...                               |
        +-----------------------------------+ <-- sl (stack-limit)
        | stack-extension handler workspace |
        +-----------------------------------+ <-- base of stack block

   The "stack-extension handler workspace" is an amount of memory in
   which the stack overflow support code must execute.  It must be
   large enough to deal with the worst case path through the extension
   code.  At the moment the compiler expects this to be AT LEAST
   256bytes.  It uses this fact to code functions with small local
   data usage within the overflow space.

   In a true target environment We may need to increase the space
   between sl and the true limit to allow for the stack extension
   code, SWI handlers and for undefined instruction handlers of the
   target environment.  */

__rt_stkovf_split_small:
        mov     ip,sp   @ Ensure we can calculate the stack required
        @ and fall through to...
__rt_stkovf_split_big:
        @ in:   sp = current stack-pointer (beneath stack-limit)
        @       sl = current stack-limit
        @       ip = low stack point we require for the current function
        @       lr = return address into the current function
        @       fp = frame-pointer
        @               original sp --> +----------------------------------+
        @                               | pc (12 ahead of PCS entry store) |
        @               current fp ---> +----------------------------------+
        @                               | lr (on entry) pc (on exit)       |
        @                               +----------------------------------+
        @                               | sp ("original sp" on entry)      |
        @                               +----------------------------------+
        @                               | fp (on entry to function)        |
        @                               +----------------------------------+
        @                               |                                  |
        @                               | ..argument and work registers..  |
        @                               |                                  |
        @               current sp ---> +----------------------------------+
        @
        @ The "current sl" is somewhere between "original sp" and "current sp"
        @ but above "true sl". The "current sl" should be at least 256bytes
        @ above the "true sl". The 256byte stack guard should be large enough
        @ to deal with the worst case function entry stacking (160bytes) plus
        @ the stack overflow handler stacking requirements, plus the stack
        @ required for the memory allocation routines.
        @
        @ Normal PCS entry (before stack overflow check) can stack 16
        @ standard registers (64bytes) and 8 floating point registers
        @ (96bytes). This gives a minimum stack guard of 160bytes (excluding
        @ the stack required for the code). (Actually only a maximum of
        @ 14standard registers are ever stacked on entry to a function).
        @
        @ NOTE: Structure returns are performed by the caller allocating a
        @       dummy space on the stack and passing in a "phantom" arg1 into
        @       the function. This means that we do not need to worry about
        @       preserving the stack under "sp" even on function return.
        @ 
        @        Code should never poke values beneath sp. The sp register
        @        should always be "dropped" first to cover the data. This
        @        protects the data against any events that may try and use
        @        the stack.

        SUB     ip, sp, ip      @ extra stack required for function
        @ Add stack extension code here.  If desired a new stack chunk
        @ can be allocated, and the register state updated suitably.

        @ We now know how much extra stack the function requires.
        @ Terminate the program for the moment:
        swi     SWI_Exit
#endif
