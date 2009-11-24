/* h_reset.c -- Setup default reset handler.
 * 
 * Copyright (c) 2004  Red Hat, Inc. All rights reserved.
 *
 * This copyrighted material is made available to anyone wishing to use, modify,
 * copy, or redistribute it subject to the terms and conditions of the BSD 
 * License.  This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY expressed or implied, including the implied 
 * warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  A copy 
 * of this license is available at http://www.opensource.org/licenses. Any 
 * Red Hat trademarks that are incorporated in the source code or documentation
 * are not subject to the BSD License and may only be used or replicated with 
 * the express permission of Red Hat, Inc.
 */

#pragma weak _handler_RESET

void _handler_RESET(void) __attribute__((section(".hwinit")));

extern void _start(void);
void
_handler_RESET(void)
{
  mep_di();
  goto *(&_start); 	
}
