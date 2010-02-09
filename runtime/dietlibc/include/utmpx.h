#ifndef _UTMPX_H
#define _UTMPX_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <sys/time.h>
#include <paths.h>

/* For the getutmp{,x} functions we need the `struct utmp'.  */
#ifdef _GNU_SOURCE
struct utmp;
#endif

#define __UT_LINESIZE	32
#define __UT_NAMESIZE	32
#define __UT_HOSTSIZE	256

__BEGIN_DECLS

/* The structure describing the status of a terminated process.  This
   type is used in `struct utmpx below.  */
struct __exit_status
  {
    short int e_termination;	/* Process termination status.  */
    short int e_exit;		/* Process exit status.  */
  };

/* The structure describing an entry in the user accounting database.  */
struct utmpx
{
  short int ut_type;		/* Type of login.  */
  pid_t ut_pid;			/* Process ID of login process.  */
  char ut_line[__UT_LINESIZE];	/* Devicename.  */
  char ut_id[4];		/* Inittab ID.  */
  char ut_user[__UT_NAMESIZE];	/* Username.  */
  char ut_host[__UT_HOSTSIZE];	/* Hostname for remote login.  */
  struct __exit_status ut_exit;	/* Exit status of a process marked
				   as DEAD_PROCESS.  */
/* The ut_session and ut_tv fields must be the same size when compiled
   32- and 64-bit.  This allows data files and shared memory to be
   shared between 32- and 64-bit applications.  */
#if __WORDSIZE == 64 && defined __WORDSIZE_COMPAT32
  int32_t ut_session;		/* Session ID, used for windowing.  */
  struct
  {
    int32_t tv_sec;		/* Seconds.  */
    int32_t tv_usec;		/* Microseconds.  */
  } ut_tv;			/* Time entry was made.  */
#else
  long int ut_session;		/* Session ID, used for windowing.  */
  struct timeval ut_tv;		/* Time entry was made.  */
#endif
  int32_t ut_addr_v6[4];	/* Internet address of remote host.  */
  char __unused[20];		/* Reserved for future use.  */
};

#ifndef _UTMP_H			/* utmp.h hasn't already defined these. */
/* Values for the `ut_type' field of a `struct utmpx'.  */
#define EMPTY		0	/* No valid user accounting information.  */

#define RUN_LVL		1	/* The system's runlevel.  */
#define BOOT_TIME	2	/* Time of system boot.  */
#define NEW_TIME	3	/* Time after system clock changed.  */
#define OLD_TIME	4	/* Time when system clock changed.  */

#define INIT_PROCESS	5	/* Process spawned by the init process.  */
#define LOGIN_PROCESS	6	/* Session leader of a logged in user.  */
#define USER_PROCESS	7	/* Normal process.  */
#define DEAD_PROCESS	8	/* Terminated process.  */

#define ACCOUNTING	9
#endif

/* Apparently, these functions are all considered possible cancellation
 * points, thus no __THROW */

struct utmpx *getutxent(void);
struct utmpx *getutxid(struct utmpx *ut);
struct utmpx *getutxline(struct utmpx *ut);

struct utmpx *pututxline(struct utmpx *ut);

void setutxent(void);
void endutxent(void);

#ifdef _GNU_SOURCE
void utmpxname (const char *file);
void updwtmpx (const char *wtmpx_file, const struct utmpx *utmpx);
void getutmp (const struct utmpx *utmpx, struct utmp *utmp);
void getutmpx (const struct utmp *utmp, struct utmpx *utmpx);
#endif

__END_DECLS

#endif
