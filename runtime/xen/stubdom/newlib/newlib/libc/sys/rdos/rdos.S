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
# rdos.S                                                                
# GCC based interface to RDOS kernel                                    
#
##########################################################################*/

#include "user.def"

    .macro UserGate nr 
    .byte 0x9A
    .long \nr
    .word 2
    .endm 

/*##########################################################################
#
#   Name       : RdosSwapShort
#
#   Purpose....: Byte reverse a short int
#
#   Returns....: Result
#
##########################################################################*/

    .global RdosSwapShort
    
RdosSwapShort:
	pushl %ebp
	movl %esp,%ebp
	movw 8(%ebp),%ax
	xchgb %ah,%al
	leave
	ret


/*##########################################################################
#
#   Name       : RdosSwapLong
#
#   Purpose....: Byte reverse a long int
#
#   Returns....: Result
#
##########################################################################*/

    .global RdosSwapLong
    
RdosSwapLong:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	xchgb %ah,%al
	roll $16,%eax
	xchgb %ah,%al
	leave
	ret


/*##########################################################################
#
#   Name       : LocalToNetworkLong
#
#   Purpose....: Convert a local long to network format
#
#   Returns....: Network format
#
##########################################################################*/

    .global LocalToNetworkLong
    
LocalToNetworkLong:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	xchgb %ah,%al
	roll $16,%eax
	xchgb %ah,%al
	leave
	ret

/*##########################################################################
#
#   Name       : NetworkToLocalLong
#
#   Purpose....: Convert a network long to local format
#
#   Returns....: Local format
#
##########################################################################*/

    .global NetworkToLocalLong
    
NetworkToLocalLong:
	pushl %ebp
	movl %esp,%ebp
	movl 8(%ebp),%eax
	xchgb %ah,%al
	roll $16,%eax
	xchgb %ah,%al
	leave
	ret

/*##########################################################################
#
#   Name       : RdosGetThreadHandle
#
#   Purpose....: Get current thread handle
#
#   Returns....: Thread ID
#
##########################################################################*/

    .global RdosGetThreadHandle
    
RdosGetThreadHandle:
	pushl %ebp
	movl %esp,%ebp
	UserGate get_thread_nr
	movzx %ax,%eax
	leave
	ret

/*##########################################################################
#
#   Name       : RdosGetThreadState
#
#   Purpose....: Get thread state
#
#   Parameters.: Thread #
#                State buffer
#
##########################################################################*/

    .global RdosGetThreadState
    
RdosGetThreadState:
	pushl %ebp
	movl %esp,%ebp
	push %edi

	movl 8(%ebp),%eax
	movl 12(%ebp),%edx
	UserGate get_thread_state_nr
	jc rgtsFail
	
    movl $1,%eax
    jmp rgtsDone
    
rgtsFail:
    xorl %eax,%eax

rgtsDone:
	popl %edi
	leave
	ret

/*##########################################################################
#
#   Name       : RdosSuspendThread
#
#   Purpose....: Suspend thread
#
#   Parameters.: Thread #
#
##########################################################################*/

    .global RdosSuspendThread
    
RdosSuspendThread:
	pushl %ebp
	movl %esp,%ebp

	movl 8(%ebp),%eax
	UserGate suspend_thread_nr
	jc rsfFail

    movl $1,%eax
    jmp rsfDone
    
rsfFail:
    xorl %eax,%eax

rsfDone:
    leave
    ret
    

/*##########################################################################
#
#   Name       : RdosExec
#
#   Purpose....: Execute a program
#
#   Parameters.: Program
#                Commandline
#
##########################################################################*/

    .global RdosExec
    
RdosExec:
	pushl %ebp
	movl %esp,%ebp
	pushl %esi
	pushl %edi

	movl 8(%ebp),%esi
	movl 12(%ebp),%edi

	UserGate load_exe_nr
	UserGate get_exit_code_nr

	popl %edi
	popl %esi
	leave
	ret
    
/*##########################################################################
#
#   Name       : RdosSpawn
#
#   Purpose....: Create new process and run a program
#
#   Parameters.: Program
#                Commandline
#                StartDir
#
##########################################################################*/

    .global RdosSpawn
    
RdosSpawn:
	pushl %ebp
	movl %esp,%ebp
	pushl %fs
	pushl %ebx
	pushl %edx
	pushl %esi
	pushl %edi

    movw %ds,%dx
    movw %dx,%fs
    xorl %edx,%edx
	movl 8(%ebp),%esi
	movl 12(%ebp),%edi
	movl 16(%ebp),%ebx
	UserGate spawn_exe_nr
	jc rsFail
	
    movzx %dx,%eax
    jmp rsDone
    
rsFail:
    xorl %eax,%eax

rsDone:
	popl %edi
	popl %esi
	popl %edx
	popl %ebx
	popw %fs
	leave
	ret
    
/*##########################################################################
#
#   Name       : RdosCpuReset
#
#   Purpose....: Cpu reset
#
##########################################################################*/

    .global RdosCpuReset
    
RdosCpuReset:
	pushl %ebp
	movl %esp,%ebp
	UserGate cpu_reset_nr
	leave
	ret
    
/*##########################################################################
#
#   Name       : RdosGetVersion
#
#   Purpose....: Get RDOS version
#
#   Parameters.: &major
#                &minor
#                &release
#
##########################################################################*/

    .global RdosGetVersion
    
RdosGetVersion:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ecx
	pushl %edx
	pushl %edi

	UserGate get_version_nr

    movzx %dx,%edx
	movl 8(%ebp),%edi
	movl %edx,(%edi)

    movzx %ax,%eax
	movl 12(%ebp),%edi
	movl %eax,(%edi)

    movzx %cx,%eax
	movl 16(%ebp),%edi
	movl %eax,(%edi)

	popl %edi
	popl %edx
	popl %ecx
	popl %eax
	leave
	ret
    
/*##########################################################################
#
#   Name       : RdosAllocateMem
#
#   Purpose....: Allocate memory
#
#   Parameters.: Bytes to allocate
#
#   Returns....: Memory pointer
#
##########################################################################*/

    .global RdosAllocateMem
    
RdosAllocateMem:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx

	movl 8(%ebp),%eax
	UserGate allocate_app_mem_nr
	movl %edx,%eax

	popl %edx
	leave
	ret
    
/*##########################################################################
#
#   Name       : RdosFreeMem
#
#   Purpose....: Free memory
#
#   Parameters.: Memory pointer
#
##########################################################################*/

    .global RdosFreeMem

RdosFreeMem:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx

	movl 8(%ebp),%edx
	UserGate free_app_mem_nr

	popl %edx
	leave
	ret
	    
/*##########################################################################
#
#   Name       : RdosAppDebug
#
#   Purpose....: App debug
#
##########################################################################*/

    .global RdosAppDebug
    
RdosAppDebug:
	pushl %ebp
	movl %esp,%ebp
	UserGate app_debug_nr
	leave
	ret
		    
/*##########################################################################
#
#   Name       : RdosWaitMilli
#
#   Purpose....: Wait a number of milliseconds
#
#   Parameters.: Milliseconds to wait
#
##########################################################################*/

    .global RdosWaitMilli
    
RdosWaitMilli:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax

	movl 8(%ebp),%eax
	UserGate wait_milli_nr

	popl %eax
	leave
	ret
			    
/*##########################################################################
#
#   Name       : RdosCreateSection
#
#   Purpose....: Create section
#
#   Returns....: Section handle
#
##########################################################################*/

    .global RdosCreateSection
    
RdosCreateSection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	
	UserGate create_user_section_nr
	movzx %bx,%eax

	popl %ebx
	leave
	ret
			    
/*##########################################################################
#
#   Name       : RdosDeleteSection
#
#   Purpose....: Delete section
#
#   Parameters.: Section handle
#
##########################################################################*/

    .global RdosDeleteSection
    
RdosDeleteSection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate delete_user_section_nr

	popl %ebx
	leave
	ret
				    
/*##########################################################################
#
#   Name       : RdosEnterSection
#
#   Purpose....: Enter section
#
#   Parameters.: Section handle
#
##########################################################################*/

    .global RdosEnterSection
    
RdosEnterSection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate enter_user_section_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosLeaveSection
#
#   Purpose....: Leave section
#
#   Parameters.: Section handle
#
##########################################################################*/

    .global RdosLeaveSection
    
RdosLeaveSection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate leave_user_section_nr

	popl %ebx
	leave
	ret
				    
/*##########################################################################
#
#   Name       : RdosCreateWait
#
#   Purpose....: Create wait object
#
#   Returns....: Wait handle
#
##########################################################################*/

    .global RdosCreateWait
    
RdosCreateWait:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	UserGate create_wait_nr
	movzx %bx,%eax

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosCloseWait
#
#   Purpose....: Close wait
#
#   Parameters.: Wait handle
#
##########################################################################*/

    .global RdosCloseWait
    
RdosCloseWait:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_wait_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosCheckWait
#
#   Purpose....: Check wait state
#
#   Parameters.: Wait handle
#
#   Returns....: Signalled ID or 0
#
##########################################################################*/

    .global RdosCheckWait
    
RdosCheckWait:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	UserGate is_wait_idle_nr
    movl %ecx,%eax

    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosWaitForever
#
#   Purpose....: Wait forever
#
#   Parameters.: Wait handle
#
#   Returns....: Signalled ID or 0
#
##########################################################################*/

    .global RdosWaitForever
    
RdosWaitForever:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	UserGate wait_no_timeout_nr
	jc rwfFail

    movl %ecx,%eax
    jmp rwfDone

rwfFail:
    xorl %eax,%eax

rwfDone:
    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosWaitTimeout
#
#   Purpose....: Wait with timeout
#
#   Parameters.: Wait handle
#                Timeout in ms
#
#   Returns....: Signalled ID or 0
#
##########################################################################*/

    .global RdosWaitTimeout
    
RdosWaitTimeout:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movl 12(%ebp),%eax
	movl $1193,%edx
	mull %edx
	pushl %edx
	pushl %eax
    UserGate get_system_time_nr
    popl %ebx
    addl %ebx,%eax
    popl %ebx
    adcl %ebx,%edx
	movw 8(%ebp),%bx
	UserGate wait_timeout_nr
	jc rwtFail

    movl %ecx,%eax
    jmp rwtDone

rwtFail:
    xorl %eax,%eax

rwtDone:
    popl %edx
    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosStopWait
#
#   Purpose....: Stop wait
#
#   Parameters.: Wait handle
#
##########################################################################*/

    .global RdosStopWait
    
RdosStopWait:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate stop_wait_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosRemoveWait
#
#   Purpose....: Remove wait object from wait handle
#
#   Parameters.: Wait handle
#                ID
#
##########################################################################*/

    .global RdosRemoveWait
    
RdosRemoveWait:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movl 12(%ebp),%ecx
	UserGate remove_wait_nr

    popl %ecx
	popl %ebx
	leave
	ret
				    
/*##########################################################################
#
#   Name       : RdosCreateSignal
#
#   Purpose....: Create signal object
#
#   Returns....: Signal handle
#
##########################################################################*/

    .global RdosCreateSignal
    
RdosCreateSignal:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	UserGate create_signal_nr
	movzx %bx,%eax

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosResetSignal
#
#   Purpose....: Reset signal
#
#   Parameters.: Signal handle
#
##########################################################################*/

    .global RdosResetSignal
    
RdosResetSignal:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate reset_signal_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosIsSignalled
#
#   Purpose....: Check if signalled
#
#   Parameters.: Signal handle
#
#   Returns....: TRUE if signalled
#
##########################################################################*/

    .global RdosIsSignalled
    
RdosIsSignalled:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate is_signalled_nr
	jc risdFree

    movl $1,%eax
    jmp risdDone	

risdFree:
    xorl %eax,%eax

risdDone:
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetSignal
#
#   Purpose....: Set signal
#
#   Parameters.: Signal handle
#
##########################################################################*/

    .global RdosSetSignal
    
RdosSetSignal:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate set_signal_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosFreeSignal
#
#   Purpose....: Free signal handle
#
#   Parameters.: Signal handle
#
##########################################################################*/

    .global RdosFreeSignal
    
