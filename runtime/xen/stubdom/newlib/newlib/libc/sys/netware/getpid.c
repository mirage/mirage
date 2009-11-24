/* NetWare version of getpid.  This is supposed to return a unique
   identifier which is used to create temporary file names.  We use
   the thread ID.  I hope this is unique.  */

#include <unistd.h>

pid_t
getpid ()
{
  return GetThreadID ();
}
