/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
#
# This library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 2.1 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
#
# The author of this program may be contacted at leif@rdos.net
#
# crt0.S                                                               
# GCC startupcode for RDOS
#
##########################################################################*/
  
#include "user.def"

    KEY_ENTRIES = 256
  
    .macro UserGate nr 
    .byte 0x9A
    .long \nr
    .word 2
    .endm 

    .data
    .align  8

_key_section:
    .word 0

_key_ref_arr:
    .long 0

_key_dtor_arr:
    .long 0

	.text
	.align 4
					  					    
/*##########################################################################
#
#   Name       : _start
#
#   Purpose....: GCC startup-code
#
##########################################################################*/

	.global _start

_start:
	call get_impure_data_size
	movl %eax,%ecx
	UserGate allocate_app_mem_nr

	xorl %eax,%eax
	.byte 0x64
	movl %edx,(%eax)
	movl %edx,%edi
	rep
	stosb
	pushl %edx

    movl $(4 * KEY_ENTRIES),%eax
	movl %eax,%ecx
    UserGate allocate_app_mem_nr
    movl $4,%eax
    .byte 0x64
    movl %edx,(%eax)
    movl %edx,%edi
	xorl %eax,%eax
    rep
    stosb

    movl $(4 * KEY_ENTRIES),%eax
	movl %eax,%ecx
    UserGate allocate_app_mem_nr
    movl %edx,_key_ref_arr
    movl %edx,%edi
	xorl %eax,%eax
    rep
    stosb

    movl $(4 * KEY_ENTRIES),%eax
	movl %eax,%ecx
    UserGate allocate_app_mem_nr
    movl %edx,_key_dtor_arr
    movl %edx,%edi
	xorl %eax,%eax
    rep
    stosb

	UserGate create_user_section_nr
	movw %bx,_key_section

	call __init_rdos
	add $4, %esp

	movl $0x1000,%eax
	UserGate allocate_app_mem_nr

	pushl %edx
	UserGate get_cmd_line_nr

	xorl %ecx,%ecx
	xorb %ah,%ah

arg_loop:
	movl %edi,(%edx)
	addl $4,%edx
	movb (%edi),%al
	orb %al,%al
	je arg_done

arg_scan:	
	movb (%edi),%al
	orb %al,%al
	je next_arg

	cmpb $0x22,%al
	jne arg_no_quote

	xorb $1,%ah
	jmp arg_scan_next

arg_no_quote:
	orb %ah,%ah
	jnz arg_scan_next

	cmpb $0x20,%al
	je next_arg

	cmpb $0x8,%al
	je next_arg

arg_scan_next:
	incl %edi
	jmp arg_scan

next_arg:
	incl %ecx

to_next_arg:
	orb %al,%al
	je arg_done

	xorb %al,%al
	movb %al,(%edi)
	incl %edi
	movb (%edi),%al
	cmpb $0x20,%al
	je to_next_arg

	cmpb $0x8,%al
	je to_next_arg
	
	jmp arg_loop	

arg_done:
	int $3
	pushl %ecx
	call main
	add $8, %esp

	pushl %eax
	call	exit
					    
/*##########################################################################
#
#   Name       : _exit
#
#   Purpose....: GCC exit-code
#
##########################################################################*/

	.global _exit

_exit:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	UserGate unload_exe_nr
					    					    
/*##########################################################################
#
#   Name       : __getreent
#
#   Purpose....: ?
#
##########################################################################*/

	.global __getreent

__getreent:
    xorl %eax,%eax
	.byte 0x64
	movl (%eax),%eax
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_key_create
#
#   Purpose....: Emulate GCC pthread_key_create
#
#   Parameters.: dtor
#
#   Returns....: Key index
#
##########################################################################*/

	.global __rdos_thread_key_create
	
__rdos_thread_key_create:
    int $3
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

    mov _key_section,%bx
    UserGate enter_user_section_nr	

	movl _key_ref_arr,%ebx
    movl KEY_ENTRIES,%ecx

rtkc_scan_loop:
    movl (%ebx), %eax
    orl %eax, %eax
    jz rtkc_entry_found

    add $4, %ebx
    loop rtkc_scan_loop

    movl $-1, %eax
    jmp rtkc_leave

rtkc_entry_found:
    movb $255,3(%ebx)
    subl _key_ref_arr,%ebx
    addl _key_dtor_arr,%ebx
	movl 8(%ebp),%eax
	movl %eax,(%ebx)
	subl _key_dtor_arr,%ebx
	movl %ebx,%eax

rtkc_leave:
    mov _key_section, %bx
    UserGate leave_user_section_nr	

    popl %ecx
    popl %ebx	
	leave
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_key_delete
#
#   Purpose....: Emulate GCC pthread_key_delete
#
#   Parameters.: index
#
#   Returns....: result
#
##########################################################################*/

	.global __rdos_thread_key_delete
	
__rdos_thread_key_delete:
    int $3
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

    mov _key_section,%bx
    UserGate enter_user_section_nr	

	movl 8(%ebp),%ebx
	testb $3,%bl
	jnz rtkd_fail

    cmpl $(4 * KEY_ENTRIES),%ebx
    jae rtkd_fail
    	
    addl _key_ref_arr,%ebx
    movb $0,3(%ebx)
    mov (%ebx),%eax
    orl %eax,%eax
    jz rtkd_ok

    subl _key_ref_arr,%ebx    
    movl $0,(%ebx)
    jmp rtkd_ok

rtkd_fail:
    movl $1,%eax 
    jmp rtkd_leave   

rtkd_ok:
    xorl %eax,%eax 

rtkd_leave:
    mov _key_section, %bx
    UserGate leave_user_section_nr	

    popl %ebx	
	leave
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_getspecific
#
#   Purpose....: Emulate GCC pthread_getspecific
#
#   Parameters.: index
#
#   Returns....: value
#
##########################################################################*/

	.global __rdos_thread_getspecific
	
__rdos_thread_getspecific:
    int $3
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	testb $3,%bl
	jnz rtg_fail

    cmpl $(4 * KEY_ENTRIES),%ebx
    jae rtg_fail

    movl $4,%eax
    .byte 0x64
    movl (%eax),%eax
    addl %eax,%ebx
    movl (%ebx),%eax
    jmp rtg_done

rtg_fail:
    xorl %eax,%eax

rtg_done:
    popl %ebx	
	leave
	ret
					    					    					    
/*##########################################################################
#
#   Name       : __rdos_thread_setspecific
#
#   Purpose....: Emulate GCC pthread_setspecific
#
#   Parameters.: index
#                value
#
##########################################################################*/

	.global __rdos_thread_setspecific
	
__rdos_thread_setspecific:
    int $3
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movl 8(%ebp),%ebx
	testb $3,%bl
	jnz rts_fail

    cmpl $(4 * KEY_ENTRIES),%ebx
    jae rts_fail

    movl $4,%eax
    .byte 0x64
    movl (%eax),%eax
    addl %eax,%ebx

	movl 12(%ebp),%eax
    movl %eax,(%ebx)
    xorl %eax,%eax
    jmp rts_done

rts_fail:
    movl $1,%eax

rts_done:
    popl %ebx	
	leave
	ret