RdosFreeSignal:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate free_signal_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosAddWaitForSignal
#
#   Purpose....: Add signal object to wait handle
#
#   Parameters.: Wait handle
#                Signal handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForSignal
    
RdosAddWaitForSignal:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	movl 16(%ebp),%ecx
	UserGate add_wait_for_signal_nr

    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosAddWaitForKeyboard
#
#   Purpose....: Add keyboard to wait handle
#
#   Parameters.: Wait handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForKeyboard
    
RdosAddWaitForKeyboard:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movl 12(%ebp),%ecx
	UserGate add_wait_for_keyboard_nr

    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosAddWaitForMouse
#
#   Purpose....: Add mouse to wait handle
#
#   Parameters.: Wait handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForMouse
    
RdosAddWaitForMouse:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movl 12(%ebp),%ecx
	UserGate add_wait_for_mouse_nr

    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosAddWaitForCom
#
#   Purpose....: Add com object to wait handle
#
#   Parameters.: Wait handle
#                Com handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForCom
    
RdosAddWaitForCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	movl 16(%ebp),%ecx
	UserGate add_wait_for_com_nr

    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosAddWaitForAdc
#
#   Purpose....: Add ADC object to wait handle
#
#   Parameters.: Wait handle
#                Adc handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForAdc
    
RdosAddWaitForAdc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	movl 16(%ebp),%ecx
	UserGate add_wait_for_adc_nr

    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetTextMode
#
#   Purpose....: Set text mode
#
##########################################################################*/

    .global RdosSetTextMode
    
RdosSetTextMode:
	pushl %ebp
	movl %esp,%ebp

	movw $3,%ax
    UserGate set_video_mode_nr

	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetVideoMode
#
#   Purpose....: Set video mode
#
#   Parameters.: &xres
#                &yres
#                &linesize
#                &LFB
#
#   Returns....: Bitmap handle
#
##########################################################################*/

    .global RdosSetVideoMode
    
RdosSetVideoMode:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%edi
	movw (%edi),%ax

	movl 12(%ebp),%edi
	movw (%edi),%cx

	movl 16(%ebp),%edi
	movw (%edi),%dx

	UserGate get_video_mode_nr
	jc set_video_fail

    UserGate set_video_mode_nr
    jc set_video_fail

	pushl %edi
	movl 8(%ebp),%edi
	movzx %ax,%eax
	movl %eax,(%edi)

	movl 12(%ebp),%edi
	movzx %cx,%ecx
	movl %ecx,(%edi)

	movl 16(%ebp),%edi
	movzx %dx,%edx
	movl %edx,(%edi)

	movl 20(%ebp),%edi
	movzx %si,%esi
	movl %esi,(%edi)
	popl %edi

	movl 24(%ebp),%eax
	movl %edi,(%eax)

	movzx %bx,%eax
	jmp set_video_done

set_video_fail:
	xorl %eax,%eax
	movl 8(%ebp),%edi
	movl %eax,(%edi)
	movl 12(%ebp),%edi
	movl %eax,(%edi)
	movl 16(%ebp),%edi
	movl %eax,(%edi)
	movl 20(%ebp),%edi
	movl %eax,(%edi)
	movl 24(%ebp),%edi
	movl %eax,(%edi)

set_video_done:
	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetClipRect
#
#   Purpose....: Set clip rectangle
#
#   Parameters.: Bitmap handle
#                xmin, xmax, ymin, ymax
#
##########################################################################*/

    .global RdosSetClipRect
    
RdosSetClipRect:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	movw 20(%ebp),%si
	movw 24(%ebp),%di
	UserGate set_clip_rect_nr

    popl %edi
    popl %esi
    popl %edx
    popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosClearClipRect
#
#   Purpose....: Clear clip rectangle
#
#   Parameters.: Bitmap handle
#
##########################################################################*/

    .global RdosClearClipRect
    
RdosClearClipRect:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate clear_clip_rect_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetDrawColor
#
#   Purpose....: Set draw color
#
#   Parameters.: Bitmap handle
#                Color
#
##########################################################################*/

    .global RdosSetDrawColor
    
RdosSetDrawColor:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx

	movw 8(%ebp),%bx
	movl 12(%ebp),%eax
	UserGate set_drawcolor_nr

	popl %ebx
	popl %eax
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetLGOP
#
#   Purpose....: Set draw color
#
#   Parameters.: Bitmap handle
#                LGOP
#
##########################################################################*/

    .global RdosSetLGOP
    
RdosSetLGOP:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	UserGate set_lgop_nr

	popl %ebx
	popl %eax
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetHollowStyle
#
#   Purpose....: Set hollow fill style
#
#   Parameters.: Bitmap handle
#
##########################################################################*/

    .global RdosSetHollowStyle
    
RdosSetHollowStyle:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate set_hollow_style_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosSetFilledStyle
#
#   Purpose....: Set filled fill style
#
#   Parameters.: Bitmap handle
#
##########################################################################*/

    .global RdosSetFilledStyle
    
RdosSetFilledStyle:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate set_filled_style_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosOpenFont
#
#   Purpose....: Open a font
#
#   Parameters.: height
#
#   Returns....: Font handle
#
##########################################################################*/

    .global RdosOpenFont
    
RdosOpenFont:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%ax
	UserGate open_font_nr
	movzx %bx,%eax

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosCloseFont
#
#   Purpose....: Close font handle
#
#   Parameters.: Font handle
#
##########################################################################*/

    .global RdosCloseFont
    
RdosCloseFont:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_font_nr

	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosGetStringMetrics
#
#   Purpose....: Get string metrics for text using font
#
#   Parameters.: Font handle
#                String
#                &width
#                &height
#
##########################################################################*/

    .global RdosGetStringMetrics
    
RdosGetStringMetrics:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	UserGate get_string_metrics_nr

	movl 16(%ebp),%edi
	movzx %cx,%ecx
	movl %ecx,(%edi)
	
	movl 20(%ebp),%edi
	movzx %dx,%edx
	movl %edx,(%edi)

	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetFont
#
#   Purpose....: Set font
#
#   Parameters.: Bitmap handle
#                Font handle
#
##########################################################################*/

    .global RdosSetFont
    
RdosSetFont:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	UserGate set_font_nr

	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetPixel
#
#   Purpose....: Get pixel
#
#   Parameters.: Bitmap handle
#                x, y
#
##########################################################################*/

    .global RdosGetPixel
    
RdosGetPixel:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	UserGate get_pixel_nr

	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetPixel
#
#   Purpose....: Set pixel
#
#   Parameters.: Bitmap handle
#                x, y
#
##########################################################################*/

    .global RdosSetPixel
    
RdosSetPixel:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	UserGate set_pixel_nr

	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosBlit
#
#   Purpose....: Blit
#
#   Parameters.: SrcHandle
#                DestHandle
#                width, height
#                SrcX, SrcY
#                DestX, DestY
#
##########################################################################*/

    .global RdosBlit
    
RdosBlit:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi
;
	movw 8(%ebp),%ax
	movw 12(%ebp),%bx
	movw 16(%ebp),%cx
	movw 20(%ebp),%dx
	movw 28(%ebp),%si
	shll $16,%esi
	movw 24(%ebp),%si
	movw 36(%ebp),%di
	shll $16,%edi
	movw 32(%ebp),%di
	UserGate blit_nr

	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDrawMask
#
#   Purpose....: Draw mask
#
#   Parameters.: Bitmap handle
#                mask
#                RowSize
#                width, height
#                SrcX, SrcY
#                DestX, DestY
#
##########################################################################*/

    .global RdosDrawMask
    
RdosDrawMask:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi
;
	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	movw 16(%ebp),%ax
	movw 24(%ebp),%si
	shll $16,%esi
	movw 20(%ebp),%si
	movw 32(%ebp),%cx
	shll $16,%ecx
	movw 28(%ebp),%cx
	movw 40(%ebp),%dx
	shll $16,%edx
	movw 36(%ebp),%dx
	UserGate draw_mask_nr

	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDrawLine
#
#   Purpose....: Draw a line
#
#   Parameters.: Bitmap handle
#                x1, y1
#                x2, y2
#
##########################################################################*/

    .global RdosDrawLine
    
RdosDrawLine:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi
;
	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	movw 20(%ebp),%si
	movw 24(%ebp),%di
	UserGate draw_line_nr

	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDrawString
#
#   Purpose....: Draw a string
#
#   Parameters.: Bitmap handle
#                x, y
#                string
#
##########################################################################*/

    .global RdosDrawString
    
RdosDrawString:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %edi
;
	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	movl 20(%ebp),%edi
	UserGate draw_string_nr

	popl %edi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDrawRect
#
#   Purpose....: Draw a rect
#
#   Parameters.: Bitmap handle
#                x, y
#                width, height
#
##########################################################################*/

    .global RdosDrawRect
    
RdosDrawRect:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	movw 20(%ebp),%si
	movw 24(%ebp),%di
	UserGate draw_rect_nr

	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDrawEllipse
#
#   Purpose....: Draw an ellipse
#
#   Parameters.: Bitmap handle
#                x, y
#                width, height
#
##########################################################################*/

    .global RdosDrawEllipse
    
RdosDrawEllipse:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	movw 20(%ebp),%si
	movw 24(%ebp),%di
	UserGate draw_ellipse_nr

	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosCreateBitmap
#
#   Purpose....: Create a bitmap
#
#   Parameters.: BitsPerPixel
#                width, height
#
#   Returns....: Bitmap handle
#
##########################################################################*/

    .global RdosCreateBitmap
    
RdosCreateBitmap:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%ax
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	UserGate create_bitmap_nr
	movzx %bx,%eax
;
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDuplicateBitmapHandle
#
#   Purpose....: Duplicate bitmap handle for use in another thread / object
#
#   Parameters.: Bitmap handle
#
#   Returns....: Bitmap handle
#
##########################################################################*/

    .global RdosDuplicateBitmapHandle
    
RdosDuplicateBitmapHandle:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate dup_bitmap_handle_nr
	movzx %bx,%eax

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseBitmap
#
#   Purpose....: Close bitmap handle
#
#   Parameters.: Bitmap handle
#
##########################################################################*/

    .global RdosCloseBitmap
    
RdosCloseBitmap:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_bitmap_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateStringBitmap
#
#   Purpose....: Create bitmap from string & font
#
#   Parameters.: Font
#                string
#
#   Returns....: Bitmap handle
#
##########################################################################*/

    .global RdosCreateStringBitmap
    
RdosCreateStringBitmap:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	UserGate create_string_bitmap_nr
	movzx %bx,%eax
;
	popl %edi
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetBitmapInfo
#
#   Purpose....: Get info about bitmap
#
#   Parameters.: Bitmap handle
#                &BitsPerPixel
#                &width, &height
#                &linesize
#                &LFB
#
##########################################################################*/

    .global RdosGetBitmapInfo
    
RdosGetBitmapInfo:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movw 8(%ebp),%bx
	UserGate get_bitmap_info_nr
	jc gbiFail

	pushl %edi
	movl 12(%ebp),%edi
	movzx %al,%eax
	movl %eax,(%edi)

	movl 16(%ebp),%edi
	movzx %cx,%ecx
	movl %ecx,(%edi)
	
	movl 20(%ebp),%edi
	movzx %dx,%edx
	movl %edx,(%edi)

	movl 24(%ebp),%edi
	movzx %si,%esi
	movl %esi,(%edi)
	popl %edi
	
	movl 28(%ebp),%eax
	movl %edi,(%eax)
	jmp gbiDone

gbiFail:
	xorl %eax,%eax
	movl 12(%ebp),%edi
	movl %eax,(%edi)

	movl 16(%ebp),%edi
	movl %eax,(%edi)

	movl 20(%ebp),%edi
	movl %eax,(%edi)

	movl 24(%ebp),%edi
	movl %eax,(%edi)

	movl 28(%ebp),%edi
	movl %eax,(%edi)

gbiDone:
	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	leave
	ret
					    
