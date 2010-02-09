#ifndef _PATHS_H
#define _PATHS_H

#define _PATH_BSHELL "/bin/sh"
#define _PATH_DEFPATH "/bin:/usr/bin:"

#define _PATH_DEVNULL "/dev/null"

#define _PATH_CONSOLE "/dev/console"

#define _PATH_PASSWD "/etc/passwd"
#define _PATH_GROUP "/etc/group"
#define _PATH_SHADOW "/etc/shadow"

#define	_PATH_SHELLS	"/etc/shells"

#define _PATH_VARRUN	"/var/run/"

/* puke */
#define _PATH_MAILDIR	"/var/mail"

#define _PATH_TTY	"/dev/tty"
#define _PATH_MNTTAB	"/etc/fstab"
#define _PATH_MOUNTED	"/etc/mtab"
#define	_PATH_DEV	"/dev/"

#define _PATH_TMP	"/tmp/"

#define _PATH_UTMP	"/var/run/utmp"
#define _PATH_WTMP	"/var/log/wtmp"
#ifdef _BSD_SOURCE
/* die, BSD, die!!! */
#define UTMP_FILE	_PATH_UTMP
#define WTMP_FILE	_PATH_WTMP
#endif
#define _PATH_UTMPX	_PATH_UTMP
#define _PATH_WTMPX	_PATH_WTMP

#endif
