/* The getdate_err variable is stored in the reentrancy structure.  This
   function returns its address for use by the getdate_err macro defined in
   time.h.  */

#include <errno.h>
#include <reent.h>

#ifndef _REENT_ONLY

int *
__getdate_err ()
{
  struct _reent *ptr = _REENT;
  _REENT_CHECK_MISC(ptr);
  return _REENT_GETDATE_ERR_P(ptr);
}

#endif