/*##########################################################################
#
#   Name       : RdosCreateSprite
#
#   Purpose....: Create a sprite
#
#   Parameters.: dest
#                bitmap
#                mask
#                LGOP
#
#   Returns....: Sprite handle
#
##########################################################################*/

    .global RdosCreateSprite
    
RdosCreateSprite:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	movw 20(%ebp),%ax
	UserGate create_sprite_nr
	movzx %bx,%eax

	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseSprite
#
#   Purpose....: Close sprite handle
#
#   Parameters.: Sprite handle
#
##########################################################################*/

    .global RdosCloseSprite
    
RdosCloseSprite:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_sprite_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosShowSprite
#
#   Purpose....: Show sprite
#
#   Parameters.: Sprite handle
#
##########################################################################*/

    .global RdosShowSprite
    
RdosShowSprite:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate show_sprite_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosHideSprite
#
#   Purpose....: Hide sprite
#
#   Parameters.: Sprite handle
#
##########################################################################*/

    .global RdosHideSprite
    
RdosHideSprite:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate hide_sprite_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosMoveSprite
#
#   Purpose....: Move sprite
#
#   Parameters.: Sprite handle
#                x, y
#
##########################################################################*/

    .global RdosMoveSprite
    
RdosMoveSprite:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%bx
	movw 12(%ebp),%cx
	movw 16(%ebp),%dx
	UserGate move_sprite_nr

	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetForeColor
#
#   Purpose....: Set text-mode fore color
#
#   Parameters.: palette index
#
##########################################################################*/

    .global RdosSetForeColor
    
RdosSetForeColor:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax

	movb 8(%ebp),%al
	UserGate set_forecolor_nr

	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetBackColor
#
#   Purpose....: Set text-mode back color
#
#   Parameters.: palette index
#
##########################################################################*/

    .global RdosSetBackColor
    
RdosSetBackColor:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax

	movb 8(%ebp),%al
	UserGate set_backcolor_nr

	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetSysTime
#
#   Purpose....: Get system time
#
#   Parameters.: &year, &month, &day
#                &hour, &min, &sec, &ms
#
##########################################################################*/

    .global RdosGetSysTime
    
RdosGetSysTime:
	pushl %ebp
	movl %esp,%ebp
	pushal

	UserGate get_system_time_nr
	pushl %eax
	UserGate binary_to_time_nr
	pushl %edx

	movl 8(%ebp),%esi
	movzx %dx,%edx
	movl %edx,(%esi)

	movl 12(%ebp),%esi
	movzx %ch,%edx
	movl %edx,(%esi)

	movl 16(%ebp),%esi
	movzx %cl,%edx
	movl %edx,(%esi)

	movl 20(%ebp),%esi
	movzx %bh,%edx
	movl %edx,(%esi)

	movl 24(%ebp),%esi
	movzx %bl,%edx
	movl %edx,(%esi)

	movl 28(%ebp),%esi
	movzx %ah,%edx
	movl %edx,(%esi)

	popl %edx
	UserGate time_to_binary_nr
	movl %eax,%ebx
	popl %eax
	subl %ebx,%eax
	xorl %edx,%edx
	movl $1192,%ebx
	divl %ebx

	movl 32(%ebp),%esi
	movzx %ax,%eax
	movl %eax,(%esi)

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetTime
#
#   Purpose....: Get time
#
#   Parameters.: &year, &month, &day
#                &hour, &min, &sec, &ms
#
##########################################################################*/

    .global RdosGetTime
    
RdosGetTime:
	pushl %ebp
	movl %esp,%ebp
	pushal

	UserGate get_time_nr
	pushl %eax
	UserGate binary_to_time_nr
	pushl %edx

	movl 8(%ebp),%esi
	movzx %dx,%edx
	movl %edx,(%esi)

	movl 12(%ebp),%esi
	movzx %ch,%edx
	movl %edx,(%esi)

	movl 16(%ebp),%esi
	movzx %cl,%edx
	movl %edx,(%esi)

	movl 20(%ebp),%esi
	movzx %bh,%edx
	movl %edx,(%esi)

	movl 24(%ebp),%esi
	movzx %bl,%edx
	movl %edx,(%esi)

	movl 28(%ebp),%esi
	movzx %ah,%edx
	movl %edx,(%esi)

	popl %edx
	UserGate time_to_binary_nr
	movl %eax,%ebx
	popl %eax
	subl %ebx,%eax
	xorl %edx,%edx
	movl $1192,%ebx
	divl %ebx

	movl 32(%ebp),%esi
	movzx %ax,%eax
	movl %eax,(%esi)

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetTime
#
#   Purpose....: Set time
#
#   Parameters.: year, month, day
#                hour, min, sec, ms
#
##########################################################################*/

    .global RdosSetTime
    
RdosSetTime:
	pushl %ebp
	movl %esp,%ebp
	pushal

	movw 8(%ebp),%dx
	movb 12(%ebp),%ch
	movb 16(%ebp),%cl
	movb 20(%ebp),%bh
	movb 24(%ebp),%bl
	movb 28(%ebp),%ah
	UserGate time_to_binary_nr

    movl %edx,%edi
    movl %eax,%esi

	movl 32(%ebp),%eax
    movl $1192,%edx
    mull %edx
    addl %eax,%esi
    adcl $0,%edi    

	UserGate get_system_time_nr
    subl %eax,%esi
    sbbl %edx,%edi
    movl %esi,%eax
    movl %edi,%edx
    UserGate update_time_nr

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosTicsToRecord
#
#   Purpose....: Convert tics to record format
#
#   Parameters.: MSB, LSB
#                &year, &month, &day
#                &hour, &min, &sec, &ms
#
##########################################################################*/

    .global RdosTicsToRecord
    
RdosTicsToRecord:
	pushl %ebp
	movl %esp,%ebp
	pushal

	movl 8(%ebp),%edx
	movl 12(%ebp),%eax
	addl $596,%eax
	adcl $0,%edx
	UserGate binary_to_time_nr
	pushl %edx

	movl 16(%ebp),%esi
	movzx %dx,%edx
	movl %edx,(%esi)

	movl 20(%ebp),%esi
	movzx %ch,%edx
	movl %edx,(%esi)

	movl 24(%ebp),%esi
	movzx %cl,%edx
	movl %edx,(%esi)

	movl 28(%ebp),%esi
	movzx %bh,%edx
	movl %edx,(%esi)

	movl 32(%ebp),%esi
	movzx %bl,%edx
	movl %edx,(%esi)

	movl 36(%ebp),%esi
	movzx %ah,%edx
	movl %edx,(%esi)

	popl %edx
	UserGate time_to_binary_nr
	movl %eax,%ebx
	movl 12(%ebp),%eax
	subl %edx,%eax
	xorl %edx,%edx
	movl $1192,%ebx
	divl %ebx

	movl 40(%ebp),%esi
	cmpw %ax,1000
	jne rttrSaveMs

	decw %ax

rttrSaveMs:	
	movzx %ax,%eax
	movl %eax,(%esi)

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosRecordToTics
#
#   Purpose....: Convert from record format to tics
#
#   Parameters.: &MSB, &LSB
#                year, month, day
#                hour, min, sec, ms
#
##########################################################################*/

    .global RdosRecordToTics
    
RdosRecordToTics:
	pushl %ebp
	movl %esp,%ebp
	pushal

	movl 40(%ebp),%eax
	movl $1192,%edx
	mull %edx
	pushl %eax
	movw 16(%ebp),%dx
	movb 20(%ebp),%ch
	movb 24(%ebp),%cl
	movb 28(%ebp),%bh
	movb 32(%ebp),%bl
	movb 36(%ebp),%ah
	UserGate time_to_binary_nr
	popl %ebx
	addl %ebx,%eax
	adcl $0,%edx

	movl 8(%ebp),%esi
	movl %edx,(%esi)

	movl 12(%ebp),%esi
	movl %eax,(%esi)

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDecodeMsbTics
#
#   Purpose....: Decode MSB tics
#
#   Parameters.: MSB
#                &day, &hour
#
##########################################################################*/

    .global RdosDecodeMsbTics
    
RdosDecodeMsbTics:
	pushl %ebp
	movl %esp,%ebp
	pushal

	movl 8(%ebp),%eax
	xorl %edx,%edx
	movl $24,%ecx
	divl %ecx

	movl 12(%ebp),%ebx
	movl %eax,(%ebx)

	movl 16(%ebp),%ebx
	movl %edx,(%ebx)

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDecodeLsbTics
#
#   Purpose....: Decode LSB tics
#
#   Parameters.: LSB
#                &min, &sec, &ms, &us
#
##########################################################################*/

    .global RdosDecodeLsbTics
    
RdosDecodeLsbTics:
	pushl %ebp
	movl %esp,%ebp
	pushal

	movl 8(%ebp),%eax
	movl $60,%edx
	mull %edx
	movl 12(%ebp),%ebx
	movl %edx,(%ebx)

	movl $60,%edx
	mull %edx
	movl 16(%ebp),%ebx
	movl %edx,(%ebx)

	movl $1000,%edx
	mull %edx
	movl 20(%ebp),%ebx
	movl %edx,(%ebx)

	movl $1000,%edx
	mull %edx
	movl 24(%ebp),%ebx
	movl %edx,(%ebx)

	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDayOfWeek
#
#   Purpose....: Get day of week
#
#   Parameters.: year, month, day
#
#   Returns....: day of week
#
##########################################################################*/

    .global RdosDayOfWeek
    
RdosDayOfWeek:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movl 8(%ebp),%edx
	movb 12(%ebp),%ch
	movb 16(%ebp),%cl
    xorw %bx,%bx
    xorb %ah,%ah
	UserGate adjust_time_nr
	pushw %dx
	movl $365,%eax
	imulw %dx
	pushw %dx
	pushw %ax
	popl %ebx
	popw %dx
	UserGate passed_days_nr
	decw %dx
	shrw $2,%dx
	incw %dx
	addw %dx,%ax
	addl %ebx,%eax
    xorl %edx,%edx
    addl $5,%eax
    movl $7,%ebx
    divl %ebx
    movzx %dl,%eax

	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetTics
#
#   Purpose....: Get system tics
#
#   Parameters.: &MSB, &LSB
#
##########################################################################*/

    .global RdosGetTics
    
RdosGetTics:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx
	pushl %esi

	UserGate get_time_nr
	movl 8(%ebp),%esi
	movl %edx,(%esi)
	movl 12(%ebp),%esi
	movl %eax,(%esi)

	popl %esi
	popl %edx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddTics
#
#   Purpose....: Add tics to binary time
#
#   Parameters.: &MSB, &LSB
#                tics
#
##########################################################################*/

    .global RdosAddTics
    
RdosAddTics:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 16(%ebp),%eax
	movl 12(%ebp),%ebx
	addl %eax,(%ebx)
	movl 8(%ebp),%ebx
	adcl $0,(%ebx)

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddMilli
#
#   Purpose....: Add milliseconds to binary time
#
#   Parameters.: &MSB, &LSB
#                milli
#
##########################################################################*/

    .global RdosAddMilli
    
RdosAddMilli:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 16(%ebp),%eax
	movl $1193,%edx
	mull %edx
	movl 12(%ebp),%ebx
	addl %eax,(%ebx)
	movl 8(%ebp),%ebx
	adcl %edx,(%ebx)

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddSec
#
#   Purpose....: Add milliseconds to binary time
#
#   Parameters.: &MSB, &LSB
#                sec
#
##########################################################################*/

    .global RdosAddSec
    
RdosAddSec:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 16(%ebp),%eax
	movl $1193000,%edx
	mull %edx
	movl 12(%ebp),%ebx
	addl %eax,(%ebx)
	movl 8(%ebp),%ebx
	adcl %edx,(%ebx)

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddMin
#
#   Purpose....: Add minutes to binary time
#
#   Parameters.: &MSB, &LSB
#                min
#
##########################################################################*/

    .global RdosAddMin
    
RdosAddMin:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 16(%ebp),%eax
	movl $71582760,%edx
	mull %edx
	movl 12(%ebp),%ebx
	addl %eax,(%ebx)
	movl 8(%ebp),%ebx
	adcl %edx,(%ebx)

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddHour
#
#   Purpose....: Add hour to binary time
#
#   Parameters.: &MSB, &LSB
#                hour
#
##########################################################################*/

    .global RdosAddHour
    
