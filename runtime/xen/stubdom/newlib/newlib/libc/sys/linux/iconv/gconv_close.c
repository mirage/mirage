/* Release any resource associated with given conversion descriptor.
   Copyright (C) 1997, 1998, 1999, 2000 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1997.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <stdlib.h>

#include <gconv_int.h>


int
internal_function
__gconv_close (__gconv_t cd)
{
  struct __gconv_step *srunp;
  struct __gconv_step_data *drunp;
  size_t nsteps;

  /* Free all resources by calling destructor functions and release
     the implementations.  */
  srunp = cd->__steps;
  nsteps = cd->__nsteps;
  drunp = cd->__data;
  do
    {
      struct __gconv_trans_data *transp;

      transp = drunp->__trans;
      while (transp != NULL)
	{
	  struct __gconv_trans_data *curp = transp;
	  transp = transp->__next;

	  if (__builtin_expect (curp->__trans_end_fct != NULL, 0))
	    curp->__trans_end_fct (curp->__data);

	  free (curp);
	}

      if (!(drunp->__flags & __GCONV_IS_LAST) && drunp->__outbuf != NULL)
	free (drunp->__outbuf);
    }
  while (!((drunp++)->__flags & __GCONV_IS_LAST));

  /* Free the data allocated for the descriptor.  */
  free (cd);

  /* Close the participating modules.  */
  return __gconv_close_transform (srunp, nsteps);
}
