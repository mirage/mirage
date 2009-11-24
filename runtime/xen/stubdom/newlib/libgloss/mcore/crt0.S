// MCore StartUp Code.

	.import	main
	.import	exit

	.text
	.export	_start
_start:
	.export	_mainCRTStartup
_mainCRTStartup:
	// Initialise the stack pointer
	lrw	r1, _stack
	mov	r0, r1

	// Zero the .bss data space
	lrw     r1, __bss_start__
	lrw     r2, __bss_end__
	movi	r3, 0
.L0:	
	st	r3, (r1, 0)
	addi	r1, 4
	cmphs	r1, r2
	bf      .L0
#ifdef __ELF__
	// Call the global/static constructors
	jbsr    _init

	// Setup destructors to be called from exit,
	// just in case main never returns...
	lrw     r2, _fini
	jbsr    atexit
#endif
	
	// Initialise the parameters to main()
	movi 	r2, 0	// argc 
	movi	r3, 0	// argv
	movi	r4, 0	// envp

	// Call main
	jbsr	main

	// Call exit
	movi	r2, 0
	jbsr	exit

	// We should never reach here.
	bkpt