RdosAddHour:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 16(%ebp),%eax
	movl 8(%ebp),%ebx
	adc %eax,(%ebx)

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddDay
#
#   Purpose....: Add days to binary time
#
#   Parameters.: &MSB, &LSB
#                days
#
##########################################################################*/

    .global RdosAddDay
    
RdosAddDay:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 16(%ebp),%eax
	movl $24,%edx
	mull %edx
	movl 8(%ebp),%ebx
	adc %eax,(%ebx)

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSyncTime
#
#   Purpose....: Synchronize time with NTP
#
#   Parameters.: IP
#
##########################################################################*/

    .global RdosSyncTime
    
RdosSyncTime:
	pushl %ebp
	movl %esp,%ebp
	pushal

	movl 8(%ebp),%edx
	UserGate sync_time_nr
	jc RdosSyncTimeFail

	movl $1,%eax
	jmp RdosSyncTimeDone

RdosSyncTimeFail:
	xorl %eax,%eax

RdosSyncTimeDone:
	popal
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenCom
#
#   Purpose....: Open com-port
#
#   Parameters.: ID
#                baudrate
#                parity
#                data bits
#                stop bits
#                SendBufferSize
#                RecBufferSize
#
#    Returns...: Com handle
#
##########################################################################*/

    .global RdosOpenCom
    
RdosOpenCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movb 8(%ebp),%al
	movb 20(%ebp),%ah
	movb 24(%ebp),%bl
	movb 16(%ebp),%bh
	movl 12(%ebp),%ecx
	movw 28(%ebp),%si
	movw 32(%ebp),%di
	UserGate open_com_nr
	movzx %bx,%eax

	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseCom
#
#   Purpose....: Close com-port
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosCloseCom
    
RdosCloseCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_com_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosFlushCom
#
#   Purpose....: Flush com-port
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosFlushCom
    
RdosFlushCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate flush_com_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadCom
#
#   Purpose....: Read com-port
#
#   Parameters.: Com handle
#
#   Returns....: Character
#
##########################################################################*/

    .global RdosReadCom
    
RdosReadCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate read_com_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteCom
#
#   Purpose....: Write com-port
#
#   Parameters.: Com handle
#                char
#
#   Returns....: 0 for success
#
##########################################################################*/

    .global RdosWriteCom
    
RdosWriteCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	movb 12(%ebp),%al
	UserGate write_com_nr
	movzx %al,%eax

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosWaitForSendCompletedCom
#
#   Purpose....: Wait until send buffer is empty
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosWaitForSendCompletedCom
    
RdosWaitForSendCompletedCom:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate wait_for_send_completed_com_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosEnableCts
#
#   Purpose....: Enable CTS signal
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosEnableCts
    
RdosEnableCts:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate enable_cts_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDisableCts
#
#   Purpose....: Disable CTS signal
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosDisableCts
    
RdosDisableCts:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate disable_cts_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosEnableAutoRts
#
#   Purpose....: Enable auto RTS signal generation for RS485
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosEnableAutoRts
    
RdosEnableAutoRts:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate enable_auto_rts_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDisableAutoRts
#
#   Purpose....: Disable auto RTS signal generation for RS485
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosDisableAutoRts
    
RdosDisableAutoRts:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate disable_auto_rts_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetDtr
#
#   Purpose....: Set DTR active
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosSetDtr
    
RdosSetDtr:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate set_dtr_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosResetDtr
#
#   Purpose....: Set DTR inactive
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosResetDtr
    
RdosResetDtr:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate reset_dtr_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetRts
#
#   Purpose....: Set RTS active
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosSetRts
    
RdosSetRts:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate set_rts_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosResetRts
#
#   Purpose....: Set RTS inactive
#
#   Parameters.: Com handle
#
##########################################################################*/

    .global RdosResetRts
    
RdosResetRts:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate reset_rts_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetReceiveBufferSpace
#
#   Purpose....: Get receive buffer free space
#
#   Parameters.: Com handle
#
#   Returns....: Free bytes
#
##########################################################################*/

    .global RdosGetReceiveBufferSpace
    
RdosGetReceiveBufferSpace:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_com_receive_space_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetSendBufferSpace
#
#   Purpose....: Get send buffer free space
#
#   Parameters.: Com handle
#
#   Returns....: Free bytes
#
##########################################################################*/

    .global RdosGetSendBufferSpace
    
RdosGetSendBufferSpace:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_com_send_space_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenFile
#
#   Purpose....: Open file
#
#   Parameters.: Filename
#                Access
#
#    Returns...: File handle
#
##########################################################################*/

    .global RdosOpenFile
    
RdosOpenFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movb 12(%ebp),%cl
	UserGate open_file_nr
	jc OpenFileFailed

	movzx %bx,%eax
	jmp OpenFileDone

OpenFileFailed:
	xorl %eax,%eax

OpenFileDone:
	popl %edi
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateFile
#
#   Purpose....: Create file
#
#   Parameters.: Filename
#                Attribute
#
#    Returns...: File handle
#
##########################################################################*/

    .global RdosCreateFile
    
RdosCreateFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movw 12(%ebp),%cx
	UserGate create_file_nr
	jc CreateFileFailed

	movzx %bx,%eax
	jmp CreateFileDone

CreateFileFailed:
	xorl %eax,%eax

CreateFileDone:
	popl %edi
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseFile
#
#   Purpose....: Close file
#
#   Parameters.: File handle
#
##########################################################################*/

    .global RdosCloseFile
    
RdosCloseFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_file_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosIsDevice
#
#   Purpose....: Check if file is device
#
#   Parameters.: TRUE if device
#
##########################################################################*/

    .global RdosIsDevice
    
RdosIsDevice:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_ioctl_data_nr
	testw $0x8000,%dx
	jz ridFail

	movl $1,%eax
	jmp ridDone

ridFail:
	xorl %eax,%eax

ridDone:
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDuplFile
#
#   Purpose....: Duplicate file handle
#
#   Parameters.: File handle
#
#   Returns....: File handle
#
##########################################################################*/

    .global RdosDuplFile
    
RdosDuplFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate dupl_file_nr
	jc DuplFileFailed
	
	movzx %bx,%eax
	jmp DuplFileDone

DuplFileFailed:
	xorl %eax,%eax

DuplFileDone:
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetFileSize
#
#   Purpose....: Get file size
#
#   Parameters.: File handle
#
#   Returns....: Size
#
##########################################################################*/

    .global RdosGetFileSize
    
RdosGetFileSize:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_file_size_nr
	jnc GetFileSizeDone

GetFileSizeFail:
	xorl %eax,%eax

GetFileSizeDone:
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetFileSize
#
#   Purpose....: Set file size
#
#   Parameters.: File handle
#                Size
#
##########################################################################*/

    .global RdosSetFileSize
    
RdosSetFileSize:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx

	movw 8(%ebp),%bx
	movl 12(%ebp),%eax
	UserGate set_file_size_nr

	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetFilePos
#
#   Purpose....: Get file position
#
#   Parameters.: File handle
#
#   Returns....: Position
#
##########################################################################*/

    .global RdosGetFilePos
    
RdosGetFilePos:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_file_pos_nr
	jnc GetFilePosDone

GetFilePosFail:
	xorl %eax,%eax

GetFilePosDone:
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetFilePos
#
#   Purpose....: Set file position
#
#   Parameters.: File handle
#                Position
#
##########################################################################*/

    .global RdosSetFilePos
    
RdosSetFilePos:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx

	movw 8(%ebp),%bx
	movl 12(%ebp),%eax
	UserGate set_file_pos_nr

	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetFileTime
#
#   Purpose....: Get file time & date
#
#   Parameters.: File handle
#                &MSB, &LSB
#
##########################################################################*/

    .global RdosGetFileTime
    
RdosGetFileTime:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movw 8(%ebp),%bx
	UserGate get_file_time_nr
	jc GetFileTimeDone

	movl 12(%ebp),%edi
	movl %edx,(%edi)

	movl 16(%ebp),%edi
	movl %eax,(%edi)

GetFileTimeDone:
	popl %edi
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetFileTime
#
#   Purpose....: Set file time & date
#
#   Parameters.: File handle
#                MSB, LSB
#
##########################################################################*/

    .global RdosSetFileTime
    
RdosSetFileTime:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx
	pushl %edx

	movw 8(%ebp),%bx
	movl 12(%ebp),%edx
	movl 16(%ebp),%eax
	UserGate set_file_time_nr

	popl %edx
	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadFile
#
#   Purpose....: Read from file
#
#   Parameters.: File handle
#                buffer
#                count
#
#   Returns....: Read count
#
##########################################################################*/

    .global RdosReadFile
    
RdosReadFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	movl 16(%ebp),%ecx
	UserGate read_file_nr

	popl %edi
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteFile
#
#   Purpose....: Write to file
#
#   Parameters.: File handle
#                buffer
#                count
#
#   Returns....: Written count
#
##########################################################################*/

    .global RdosWriteFile
    
RdosWriteFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	movl 16(%ebp),%ecx
	UserGate write_file_nr

	popl %edi
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateMapping
#
#   Purpose....: Create file mapping
#
#   Parameters.: Size
#
#    Returns...: Filemap handle
#
##########################################################################*/

    .global RdosCreateMapping
    
RdosCreateMapping:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%eax
	UserGate create_mapping_nr
	movzx %bx,%eax

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateNamedMapping
#
#   Purpose....: Create named file mapping
#
#   Parameters.: Name
#                Size
#
#    Returns...: Filemap handle
#
##########################################################################*/

    .global RdosCreateNamedMapping
    
RdosCreateNamedMapping:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%eax
	UserGate create_named_mapping_nr
	movzx %bx,%eax

	popl %edi
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateNamedFileMapping
#
#   Purpose....: Create file named file mapping
#
#   Parameters.: Name
#                Size
#                File handle
#
#    Returns...: Filemap handle
#
##########################################################################*/

    .global RdosCreateNamedFileMapping
    
RdosCreateNamedFileMapping:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%eax
	movw 16(%ebp),%bx
	UserGate create_named_file_mapping_nr
	movzx %bx,%eax

	popl %edi
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenNamedMapping
#
#   Purpose....: Open named file mapping
#
#   Parameters.: Name
#
#    Returns...: Filemap handle
#
##########################################################################*/

    .global RdosOpenNamedMapping
    
RdosOpenNamedMapping:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%edi
	UserGate open_named_mapping_nr
	movzx %bx,%eax

	popl %edi
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSyncMapping
#
#   Purpose....: Sync file mapping
#
#   Parameters.: Filemap handle
#
##########################################################################*/

    .global RdosSyncMapping
    
RdosSyncMapping:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate sync_mapping_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseMapping
#
#   Purpose....: Close file mapping
#
#   Parameters.: Filemap handle
#
##########################################################################*/

    .global RdosCloseMapping
    
RdosCloseMapping:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_mapping_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosMapView
#
#   Purpose....: Map view of file into memory
#
#   Parameters.: Filemap handle
#                Offset
#                Address
#                Size
#
##########################################################################*/

    .global RdosMapView
    
RdosMapView:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%eax
	movl 16(%ebp),%edi
	movl 20(%ebp),%ecx
	UserGate map_view_nr

	popl %edi
	popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosUnmapView
#
#   Purpose....: Unmap view of file
#
#   Parameters.: Filemap handle
#
##########################################################################*/

    .global RdosUnmapView
    
RdosUnmapView:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate unmap_view_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetCurDrive
#
#   Purpose....: Set current drive
#
#   Parameters.: Drive
#
##########################################################################*/

    .global RdosSetCurDrive
    
RdosSetCurDrive:
	pushl %ebp
	movl %esp,%ebp

	movb 8(%ebp),%al
	UserGate set_cur_drive_nr
	jc rscdrFail

    movl $1,%eax
    jmp rscdrDone

rscdrFail:
    xorl %eax,%eax

rscdrDone:
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetCurDrive
#
#   Purpose....: Get current drive
#
#   Returns....: Drive
#
##########################################################################*/

    .global RdosGetCurDrive
    
