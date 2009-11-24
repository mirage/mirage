#include <sys/types.h>
#include <local.h>

/* Shared timezone information for libc/time functions.  */
static __tzinfo_type tzinfo = {1, 0,
    { {'J', 0, 0, 0, 0, (time_t)0, 0L },
      {'J', 0, 0, 0, 0, (time_t)0, 0L } 
    } 
};

__tzinfo_type *
__gettzinfo (void)
{
  return &tzinfo;
}
