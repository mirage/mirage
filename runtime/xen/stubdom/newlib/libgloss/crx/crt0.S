 ##############################################################################
 # crt0.S -- CRX default start-up routine                                     #
 #                                                                            #
 # Copyright (c) 2004 National Semiconductor Corporation                      #
 #                                                                            #
 # The authors hereby grant permission to use, copy, modify, distribute,      #
 # and license this software and its documentation for any purpose, provided  #
 # that existing copyright notices are retained in all copies and that this   #
 # notice is included verbatim in any distributions. No written agreement,    #
 # license, or royalty fee is required for any of the authorized uses.        #
 # Modifications to this software may be copyrighted by their authors         #
 # and need not follow the licensing terms described here, provided that      #
 # the new terms are clearly indicated on the first page of each file where   #
 # they apply.                                                                #
 #                                                                            #
 # This is the  start routine of your CRX program.                            #
 # It is linked with your application automatically. You can use              #
 # this routine as a template and modify it to your needs, yet this           #
 # file must be supplied for the compiler.                                    #
 # It is assumed that the following symbols are defined in your linker        #
 # script: __STACK_START, __ISTACK_START, __DATA_START, __DATA_END,           #
 # __DATA_IMAGE_START, __BSS_START, __BSS_END.                                #
 ##############################################################################

	.text
	.align	4
	.globl		_main
	.globl		_start
	.globl		_atexit
	.globl		_exit
	.globl		__dispatch_table

_start:

 #----------------------------------------------------------------------------#
 # Initialize the stack pointers. The constants __STACK_START and             #
 # __ISTACK_START should be defined in the linker script.                     #

	movd	$__STACK_START, sp
	movd	$__ISTACK_START, r0
	mtpr    r0, isp

 #----------------------------------------------------------------------------#
 # Initialize the default sections according to the linker script.            #

	movd	$__DATA_END, r4
	subd	$__DATA_START, r4
	movd	$__DATA_START, r2
	movd	$__DATA_IMAGE_START, r3
	bal	ra,	_memcpy
	movd	$__BSS_END, r4
	subd	$__BSS_START, r4
	movd	$__BSS_START, r2
	movd	$0, r3
	bal	ra,	_memset

 #----------------------------------------------------------------------------#
 # Initialize the intbase (pointer to the dispatch table).                    #

	movd	$__dispatch_table, r0
	mtpr    r0, intbase

 #----------------------------------------------------------------------------#
 # Handle global and static constructurs execution and setup                  #
 # destructors to be called from exit.                                        #
	bal	ra,	_init
	movd	$_fini, r2
	bal     ra, _atexit 

 #----------------------------------------------------------------------------#
 # Here you may add initializations that are specific to your                 #
 # environment. For example:                                                  #
 # 1. Configure wait states and other BIU parameters in order to get          #
 #    the best performance out of your target (see the specification          #
 #    document).                                                              #
 # 2. Enable maskable interrupts that should be enabled when your             #
 #    program starts to execute.                                              #


 #----------------------------------------------------------------------------#
 # Jump to the main function in your application.                             #

	bal	ra, _main

 #----------------------------------------------------------------------------#
 # Upon returning from the main function (if it isn't an infinite loop),      #
 # jump to the exit function. The exit function is located in the             #
 # library 'libc.a'.                                                          #

	movd	r0, r2		# _main return value is passed as a
						# parameter to exit.
	br	_exit			# returns control to the debugger.