RdosGetCurDrive:
	pushl %ebp
	movl %esp,%ebp

    xorl %eax,%eax
	UserGate get_cur_drive_nr
	movzx %al,%eax

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetCurDir
#
#   Purpose....: Set current directory
#
#   Parameters.: Pathname
#
##########################################################################*/

    .global RdosSetCurDir
    
RdosSetCurDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movl 8(%ebp),%edi
	UserGate set_cur_dir_nr
	jc rscdFail

    movl $1,%eax
    jmp rscdDone

rscdFail:
    xorl %eax,%eax

rscdDone:
	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetCurDir
#
#   Purpose....: Get current directory
#
#   Parameters.: Drive
#                Pathname
#
##########################################################################*/

    .global RdosGetCurDir
    
RdosGetCurDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%edi
	UserGate get_cur_dir_nr
	jc rgcdFail

    movl $1,%eax
    jmp rgcdDone

rgcdFail:
    xorl %eax,%eax

rgcdDone:
	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosMakeDir
#
#   Purpose....: Create directory
#
#   Parameters.: Pathname
#
##########################################################################*/

    .global RdosMakeDir
    
RdosMakeDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movl 8(%ebp),%edi
	UserGate make_dir_nr
	jc mdFail

    movl $1,%eax
    jmp mdDone

mdFail:
    xorl %eax,%eax

mdDone:
	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosRemoveDir
#
#   Purpose....: Remove directory
#
#   Parameters.: Pathname
#
##########################################################################*/

    .global RdosRemoveDir
    
RdosRemoveDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movl 8(%ebp),%edi
	UserGate remove_dir_nr
	jc rdFail

    movl $1,%eax
    jmp rdDone

rdFail:
    xorl %eax,%eax

rdDone:
	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosRenameFile
#
#   Purpose....: Rename file
#
#   Parameters.: ToName
#                FromName
#
##########################################################################*/

    .global RdosRenameFile
    
RdosRenameFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %esi
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%esi
	UserGate rename_file_nr
	jc rfFail

    mov $1,%eax
    jmp rfDone

rfFail:
    xorl %eax,%eax

rfDone:
	popl %edi
	popl %esi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosDeleteFile
#
#   Purpose....: Delete file
#
#   Parameters.: Pathname
#
##########################################################################*/

    .global RdosDeleteFile
    
RdosDeleteFile:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movl 8(%ebp),%edi
	UserGate delete_file_nr
	jc dfFail

    mov $1,%eax
    jmp dfDone

dfFail:
    xorl %eax,%eax

dfDone:
	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetFileAttribute
#
#   Purpose....: Get file attribute
#
#   Parameters.: Pathname
#                &Attrib
#
##########################################################################*/

    .global RdosGetFileAttribute
    
RdosGetFileAttribute:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	UserGate get_file_attribute_nr
	jc gfaFail

	movl 12(%ebp),%edi
    movzx %cx,%ecx
	movl %ecx,(%edi)
    movl $1,%eax
    jmp gfaDone

gfaFail:
    xorl %eax,%eax

gfaDone:
	popl %edi
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetFileAttribute
#
#   Purpose....: Set file attribute
#
#   Parameters.: Pathname
#                Attrib
#
##########################################################################*/

    .global RdosSetFileAttribute
    
RdosSetFileAttribute:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movw 12(%ebp),%cx
	UserGate set_file_attribute_nr
	jc sfaFail

    movl $1,%eax
    jmp sfaDone

sfaFail:
    xorl %eax,%eax

sfaDone:
	popl %edi
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenDir
#
#   Purpose....: Open directory
#
#   Parameters.: Pathname
#
#   Returns....: Dir handle
#
##########################################################################*/

    .global RdosOpenDir
    
RdosOpenDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%edi
	UserGate open_dir_nr
	jc odFail

    movzx %bx,%eax
    jmp odDone

odFail:
    xorl %eax,%eax

odDone:
	popl %edi
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseDir
#
#   Purpose....: Close directory
#
#   Parameters.: Dir handle
#
##########################################################################*/

    .global RdosCloseDir
    
RdosCloseDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_dir_nr

	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadDir
#
#   Purpose....: Read directory entry
#
#   Parameters.: Dir handle
#                Entry #
#                MaxNameSize
#                Name buffer
#                &FileSize
#                &Attribute
#                &Msb time
#                &Lsb time
#
##########################################################################*/

    .global RdosReadDir
    
RdosReadDir:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movw 8(%ebp),%bx
	movw 12(%ebp),%dx
	movw 16(%ebp),%cx
	movl 20(%ebp),%edi
	UserGate read_dir_nr
	jc rdiFail

	movl 24(%ebp),%edi
	movl %ecx,(%edi)

	movl 28(%ebp),%edi
    movzx %bx,%ebx
	movl %ebx,(%edi)

	movl 32(%ebp),%edi
	movl %edx,(%edi)

	movl 36(%ebp),%edi
	movl %eax,(%edi)

    movl $1,%eax
    jmp rdiDone

rdiFail:
    xorl %eax,%eax
    
rdiDone:
    popl %edi
    popl %ecx
	popl %ebx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetFocus
#
#   Purpose....: Set input focus
#
#   Parameters.: Focus handle
#
##########################################################################*/

    .global RdosSetFocus
    
RdosSetFocus:
	pushl %ebp
	movl %esp,%ebp
	
	movl 8(%ebp),%eax
	UserGate set_focus_nr

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetFocus
#
#   Purpose....: Get input focus
#
#   Returns....: Focus handle
#
##########################################################################*/

    .global RdosGetFocus
    
RdosGetFocus:
	pushl %ebp
	movl %esp,%ebp
	
	UserGate get_focus_nr

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosClearKeyboard
#
#   Purpose....: Clear keyboard buffer
#
##########################################################################*/

    .global RdosClearKeyboard
    
RdosClearKeyboard:
	pushl %ebp
	movl %esp,%ebp

	UserGate flush_keyboard_nr

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosPollKeyboard
#
#   Purpose....: Poll keyboard buffer
#
#   Returns....: TRUE if non-empty
#
##########################################################################*/

    .global RdosPollKeyboard
    
RdosPollKeyboard:
	pushl %ebp
	movl %esp,%ebp

	UserGate poll_keyboard_nr
	jc rpkEmpty

	mov $1,%eax
	jmp rpkDone

rpkEmpty:
	xorl %eax,%eax

rpkDone:
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadKeyboard
#
#   Purpose....: Read keyboard buffer
#
#   Returns....: Scan code
#
##########################################################################*/

    .global RdosReadKeyboard
    
RdosReadKeyboard:
	pushl %ebp
	movl %esp,%ebp

	UserGate read_keyboard_nr
	movzx %ax,%eax

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetKeyboardState
#
#   Purpose....: Get keyboard buffer
#
#   Returns....: Keyboard state
#
##########################################################################*/

    .global RdosGetKeyboardState
    
RdosGetKeyboardState:
	pushl %ebp
	movl %esp,%ebp

	UserGate get_keyboard_state_nr
	movzx %ax,%eax

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosPutKeyboard
#
#   Purpose....: Put scancode in keyboard buffer
#
##########################################################################*/

    .global RdosPutKeyboard
    
RdosPutKeyboard:
	pushl %ebp
	movl %esp,%ebp
    pushl %edx

	movw 8(%ebp),%ax
	movb 12(%ebp),%dl
	movb 16(%ebp),%dh
	UserGate put_keyboard_code_nr

    popl %edx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosPeekKeyEvent
#
#   Purpose....: Peek keyboard event
#
##########################################################################*/

    .global RdosPeekKeyEvent
    
RdosPeekKeyEvent:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx
	pushl %edi

	UserGate peek_key_event_nr
	jc rpeFail

	movl 8(%ebp),%edi
	movzx %ax,%eax
	movl %eax,(%edi)

	movl 12(%ebp),%edi
	movzx %cx,%eax
	movl %eax,(%edi)

	movl 16(%ebp),%edi
	movzx %dl,%eax
	movl %eax,(%edi)

	movl 20(%ebp),%edi
	movzx %dh,%eax
	movl %eax,(%edi)

	movl $1,%eax
	jmp rpeDone

rpeFail:
	xorl %eax,%eax

rpeDone:
	popl %edi
	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadKeyEvent
#
#   Purpose....: Read keyboard event
#
##########################################################################*/

    .global RdosReadKeyEvent
    
RdosReadKeyEvent:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx
	pushl %edi

	UserGate read_key_event_nr
	jc rkeFail

	movl 8(%ebp),%edi
	movzx %ax,%eax
	movl %eax,(%edi)

	movl 12(%ebp),%edi
	movzx %cx,%eax
	movl %eax,(%edi)

	movl 16(%ebp),%edi
	movzx %dl,%eax
	movl %eax,(%edi)

	movl 20(%ebp),%edi
	movzx %dh,%eax
	movl %eax,(%edi)

	movl $1,%eax
	jmp rkeDone

rkeFail:
	xorl %eax,%eax

rkeDone:
	popl %edi
	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosHideMouse
#
#   Purpose....: Hide mouse cursor
#
##########################################################################*/

    .global RdosHideMouse
    
RdosHideMouse:
	pushl %ebp
	movl %esp,%ebp

	UserGate hide_mouse_nr

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosShowMouse
#
#   Purpose....: Show mouse cursor
#
##########################################################################*/

    .global RdosShowMouse
    
RdosShowMouse:
	pushl %ebp
	movl %esp,%ebp

	UserGate show_mouse_nr

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetMousePosition
#
#   Purpose....: Get mouse position
#
#   Parameters.: &x, &y
#
##########################################################################*/

    .global RdosGetMousePosition
    
RdosGetMousePosition:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx

	UserGate get_mouse_position_nr

	movl 8(%ebp),%eax
	movzx %cx,%ecx
	movl %ecx,(%eax)

	movl 12(%ebp),%eax
	movzx %dx,%edx
	movl %edx,(%eax)

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetMousePosition
#
#   Purpose....: Set mouse position
#
#   Parameters.: x, y
#
##########################################################################*/

    .global RdosSetMousePosition
    
RdosSetMousePosition:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%cx
	movw 12(%ebp),%dx
	UserGate set_mouse_position_nr

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetMouseWindow
#
#   Purpose....: Set mouse window
#
#   Parameters.: start x, start y
#                end x, end y
#
##########################################################################*/

    .global RdosSetMouseWindow
    
RdosSetMouseWindow:
	pushl %ebp
	movl %esp,%ebp
	pushl %eax
	pushl %ebx
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%ax
	movw 12(%ebp),%bx
	movw 16(%ebp),%cx
	movw 20(%ebp),%dx
	UserGate set_mouse_window_nr

	popl %edx
	popl %ecx
	popl %ebx
	popl %eax
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetMouseMickey
#
#   Purpose....: Set mouse mickey
#
#   Parameters.: x, y
#
##########################################################################*/

    .global RdosSetMouseMickey
    
RdosSetMouseMickey:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%cx
	movw 12(%ebp),%dx
	UserGate set_mouse_mickey_nr

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetCursorPosition
#
#   Purpose....: Get cursor position
#
#   Parameters.: &x, &y
#
##########################################################################*/

    .global RdosGetCursorPosition
    
RdosGetCursorPosition:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx

	UserGate get_cursor_position_nr

	movl 8(%ebp),%eax
	movzx %cx,%ecx
	movl %ecx,(%eax)

	movl 12(%ebp),%eax
	movzx %dx,%edx
	movl %edx,(%eax)

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetCursorPosition
#
#   Purpose....: Set cursor position
#
#   Parameters.: x, y
#
##########################################################################*/

    .global RdosSetCursorPosition
    
RdosSetCursorPosition:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx

	movw 8(%ebp),%cx
	movw 12(%ebp),%dx
	UserGate set_cursor_position_nr

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetLeftButton
#
#   Purpose....: Check if left button is pressed
#
#   Returns....: TRUE if pressed
#
##########################################################################*/

    .global RdosGetLeftButton
    
RdosGetLeftButton:
	pushl %ebp
	movl %esp,%ebp

	UserGate get_left_button_nr
	jc get_left_rel

	mov $1,%eax
	jmp get_left_done

