# XSTORMY16 startup code

# Interrupt vectors at 0x8000.
	.section .int_vec,"ax"
	.global	_start
	.align 1
_start:
	;; Reset, watchdog timer interrupt
	jmpf _int_reset
	;; base timer interrupt
	jmpf _int_basetimer
	;; timer 0
	jmpf _int_timer0
	;; timer 1
	jmpf _int_timer1
	;; SIO0 interrupt
	jmpf _int_sio0
	;; SIO1 interrupt
	jmpf _int_sio1
	;; port0 interrupt
	jmpf _int_port0
	;; port1 interrupt
	jmpf _int_port1

# Reset code, set up memory and call main.
        .section        .rodata
2:	.word	__rdata
	.text
_int_reset:
	;; Set up the stack pointer.
	mov r0,#__stack
        bz  r0,#0,0f
	mov sp,r0
0:
	;; Zero the data space
	mov r0,#_edata
	mov r1,#_end
	mov r2,#0
0:	mov.w (r0++),r2
	blt r0,r1,0b

	;; Copy data from ROM into RAM.  ROM area may be above 64k,
	;; but RAM may not.
	mov r1,#__data
	mov r3,#_edata
	mov r4,#2b
	mov.w r0,(r4++)
	mov.w r2,(r4) 
	mov r8,r2
	;; If _data == _rdata there's no need to copy anything.
	bnz r0,r1,0f
	bz r2,#0,1f
0:	movf.w r2,(r0++)
	bnz r0,#0,2f
	add r8,#1
2:	mov.w (r1++),r2
	blt r1,r3,0b
1:	
	;; Call hardware init routine
	callf _hwinit
	;; Call initialization routines
	callf _init
	;; Set up fini routines to be called from exit
	mov r2,#@fptr(_fini)
	callf atexit
	;; Call main() with empty argc/argv/envp
	mov r2,#0
	mov r3,#0
	mov r4,#0
	callf main
	;; Exit.
	callf exit
	;; Should never reach this code.
	halt
1:	.size _int_reset,1b-_int_reset
		
# Stub interrupt routines.
	.globl _int_timer0
	.weak _int_timer0
	.globl _int_timer1
	.weak _int_timer1
	.globl _int_sio0
	.weak _int_sio0
	.globl _int_sio1
	.weak _int_sio1
	.globl _int_port0
	.weak _int_port0
	.globl _int_port1
	.weak _int_port1
	.globl _int_basetimer
	.weak _int_basetimer
_int_timer0:
_int_timer1:
_int_sio0:
_int_sio1:
_int_port0:
_int_port1:
_int_basetimer:
	iret
1:	.size _int_timer0,1b-_int_timer0

# Stub hardware init
	.globl _hwinit
	.weak _hwinit
_hwinit:
	ret
1:	.size _int_hwinit,1b-_int_hwinit

# The first word in .data has address 0, so it's not a good
# idea to use it as its address conflicts with NULL.
# Place a HALT instruction there to try to catch NULL pointer
# dereferences.
	.data
	halt
