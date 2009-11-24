# (C) Copyright IBM Corp. 2005, 2006
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
# notice, this list of conditions and the following disclaimer in the 
# documentation and/or other materials provided with the distribution.
#     * Neither the name of IBM nor the names of its contributors may be 
# used to endorse or promote products derived from this software without 
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# This file just make a stack frame for the contents of the .fini and
# .init sections.  Users may put any desired instructions in those
# sections.

	# Note - this macro is complimented by the FUNC_END macro
	# in crtn.S.  If you change this macro you must also change
	# that macro match.
.macro FUNC_START
	# Create a stack frame with two slots: LR and BC
	# The .init and .fini section don't change the call-preserved 
	# registes, therefore no need to save them.
	stqd    $lr, 16($sp)
	stqd    $sp, -32($sp)
	ai      $sp, $sp, -32
.endm
		
	.file		"crti.S"

	.section	".init"
	.align 2

        # To make sure the address of _init is not zero, because
        # the default linker entry point is 0.       
        nop

	.global	_init
	.type	_init, @function
_init:
	FUNC_START
	
		
	.section	".fini"
	.align	2
	.global	_fini
	.type	_fini, @function
_fini:
	FUNC_START
	
