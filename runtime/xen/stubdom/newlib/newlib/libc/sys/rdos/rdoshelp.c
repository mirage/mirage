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
# rdoshelp.c                                                                
# implementation of various structures and helpers
#
##########################################################################*/

#include <reent.h>
#include <rdos.h>
#include <stdio.h>

char *__env[1] = { 0 }; 
char **environ = __env; 

static int once_section;
static int key_section;

/*##########################################################################
#
#   Name       : _get_impure_data_size
#
#   Purpose....: Get size of _reent structure
#
#   In params..: *
#   Out params.: *
#   Returns....: size
#
##########################################################################*/
int get_impure_data_size()
{
	return sizeof(struct _reent);
}

/*##########################################################################
#
#   Name       : __rdos_thread_once
#
#   Purpose....: Emulate GCC pthread_once
#
#   In params..: Handle initially 0
#              : function to initially call
#   Out params.: *
#   Returns....: result
#
##########################################################################*/
int __rdos_thread_once (int *handle, void (*func) (void))
{
    if (handle == 0 || func == 0)
        return 0;
         
    RdosEnterSection(once_section);
    if (*handle == 0)
        (*func)();
    else
        *handle = 1;
    RdosLeaveSection(once_section);
    return 0;
}

/*##########################################################################
#
#   Name       : __rdos_thread_mutex_init
#
#   Purpose....: Emulate GCC pthread_thread_mutex_init
#
#   In params..: *
#   Out params.: *
#   Returns....: handle
#
##########################################################################*/
int __rdos_thread_mutex_init (void)
{
    return RdosCreateSection();
}

/*##########################################################################
#
#   Name       : __rdos_thread_mutex_lock
#
#   Purpose....: Emulate GCC pthread_thread_mutex_lock
#
#   In params..: handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int __rdos_thread_mutex_lock (int handle)
{
    RdosEnterSection(handle);
    return 0;
}

/*##########################################################################
#
#   Name       : __rdos_thread_mutex_trylock
#
#   Purpose....: Emulate GCC pthread_thread_mutex_trylock
#                Try is not yet implemented, and lock is used.
#
#   In params..: handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int __rdos_thread_mutex_trylock (int handle)
{
    RdosEnterSection(handle);
    return 0;
}

/*##########################################################################
#
#   Name       : __rdos_thread_mutex_unlock
#
#   Purpose....: Emulate GCC pthread_thread_mutex_unlock
#
#   In params..: handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int __rdos_thread_mutex_unlock (int handle)
{
    RdosLeaveSection(handle);
    return 0;
}

/*##########################################################################
#
#   Name       : __init_rdos
#
#   Purpose....: Init RDOS specific data
#
#   In params..: reent structure
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void __init_rdos(struct _reent *reent)
{
	once_section = RdosCreateSection();
	_REENT_INIT_PTR(reent);
	__sinit(reent);
}
