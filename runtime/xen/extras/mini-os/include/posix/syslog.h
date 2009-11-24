#ifndef _POSIX_SYSLOG_H
#define _POSIX_SYSLOG_H

#include <stdarg.h>

#define LOG_PID 0
#define LOG_CONS 0
#define LOG_NDELAY 0
#define LOG_ODELAY 0
#define LOG_NOWAIT 0

#define LOG_KERN 0
#define LOG_USER 0
#define LOG_MAIL 0
#define LOG_NEWS 0
#define LOG_UUCP 0
#define LOG_DAEMON 0
#define LOG_AUTH 0
#define LOG_CRON 0
#define LOG_LPR 0

/* TODO: support */
#define LOG_EMERG 0
#define LOG_ALERT 1
#define LOG_CRIT 2
#define LOG_ERR 3
#define LOG_WARNING 4
#define LOG_NOTICE 5
#define LOG_INFO 6
#define LOG_DEBUG 7

void openlog(const char *ident, int option, int facility);
void syslog(int priority, const char *format, ...);
void closelog(void);
void vsyslog(int priority, const char *format, va_list ap);

#endif /* _POSIX_SYSLOG_H */