get_left_rel:
	xorl %eax,%eax

get_left_done:
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRightButton
#
#   Purpose....: Check if right button is pressed
#
#   Returns....: TRUE if pressed
#
##########################################################################*/

    .global RdosGetRightButton
    
RdosGetRightButton:
	pushl %ebp
	movl %esp,%ebp

	UserGate get_right_button_nr
	jc get_right_rel

	mov $1,%eax
	jmp get_right_done

get_right_rel:
	xorl %eax,%eax

get_right_done:
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetLeftButtonPressPosition
#
#   Purpose....: Get left button press position
#
#   Parameters.: &x, &y
#
##########################################################################*/

    .global RdosGetLeftButtonPressPosition
    
RdosGetLeftButtonPressPosition:
	pushl %ebp
	movl %esp,%ebp

	pushl %ecx
	pushl %edx

	UserGate get_left_button_press_position_nr

	movl 8(%ebp),%eax
	movzx %cx,%ecx
	movl %ecx,(%eax)

	movl 12(%ebp),%eax
	movzx %dx,%edx
	movl %edx,(%eax)

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRightButtonPressPosition
#
#   Purpose....: Get right button press position
#
#   Parameters.: &x, &y
#
##########################################################################*/

    .global RdosGetRightButtonPressPosition
    
RdosGetRightButtonPressPosition:
	pushl %ebp
	movl %esp,%ebp

	pushl %ecx
	pushl %edx

	UserGate get_right_button_press_position_nr

	movl 8(%ebp),%eax
	movzx %cx,%ecx
	movl %ecx,(%eax)

	movl 12(%ebp),%eax
	movzx %dx,%edx
	movl %edx,(%eax)

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetLeftButtonReleasePosition
#
#   Purpose....: Get left button release position
#
#   Parameters.: &x, &y
#
##########################################################################*/

    .global RdosGetLeftButtonReleasePosition
    
RdosGetLeftButtonReleasePosition:
	pushl %ebp
	movl %esp,%ebp

	pushl %ecx
	pushl %edx

	UserGate get_left_button_release_position_nr

	movl 8(%ebp),%eax
	movzx %cx,%ecx
	movl %ecx,(%eax)

	movl 12(%ebp),%eax
	movzx %dx,%edx
	movl %edx,(%eax)

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRightButtonReleasePosition
#
#   Purpose....: Get right button release position
#
#   Parameters.: &x, &y
#
##########################################################################*/

    .global RdosGetRightButtonReleasePosition
    
RdosGetRightButtonReleasePosition:
	pushl %ebp
	movl %esp,%ebp

	pushl %ecx
	pushl %edx

	UserGate get_right_button_release_position_nr

	movl 8(%ebp),%eax
	movzx %cx,%ecx
	movl %ecx,(%eax)

	movl 12(%ebp),%eax
	movzx %dx,%edx
	movl %edx,(%eax)

	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadLine
#
#   Purpose....: Read a line from keyboard
#
#   Parameters.: Buffer
#                Size
#
#   Returns....: Read count
#
##########################################################################*/

    .global RdosReadLine
    
RdosReadLine:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%ecx
	UserGate read_con_nr

	popl %edi
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteChar
#
#   Purpose....: Write a character to screen
#
#   Parameters.: Char
#
##########################################################################*/

    .global RdosWriteChar
    
RdosWriteChar:
	pushl %ebp
	movl %esp,%ebp

	movb 8(%ebp),%al
	UserGate write_char_nr

	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteSizeString
#
#   Purpose....: Write a fixed number of characters to screen
#
#   Parameters.: String
#                Count
#
##########################################################################*/

    .global RdosWriteSizeString
    
RdosWriteSizeString:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%ecx
	UserGate write_size_string_nr

	popl %edi
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteString
#
#   Purpose....: Write a string to screen
#
#   Parameters.: String
#
##########################################################################*/

    .global RdosWriteString
    
RdosWriteString:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movl 8(%ebp),%edi
	UserGate write_asciiz_nr

	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosNameToIp
#
#   Purpose....: Convert host name to IP address
#
#   Parameters.: Name
#                
#   Returns....: IP
#
##########################################################################*/

    .global RdosNameToIp
    
RdosNameToIp:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movl 8(%ebp),%edi
	UserGate name_to_ip_nr
	jc rntiFail

	movl %edx,%eax
	jmp rntiDone

rntiFail:
	xorl %eax,%eax

rntiDone:
	popl %edi
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetIp
#
#   Purpose....: Get my IP
#                
#   Returns....: IP
#
##########################################################################*/

    .global RdosGetIp
    
RdosGetIp:
	pushl %ebp
	movl %esp,%ebp

	UserGate get_ip_address_nr
	movl %edx,%eax

    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosIpToName
#
#   Purpose....: Convert IP address to host name
#
#   Parameters.: IP
#                Name                
#                Size
#
##########################################################################*/

    .global RdosIpToName
    
RdosIpToName:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx
	pushl %edi
;
	movl 8(%ebp),%edx
	movl 12(%ebp),%edi
	movl 16(%ebp),%ecx
	UserGate ip_to_name_nr
	jnc ritnDone

ritnFail:
	xorl %eax,%eax

ritnDone:
	popl %edi
	popl %edx
	popl %ecx
	leave
	ret
					    					    
/*##########################################################################
#
#   Name       : RdosPing
#
#   Purpose....: Ping node
#                
#   Parameters.: IP
#                Timeout
#
##########################################################################*/

    .global RdosPing
    
RdosPing:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx
;
	movl 8(%ebp),%edx
	movl 12(%ebp),%eax
	UserGate ping_nr
	jc ping_failed

	movl $1,%eax
	jmp ping_done

ping_failed:
	xorl %eax,%eax

ping_done:
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenTcpConnection
#
#   Purpose....: Open an active connection over TCP
#                
#   Parameters.: RemoteIp
#                LocalPort
#                RemotePort
#                Timeout in ms
#                BufferSize
#
#   Returns....: Conn handle
#
##########################################################################*/

    .global RdosOpenTcpConnection
    
RdosOpenTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%edx
	movw 12(%ebp),%si
	movw 16(%ebp),%di
	movl 20(%ebp),%eax
	movl 24(%ebp),%ecx
	UserGate open_tcp_connection_nr
	mov $0,%eax
	jc rotcDone

	movl %ebx,%eax

rotcDone:
	popl %edi
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateTcpListen
#
#   Purpose....: Create listen handle
#                
#   Parameters.: Port
#                MaxConnections
#                BufferSize
#
#   Returns....: Listen handle
#
##########################################################################*/

    .global RdosCreateTcpListen
    
RdosCreateTcpListen:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi

	movw 8(%ebp),%si
	movw 12(%ebp),%ax
	movl 16(%ebp),%ecx
	UserGate create_tcp_listen_nr
	movzx %bx,%eax
	jnc ctlDone

    xorl %eax,%eax

ctlDone:
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetTcpListen
#
#   Purpose....: Get connection from listen
#                
#   Parameters.: Listen handle
#
#   Returns....: Conn handle
#
##########################################################################*/

    .global RdosGetTcpListen
    
RdosGetTcpListen:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_tcp_listen_nr
	movzx %ax,%eax
	jnc gtlDone

    xorl %eax,%eax

gtlDone:
    popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseTcpListen
#
#   Purpose....: Close TCP listen
#                
#   Parameters.: Listen handle
#
##########################################################################*/

    .global RdosCloseTcpListen
    
RdosCloseTcpListen:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_tcp_listen_nr
	
    popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddWaitForTcpListen
#
#   Purpose....: Add wait object to tcp listen
#                
#   Parameters.: Wait handle
#                Listen handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForTcpListen
    
RdosAddWaitForTcpListen:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	movl 16(%ebp),%ecx
	UserGate add_wait_for_tcp_listen_nr
	movl $1,%eax
	jnc awftlDone

	xorl %eax,%eax

awftlDone:
    popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosWaitForTcpConnection
#
#   Purpose....: Wait for Tcp connection to be established
#                
#   Parameters.: Conn handle
#                Timeout ms
#
##########################################################################*/

    .global RdosWaitForTcpConnection
    
RdosWaitForTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	movl 12(%ebp),%eax
	UserGate wait_for_tcp_connection_nr
	movl $1,%eax
	jnc wftcDone

	xorl %eax,%eax

wftcDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddWaitForTcpConnection
#
#   Purpose....: Add wait object to tcp connection
#                
#   Parameters.: Wait handle
#                Conn handle
#                ID
#
##########################################################################*/

    .global RdosAddWaitForTcpConnection
    
RdosAddWaitForTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx

	movw 8(%ebp),%bx
	movw 12(%ebp),%ax
	movl 16(%ebp),%ecx
	UserGate add_wait_for_tcp_connection_nr
	movl $1,%eax
	jnc awftcDone

	xorl %eax,%eax

awftcDone:
    popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseTcpConnection
#
#   Purpose....: Close Tcp connection
#                
#   Parameters.: Conn handle
#
##########################################################################*/

    .global RdosCloseTcpConnection
    
RdosCloseTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate close_tcp_connection_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDeleteTcpConnection
#
#   Purpose....: Delete Tcp connection
#                
#   Parameters.: Conn handle
#
##########################################################################*/

    .global RdosDeleteTcpConnection
    
RdosDeleteTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate delete_tcp_connection_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAbortTcpConnection
#
#   Purpose....: Abort Tcp connection
#                
#   Parameters.: Conn handle
#
##########################################################################*/

    .global RdosAbortTcpConnection
    
RdosAbortTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate abort_tcp_connection_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosPushTcpConnection
#
#   Purpose....: Push Tcp connection
#                
#   Parameters.: Conn handle
#
##########################################################################*/

    .global RdosPushTcpConnection
    
RdosPushTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate push_tcp_connection_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosPollTcpConnection
#
#   Purpose....: Poll Tcp connection
#                
#   Parameters.: Conn handle
#
#   Returns....: Available bytes in receive buffer
#
##########################################################################*/

    .global RdosPollTcpConnection
    
RdosPollTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate poll_tcp_connection_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosIsTcpConnectionClosed
#
#   Purpose....: Check if connection is closed
#                
#   Parameters.: Conn handle
#
#   Returns....: TRUE if closed
#
##########################################################################*/

    .global RdosIsTcpConnectionClosed
    
RdosIsTcpConnectionClosed:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate is_tcp_connection_closed_nr
	jc rptcClosed

	xorl %eax,%eax
	jmp rptcDone

rptcClosed:
	movl $1,%eax
	
rptcDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRemoteTcpConnectionIp
#
#   Purpose....: Get remote IP
#                
#   Parameters.: Conn handle
#
#   Returns....: IP
#
##########################################################################*/

    .global RdosGetRemoteTcpConnectionIp
    
RdosGetRemoteTcpConnectionIp:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_remote_tcp_connection_ip_nr
	jnc grtciDone

	movl $0xFFFFFFFF,%eax
	
grtciDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRemoteTcpConnectionPort
#
#   Purpose....: Get remote port
#                
#   Parameters.: Conn handle
#
#   Returns....: Port
#
##########################################################################*/

    .global RdosGetRemoteTcpConnectionPort
    
RdosGetRemoteTcpConnectionPort:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_remote_tcp_connection_port_nr
	jnc grtcpDone

	movl $0,%eax
	
grtcpDone:
    movzx %ax,%eax
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetLocalTcpConnectionPort
#
#   Purpose....: Get local port
#                
#   Parameters.: Conn handle
#
#   Returns....: Port
#
##########################################################################*/

    .global RdosGetLocalTcpConnectionPort
    
RdosGetLocalTcpConnectionPort:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movw 8(%ebp),%bx
	UserGate get_local_tcp_connection_port_nr
	jnc gltcpDone

	movl $0,%eax
	
gltcpDone:
    movzx %ax,%eax
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadTcpConnection
#
#   Purpose....: Read data from connection
#                
#   Parameters.: Conn handle
#                Buffer
#                Size
#
#   Returns....: Read bytes
#
##########################################################################*/

    .global RdosReadTcpConnection
    
RdosReadTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	movl 16(%ebp),%ecx
	UserGate read_tcp_connection_nr

	popl %edi
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteTcpConnection
#
#   Purpose....: Write data fto connection
#                
#   Parameters.: Conn handle
#                Buffer
#                Size
#
#   Returns....: Written bytes
#
##########################################################################*/

    .global RdosWriteTcpConnection
    
RdosWriteTcpConnection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%edi
	movl 16(%ebp),%ecx
	UserGate write_tcp_connection_nr

	popl %edi
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetLocalMailslot
#
#   Purpose....: Get local mailslot from name
#                
#   Parameters.: Name
#
#   Returns....: Mailslot handle
#
##########################################################################*/

    .global RdosGetLocalMailslot
    
RdosGetLocalMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%edi
	UserGate get_local_mailslot_nr
	jc rglmFail

	movzx %bx,%eax
	jmp rglmDone

rglmFail:
	xorl %eax,%eax

rglmDone:
	popl %edi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRemoteMailslot
#
#   Purpose....: Get remote mailslot from name
#                
#   Parameters.: IP
#                Name
#
#   Returns....: Mailslot handle
#
##########################################################################*/

    .global RdosGetRemoteMailslot
    
RdosGetRemoteMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edx
	pushl %edi

	movl 8(%ebp),%edx
	movl 12(%ebp),%edi
	UserGate get_remote_mailslot_nr
	jc rgrmFail

	movzx %bx,%eax
	jmp rgrmDone

rgrmFail:
	xorl %eax,%eax

rgrmDone:
	popl %edi
	popl %edx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosFreeMailslot
#
#   Purpose....: Free mailslot
#                
#   Parameters.: Mailslot handle
#
##########################################################################*/

    .global RdosFreeMailslot
    
RdosFreeMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	UserGate free_mailslot_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosSendMailslot
#
#   Purpose....: Send mailslot
#                
#   Parameters.: Mailslot handle
#				 Msg
#				 Size
#				 ReplyBuf
#				 MaxReplySize
#
#   Returns....: Size of reply
#
##########################################################################*/

    .global RdosSendMailslot
    
RdosSendMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movw 8(%ebp),%bx
	movl 12(%ebp),%esi
	movl 16(%ebp),%ecx
	movl 20(%ebp),%edi
	movl 24(%ebp),%eax
	UserGate send_mailslot_nr
	jc smFail

	movl %ecx,%eax
	jmp smDone

smFail:
	movl $0xFFFFFFFF,%eax

smDone:
	popl %edi
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDefineMailslot
#
#   Purpose....: Define mailslot
#                
#   Parameters.: Name
#                Max msg size
#
##########################################################################*/

    .global RdosDefineMailslot
    
RdosDefineMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%ecx
	UserGate define_mailslot_nr

	popl %edi
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReceiveMailslot
#
#   Purpose....: Receive from mailslot
#                
#   Parameters.: Msg buffer
#
#   Returns....: Msg size
#
##########################################################################*/

    .global RdosReceiveMailslot
    
RdosReceiveMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	UserGate receive_mailslot_nr
	movl %ecx,%eax

	popl %edi
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReplyMailslot
#
#   Purpose....: Reply to mailslot
#                
#   Parameters.: Msg buffer
#                Msg size
#
##########################################################################*/

    .global RdosReplyMailslot
    
RdosReplyMailslot:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edi

	movl 8(%ebp),%edi
	movl 12(%ebp),%ecx
	UserGate reply_mailslot_nr

	popl %edi
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetIdeDisc
#
#   Purpose....: Get IDE disc
#                
#   Parameters.: Unit #
#
#   Returns....: Disc #
#
##########################################################################*/

    .global RdosGetIdeDisc
    
RdosGetIdeDisc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movb 8(%ebp),%bl
	UserGate get_ide_disc_nr
	jc get_ide_disc_fail

    movzx %al,%eax
	jmp get_ide_disc_done

get_ide_disc_fail:
	movl $0xFFFFFFFF,%eax

get_ide_disc_done:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetFloppyDisc
#
#   Purpose....: Get floppy disc
#                
#   Parameters.: Unit #
#
#   Returns....: Disc #
#
##########################################################################*/

    .global RdosGetFloppyDisc
    
RdosGetFloppyDisc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movb 8(%ebp),%bl
	UserGate get_floppy_disc_nr
	jc get_floppy_disc_fail

    movzx %al,%eax
	jmp get_floppy_disc_done

get_floppy_disc_fail:
	movl $0xFFFFFFFF,%eax

get_floppy_disc_done:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetDiscInfo
#
#   Purpose....: Get disc info
#                
#   Parameters.: Disc #
#				 Bytes / sector
#				 Total sectors
#				 BIOS sectors / cyl
#				 BIOS heads
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosGetDiscInfo
    
RdosGetDiscInfo:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movb 8(%ebp),%al
	UserGate get_disc_info_nr
	jc get_disc_info_fail

	movl 12(%ebp),%ebx
	movzx %cx,%ecx
	movl %ecx,(%ebx)

	movl 16(%ebp),%ebx
	movl %edx,(%ebx)

	movl 20(%ebp),%ebx
	movzx %si,%esi
	movl %esi,(%ebx)

	movl 24(%ebp),%ebx
	movzx %di,%edi
	movl %edi,(%ebx)

	movl $1,%eax
	jmp get_disc_info_done

get_disc_info_fail:
	xorl %eax,%eax

get_disc_info_done:
	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetDiscInfo
#
#   Purpose....: Set disc info
#                
#   Parameters.: Disc #
#				 Bytes / sector
#				 Total sectors
#				 BIOS sectors / cyl
#				 BIOS heads
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosSetDiscInfo
    
RdosSetDiscInfo:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx
	pushl %esi
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%ecx
	movl 16(%ebp),%edx
	movl 20(%ebp),%esi
	movl 24(%ebp),%edi
	UserGate set_disc_info_nr
	jc set_disc_info_fail

	movl $1,%eax
	jmp set_disc_info_done

set_disc_info_fail:
	xorl %eax,%eax

set_disc_info_done:
	popl %edi
	popl %esi
	popl %edx
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadDisc
#
#   Purpose....: Read from disc
#                
#   Parameters.: Disc #
#				 Sector #
#				 Buffer
#				 Size
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosReadDisc
    
RdosReadDisc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%edx
	movl 16(%ebp),%edi
	movl 20(%ebp),%ecx
	UserGate read_disc_nr
	jc read_disc_fail

	movl $1,%eax
	jmp read_disc_done

read_disc_fail:
	xorl %eax,%eax

read_disc_done:
	popl %edi
	popl %edx
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteDisc
#
#   Purpose....: Write to disc
#                
#   Parameters.: Disc #
#				 Sector #
#				 Buffer
#				 Size
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosWriteDisc
    
RdosWriteDisc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%edx
	movl 16(%ebp),%edi
	movl 20(%ebp),%ecx
	UserGate write_disc_nr
	jc write_disc_fail

	movl $1,%eax
	jmp write_disc_done

write_disc_fail:
	xorl %eax,%eax

write_disc_done:
	popl %edi
	popl %edx
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAllocateFixedDrive
#
#   Purpose....: Allocate fixed drive
#                
#   Parameters.: Drive #
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosAllocateFixedDrive
    
RdosAllocateFixedDrive:
	pushl %ebp
	movl %esp,%ebp

	movb 8(%ebp),%al
	UserGate allocate_fixed_drive_nr
	jc allocate_fixed_drive_fail

	movl $1,%eax
	jmp allocate_fixed_drive_done

allocate_fixed_drive_fail:
	xorl %eax,%eax

allocate_fixed_drive_done:
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAllocateStaticDrive
#
#   Purpose....: Allocate static drive
#                
#   Returns....: Drive #
#
##########################################################################*/

    .global RdosAllocateStaticDrive
    
RdosAllocateStaticDrive:
	pushl %ebp
	movl %esp,%ebp

	UserGate allocate_static_drive_nr
	jc allocate_static_drive_fail

    movzx %al,%eax
	jmp allocate_static_drive_done

allocate_static_drive_fail:
	xorl %eax,%eax

allocate_static_drive_done:
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAllocateDynamicDrive
#
#   Purpose....: Allocate dynamic drive
#                
#   Returns....: Drive #
#
##########################################################################*/

    .global RdosAllocateDynamicDrive
    
RdosAllocateDynamicDrive:
	pushl %ebp
	movl %esp,%ebp

	UserGate allocate_dynamic_drive_nr
	jc allocate_dynamic_drive_fail

    movzx %al,%eax
	jmp allocate_dynamic_drive_done

allocate_dynamic_drive_fail:
	xorl %eax,%eax

allocate_dynamic_drive_done:
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetRdfsInfo
#
#   Purpose....: Get rdfs info
#                
#   Parameters.: Crypt tab
#                Key tab
#                Extent size tab
#
##########################################################################*/

    .global RdosGetRdfsInfo
    
RdosGetRdfsInfo:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%esi
	movl 12(%ebp),%edi
	movl 16(%ebp),%ebx
	UserGate get_rdfs_info_nr

	popl %edi
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetDriveInfo
#
#   Purpose....: Get drive info
#                
#   Parameters.: Drive #
#                Free units
#                Bytes per unit
#                Total units
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosGetDriveInfo
    
RdosGetDriveInfo:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movb 8(%ebp),%al
	UserGate get_drive_info_nr
	jc get_drive_info_fail

	movl 12(%ebp),%ebx
	movl %eax,(%ebx)

	movl 16(%ebp),%ebx
	movzx %cx,%ecx
	movl %ecx,(%ebx)

	movl 20(%ebp),%ebx
	movl %edx,(%ebx)

	movl $1,%eax
	jmp get_drive_info_done

get_drive_info_fail:
	xorl %eax,%eax

get_drive_info_done:
	popl %edx
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDemandLoadDrive
#
#   Purpose....: Demand load drive
#                
#   Parameters.: Drive #
#
##########################################################################*/

    .global RdosDemandLoadDrive
    
RdosDemandLoadDrive:
	pushl %ebp
	movl %esp,%ebp

	movb 8(%ebp),%al
	UserGate demand_load_drive_nr

    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetDriveDiscParam
#
#   Purpose....: Get drive disc parameters
#                
#   Parameters.: Drive #
#                Disc #
#                Start sector
#                Total sectors
#
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosGetDriveDiscParam
    
RdosGetDriveDiscParam:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %edx

	movb 8(%ebp),%al
	UserGate get_drive_disc_param_nr
	jc get_drive_disc_param_fail

	movl 12(%ebp),%ebx
	movzx %al,%eax
	movl %eax,(%ebx)

	movl 16(%ebp),%ebx
	movl %edx,(%ebx)

	movl 20(%ebp),%ebx
	movl %ecx,(%ebx)

	movl $1,%eax
	jmp get_drive_disc_param_done

get_drive_disc_param_fail:
	xorl %eax,%eax

get_drive_disc_param_done:
	popl %edx
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosFormatDrive
#
#   Purpose....: Format drive
#                
#   Parameters.: Disc #
#                Start sector
#                Sectors
#                FS name
#
#   Returns....: Drive #
#
##########################################################################*/

    .global RdosFormatDrive
    
RdosFormatDrive:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %edx
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%edx
	movl 16(%ebp),%ecx
	movl 20(%ebp),%edi
	UserGate format_drive_nr
	jc rfdFail

    movzx %al,%eax
    jmp rfdDone

rfdFail:
    xorl %eax,%eax

rfdDone:
	popl %edi
	popl %edx
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetExeName
#
#   Purpose....: Get name of executable file
#
#   Returns....: Exe pathname
#
##########################################################################*/

    .global RdosGetExeName
    
RdosGetExeName:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	UserGate get_exe_name_nr
	jc rgenFail

    movl %edi,%eax
    jmp rgenDone

rgenFail:
    xorl %eax,%eax

rgenDone:
	popl %edi
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenAdc
#
#   Purpose....: Open handle to ADC channel
#
#   Parameters.: Channel #
#
#   Returns....: Adc handle
#
##########################################################################*/

    .global RdosOpenAdc
    
