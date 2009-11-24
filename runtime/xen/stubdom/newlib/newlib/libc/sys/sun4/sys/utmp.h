#ifndef _UTMP_H
# define _UTMP_H

#include <sys/types.h>

# define UTMP_FILE "/etc/utmp"
# define WTMP_FILE "/etc/wtmp"

struct utmp {
	char	ut_user[8];	/* how limited */
	char	ut_id[4];	/* ditto */
	char	ut_line[12];	/* I'm repeating myself */
	short	ut_pid;
	short	ut_type;
	struct exit_status {
		short e_termination;
		short e_exit;
	} ut_exit;		/* for DEAD_PROCESS processes */
	time_t	ut_time;
};

/* Definitions for ut_type fields */

# define	EMPTY	0
# define	RUN_LVL	1
# define	BOOT_TIME	2
# define	OLD_TIME	3
# define	NEW_TIME	4
# define	INIT_PROCESS	5
# define	LOGIN_PROCESS	6
# define	USER_PROCESS	7
# define	DEAD_PROCESS	8
# define	ACCOUNTING	9
# define	UTMAXTYPE	ACCOUNTING

# define	RUNLVL_MSG	"run-level %c"
# define	BOOT_MSG	"system boot"
# define	OTIME_MSG	"old time"
# define	NTIME_MSG	"new time"

#endif	/* _UTMP_H */


