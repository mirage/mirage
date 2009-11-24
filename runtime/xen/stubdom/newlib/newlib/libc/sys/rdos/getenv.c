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
# getenv.c                                                                
# getenv function implementation
#
##########################################################################*/

/*
FUNCTION
<<getenv>>---look up environment variable

INDEX
	getenv
INDEX
	environ

ANSI_SYNOPSIS
	#include <stdlib.h>
	char *getenv(const char *<[name]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	char *getenv(<[name]>)
	char *<[name]>;

DESCRIPTION
<<getenv>> searches the list of environment variable names and values
(using the global pointer ``<<char **environ>>'') for a variable whose
name matches the string at <[name]>.  If a variable name matches,
<<getenv>> returns a pointer to the associated value.

RETURNS
A pointer to the (string) value of the environment variable, or
<<NULL>> if there is no such environment variable.

PORTABILITY
<<getenv>> is ANSI, but the rules for properly forming names of environment
variables vary from one system to another.

This function is not thread-safe, but does it need to be??
There is an reentrant class that should be used if reentrance is required

*/

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <rdos.h>

static char envbuf[256];

char *getenv(const char *name)
{
    int handle;
    char *ptr = 0;

    handle = RdosOpenSysEnv();
    if (handle)
    {
        if (RdosFindEnvVar(handle, name, envbuf))
            ptr = envbuf;
    }
    RdosCloseEnv(handle);
    return ptr;
}