RdosOpenAdc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%eax
	UserGate open_adc_nr
	movw %bx,%ax

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseAdc
#
#   Purpose....: Close ADC handle
#
#   Parameters.: Adc handle
#
##########################################################################*/

    .global RdosCloseAdc
    
RdosCloseAdc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	UserGate close_adc_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDefineAdcTime
#
#   Purpose....: Define time of next conversion
#
#   Parameters.: Adc handle
#                MSB time
#                LSB time
#
##########################################################################*/

    .global RdosDefineAdcTime
    
RdosDefineAdcTime:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edx

	movl 8(%ebp),%ebx
	movl 12(%ebp),%edx
	movl 16(%ebp),%eax
	UserGate define_adc_time_nr

    popl %edx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadAdc
#
#   Purpose....: Read ADC
#
#   Parameters.: Adc handle
#                
#   Returns....: Value
#
##########################################################################*/

    .global RdosReadAdc
    
RdosReadAdc:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	UserGate read_adc_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadSerialLines
#
#   Purpose....: Read serial lines
#
#   Parameters.: Device
#                &Value
#                
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosReadSerialLines
    
RdosReadSerialLines:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx
	pushl %esi

	movb 8(%ebp),%dh
	UserGate read_serial_lines_nr
	jc rdsFail

	movzx %al,%eax
	movl 12(%ebp),%esi
	movl %eax,(%esi)
	movl $1,%eax
	jmp rdsDone

rdsFail:
	xorl %eax,%eax

rdsDone:
	popl %esi
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosToggleSerialLine
#
#   Purpose....: Toggle serial line
#
#   Parameters.: Device
#                Line
#                
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosToggleSerialLine
    
RdosToggleSerialLine:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx

	movb 8(%ebp),%dh
	movb 12(%ebp),%dl
	UserGate toggle_serial_line_nr
	jc rtsFail

	movl $1,%eax
	jmp rtsDone

rtsFail:
	xorl %eax,%eax

rtsDone:
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadSerialVal
#
#   Purpose....: Read serial value
#
#   Parameters.: Device
#                Line
#                &Val
#                
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosReadSerialVal
    
RdosReadSerialVal:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx
	pushl %esi

	movb 8(%ebp),%dh
	movb 12(%ebp),%dl
	UserGate read_serial_val_nr

    pushfw
	shll $8,%eax
	movl 16(%ebp),%esi
	movl %eax,(%esi)
    popfw
	jc rdvFail

	movl $1,%eax
	jmp rdvDone

rdvFail:
	xorl %eax,%eax

rdvDone:
	popl %esi
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteSerialVal
#
#   Purpose....: Write serial value
#
#   Parameters.: Device
#                Line
#                Val
#                
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosWriteSerialVal
    
RdosWriteSerialVal:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx

	movb 8(%ebp),%dh
	movb 12(%ebp),%dl
	movl 16(%ebp),%eax
	sarl $8,%eax
	UserGate write_serial_val_nr
	jc rwvFail

	movl $1,%eax
	jmp rwvDone

rwvFail:
	xorl %eax,%eax

rwvDone:
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadSerialRaw
#
#   Purpose....: Read serial raw value
#
#   Parameters.: Device
#                Line
#                &Val
#                
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosReadSerialRaw
    
RdosReadSerialRaw:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx
	pushl %esi

	movb 8(%ebp),%dh
	movb 12(%ebp),%dl
	UserGate read_serial_val_nr

    pushfw
	movl 16(%ebp),%esi
	movl %eax,(%esi)
    popfw
	jc rdrFail

	movl $1,%eax
	jmp rdrDone

rdrFail:
	xorl %eax,%eax

rdrDone:
	popl %esi
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteSerialRaw
#
#   Purpose....: Write serial raw value
#
#   Parameters.: Device
#                Line
#                Val
#                
#   Returns....: TRUE if ok
#
##########################################################################*/

    .global RdosWriteSerialRaw
    
RdosWriteSerialRaw:
	pushl %ebp
	movl %esp,%ebp
	pushl %edx

	movb 8(%ebp),%dh
	movb 12(%ebp),%dl
	movl 16(%ebp),%eax
	UserGate write_serial_val_nr
	jc rwrFail

	movl $1,%eax
	jmp rwrDone

rwrFail:
	xorl %eax,%eax

rwrDone:
	popl %edx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenSysEnv
#
#   Purpose....: Open system environment
#                
#   Returns....: Env handle
#
##########################################################################*/

    .global RdosOpenSysEnv
    
RdosOpenSysEnv:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	UserGate open_sys_env_nr
	jc oseFail

	movzx %bx,%eax
	jmp oseDone

oseFail:
	xorl %eax,%eax

oseDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenProcessEnv
#
#   Purpose....: Open process environment
#                
#   Returns....: Env handle
#
##########################################################################*/

    .global RdosOpenProcessEnv
    
RdosOpenProcessEnv:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	UserGate open_proc_env_nr
	jc opeFail

	movzx %bx,%eax
	jmp opeDone

opeFail:
	xorl %eax,%eax

opeDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseEnv
#
#   Purpose....: Close environment
#
#   Parameters.: Env handle
#
##########################################################################*/

    .global RdosCloseEnv
    
RdosCloseEnv:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	UserGate close_env_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosAddEnvVar
#
#   Purpose....: Add environment variable
#
#   Parameters.: Env handle
#                var
#                data
#
##########################################################################*/

    .global RdosAddEnvVar
    
RdosAddEnvVar:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	movl 16(%ebp),%edi
	UserGate add_env_var_nr

	popl %edi
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDeleteEnvVar
#
#   Purpose....: Delete environment variable
#
#   Parameters.: Env handle
#                var
#
##########################################################################*/

    .global RdosDeleteEnvVar
    
RdosDeleteEnvVar:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	UserGate delete_env_var_nr

	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosFindEnvVar
#
#   Purpose....: Find environment variable
#
#   Parameters.: Env handle
#                var
#                data
#
##########################################################################*/

    .global RdosFindEnvVar
    
RdosFindEnvVar:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	movl 16(%ebp),%edi
	UserGate find_env_var_nr
	jc fevFail

	movl $1,%eax
	jmp fevDone

fevFail:
	xorl %eax,%eax

fevDone:
	popl %edi
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGetEnvData
#
#   Purpose....: Get raw environment data
#
#   Parameters.: Env handle
#                data
#
##########################################################################*/

    .global RdosGetEnvData
    
RdosGetEnvData:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%edi
	UserGate get_env_data_nr
	jnc gedDone

	xorw %ax,%ax
	stosw

gedDone:
	popl %edi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosSetEnvData
#
#   Purpose....: Set raw environment data
#
#   Parameters.: Env handle
#                data
#
##########################################################################*/

    .global RdosSetEnvData
    
RdosSetEnvData:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%edi
	UserGate set_env_data_nr

	popl %edi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenSysIni
#
#   Purpose....: Open system ini-file
#
#   Returns....: Ini handle
#
##########################################################################*/

    .global RdosOpenSysIni
    
RdosOpenSysIni:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	UserGate open_sys_ini_nr
	jc osiFail

	movzx %bx,%eax
	jmp osiDone

osiFail:
	xorl %eax,%eax

osiDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCloseIni
#
#   Purpose....: Close ini-file
#
#   Parameters.: Ini handle
#
##########################################################################*/

    .global RdosCloseIni
    
RdosCloseIni:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	UserGate close_ini_nr

	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosGotoIniSection
#
#   Purpose....: Goto ini section
#
#   Parameters.: Ini handle
#                SectionName
#
##########################################################################*/

    .global RdosGotoIniSection
    
RdosGotoIniSection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%edi
	UserGate goto_ini_section_nr
	jc gisFail

	movl $1,%eax
	jmp gisDone

gisFail:
	xorl %eax,%eax

gisDone:
	popl %edi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosRemoveIniSection
#
#   Purpose....: Remove current ini section
#
#   Parameters.: Ini handle
#
##########################################################################*/

    .global RdosRemoveIniSection
    
RdosRemoveIniSection:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx

	movl 8(%ebp),%ebx
	UserGate remove_ini_section_nr
	jc risFail

	movl $1,%eax
	jmp risDone

risFail:
	xorl %eax,%eax

risDone:
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosReadIni
#
#   Purpose....: Read ini var in current section
#
#   Parameters.: Ini handle
#                VarName
#                Data
#                MaxSize
#
##########################################################################*/

    .global RdosReadIni
    
RdosReadIni:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %ecx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	movl 16(%ebp),%edi
	movl 20(%ebp),%ecx
	UserGate read_ini_nr
	jc riFail

	movl $1,%eax
	jmp riDone

riFail:
	xorl %eax,%eax

riDone:
	popl %edi
	popl %esi
	popl %ecx
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosWriteIni
#
#   Purpose....: Write ini var in current section
#
#   Parameters.: Ini handle
#                VarName
#                Data
#
##########################################################################*/

    .global RdosWriteIni
    
RdosWriteIni:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi
	pushl %edi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	movl 16(%ebp),%edi
	UserGate write_ini_nr
	jc wiFail

	movl $1,%eax
	jmp wiDone

wiFail:
	xorl %eax,%eax

wiDone:
	popl %edi
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDeleteIni
#
#   Purpose....: Delete ini var in current section
#
#   Parameters.: Ini handle
#                VarName
#
##########################################################################*/

    .global RdosDeleteIni
    
RdosDeleteIni:
	pushl %ebp
	movl %esp,%ebp
	pushl %ebx
	pushl %esi

	movl 8(%ebp),%ebx
	movl 12(%ebp),%esi
	UserGate delete_ini_nr
	jc diFail

	movl $1,%eax
	jmp diDone

diFail:
	xorl %eax,%eax

diDone:
	popl %esi
	popl %ebx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosCreateFileDrive
#
#   Purpose....: Create a new file-drive
#
#   Parameters.: Drive
#                Size
#                FS name
#                Filename
#
##########################################################################*/

    .global RdosCreateFileDrive
    
RdosCreateFileDrive:
	pushl %ebp
	movl %esp,%ebp
	pushl %ecx
	pushl %esi
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%ecx
	movl 16(%ebp),%esi
	movl 20(%ebp),%edi
	UserGate create_file_drive_nr
	jnc cfdOk

    xorl %eax,%eax
    jmp cfdDone

cfdOk:
	movl $1,%eax

cfdDone:
	popl %edi
	popl %esi
	popl %ecx
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosOpenFileDrive
#
#   Purpose....: Open a new file-drive
#
#   Parameters.: Drive
#                Filename
#
##########################################################################*/

    .global RdosOpenFileDrive
    
RdosOpenFileDrive:
	pushl %ebp
	movl %esp,%ebp
	pushl %edi

	movb 8(%ebp),%al
	movl 12(%ebp),%edi
	UserGate open_file_drive_nr
	jnc ofdOk

	xorl %eax,%eax
	jmp ofdDone

ofdOk:
	movl $1,%eax

ofdDone:
	popl %edi
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosEnableStatusLed
#
#   Purpose....: Enable status LED
#
##########################################################################*/

    .global RdosEnableStatusLed
    
RdosEnableStatusLed:
	pushl %ebp
	movl %esp,%ebp
	UserGate enable_status_led_nr
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosDisableStatusLed
#
#   Purpose....: Disable status LED
#
##########################################################################*/

    .global RdosDisableStatusLed
    
RdosDisableStatusLed:
	pushl %ebp
	movl %esp,%ebp
	UserGate disable_status_led_nr
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosStartWatchdog
#
#   Purpose....: Start watchdog
#
#   Parameters.: Timeout, ms
#
##########################################################################*/

    .global RdosStartWatchdog
    
RdosStartWatchdog:
	pushl %ebp
	movl %esp,%ebp
;
	movl 8(%ebp),%eax
	UserGate start_watchdog_nr
;	
    leave
    ret
					    					    
/*##########################################################################
#
#   Name       : RdosKickWatchdog
#
#   Purpose....: Kick watchdog
#
##########################################################################*/

    .global RdosKickWatchdog
    
RdosKickWatchdog:
	pushl %ebp
	movl %esp,%ebp
	UserGate kick_watchdog_nr
    leave
    ret
					    
