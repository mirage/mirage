/*
 *  This file lists the minimums for the limits set by each of
 *  the POSIX features subsets.
 *
 *  XXX: Careful attention needs to be paid to section 2.8 in 1003.1b-1993
 *       to segregrate the variables below based on their "class" according
 *       to our implementation.  We also need to set the Run-Time Invariant
 *       and other related values.
 *
 *  $Id: limits.h,v 1.2 1999/09/07 21:18:36 ranjith Exp $
 */

#ifndef _GCC_LIMITS_H_  /* if we have not seen gcc's limits.h yet */
#include_next <limits.h>
#endif

#include <sys/syslimits.h>

#ifndef __POSIX_LIMITS_h
#define __POSIX_LIMITS_h

/****************************************************************************
 ****************************************************************************
 *                                                                          *
 *         P1003.1b-1993 defines the constants below this comment.          *
 *                                                                          *
 **************************************************************************** 
 ****************************************************************************/

#define _POSIX_AIO_LISTIO_MAX   2
#define _POSIX_AIO_MAX          1
#define _POSIX_ARG_MAX          4096
#define _POSIX_CHILD_MAX        6
#define _POSIX_DELAYTIMER_MAX   32
#define _POSIX_LINK_MAX         8
#define _POSIX_MAX_CANON        255
#define _POSIX_MAX_INPUT        255
#define _POSIX_MQ_OPEN_MAX      8
#define _POSIX_MQ_PRIO_MAX      32
#define _POSIX_NAME_MAX         255
#define _POSIX_NGROUPS_MAX      0
#define _POSIX_OPEN_MAX         16
#define _POSIX_PATH_MAX         255
#define _POSIX_PIPE_BUF         512
#define _POSIX_RTSIG_MAX        8
#define _POSIX_SEM_NSEMS_MAX    256
#define _POSIX_SEM_VALUE_MAX    32767
#define _POSIX_SIGQUEUE_MAX     32
#define _POSIX_SSIZE_MAX        32767
#define _POSIX_STREAM_MAX       8
#define _POSIX_TIMER_MAX        32
#define _POSIX_TZNAME_MAX       3

/*
 *  Definitions of the following may be omitted if the value is >= stated
 *  minimum but is indeterminate.
 */

#define AIO_LISTIO_MAX          2
#define AIO_MAX                 1
#define AIO_PRIO_DELTA_MAX      0
#define DELAYTIMER_MAX          32
#define MQ_OPEN_MAX             8
#define MQ_PRIO_MAX             32
#define PAGESIZE                1
#define RTSIG_MAX               8
#define SEM_NSEMS_MAX           256
#define SEM_VALUE_MAX           32767
#define SIGQUEUE_MAX            32
#define STREAM_MAX              8
#define TIMER_MAX               32
#define TZNAME_MAX              3

/*
 *  Invariant values
 */

#define SSIZE_MAX               32767

/*
 *  Maximum Values
 */

#define _POSIX_CLOCKRES_MIN      0   /* in nanoseconds */

/****************************************************************************
 ****************************************************************************
 *                                                                          *
 *         P1003.1c/D10 defines the constants below this comment.           *
 *
 *  XXX: doc seems to have printing problems in this table :(
 *                                                                          *
 **************************************************************************** 
 ****************************************************************************/

#define _POSIX_LOGIN_NAME_MAX                9
#define _POSIX_THREAD_DESTRUCTOR_ITERATIONS  4
#define _POSIX_THREAD_KEYS_MAX               28
#define _POSIX_THREAD_THREADS_MAX            64
#define _POSIX_TTY_NAME_MAX                  9

/*
 *  Definitions of the following may be omitted if the value is >= stated
 *  minimum but is indeterminate.
 *
 *  NOTE:  LOGIN_NAME_MAX is named LOGNAME_MAX under Solaris 2.x.  Perhaps
 *         the draft specification will be changing.  jrs 05/24/96
 */

#define LOGIN_NAME_MAX                      _POSIX_LOGIN_NAME_MAX
#define TTY_NAME_MAX                        _POSIX_TTY_NAME_MAX
#define PTHREAD_DESTRUCTOR_ITERATIONS       _POSIX_THREAD_DESTRUCTOR_ITERATIONS

/*
 *  RTEMS is smart enough to give us the minimum stack size if we ask
 *  for too little.  Because the real RTEMS limit for this is cpu dependent
 *  AND rtems header files are not installed yet, we cannot use the cpu
 *  dependent constant CPU_STACK_MINIMUM_SIZE.  Moreover, we do not want
 *  to duplicate that information here so we will just let RTEMS magically
 *  give us its minimum stack size.
 *
 *  NOTE:  The other alternative is to have this be a macro for a 
 *         routine in RTEMS which returns the constant.
 */

#define PTHREAD_STACK_MIN                   0

/*
 *  The maximum number of keys (PTHREAD_KEYS_MAX) and threads
 *  (PTHREAD_THREADS_MAX) are configurable and may exceed the minimum.
 *
#define PTHREAD_KEYS_MAX                    _POSIX_THREAD_KEYS_MAX
#define PTHREAD_THREADS_MAX                 _POSIX_THREAD_THREADS_MAX
*/


/****************************************************************************
 ****************************************************************************
 *                                                                          *
 *         P1003.4b/D8 defines the constants below this comment.            *
 *                                                                          *
 **************************************************************************** 
 ****************************************************************************/

#define _POSIX_INTERRUPT_OVERRUN_MAX        32

/*
 *  Definitions of the following may be omitted if the value is >= stated
 *  minimum but is indeterminate.
 */

#define INTERRUPT_OVERRUN_MAX               32

/*
 *  Pathname Variables
 */

#define MIN_ALLOC_SIZE      
#define REC_MIN_XFER_SIZE   
#define REC_MAX_XFER_SIZE   
#define REC_INCR_XFER_SIZE  
#define REC_XFER_ALIGN      
#define MAX_ATOMIC_SIZE     

#endif
/* end of include file */
