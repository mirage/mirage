#include <sys/unistd.h>
#include <errno.h>

extern char **environ;

int
execv (const char *path, char * const *args) {
	extern int execve (const char *, char * const *, char * const*);
	return execve (path, args, environ);
}

int
execl(const char *path, const char *arg1, ...) {
	return execv (path, &arg1);
}

/*
 * Copy string, until c or <nul> is encountered.
 * NUL-terminate the destination string (s1).
 */

static char *
strccpy (char *s1, char *s2, char c) {
	char *dest = s1;
	while (*s2 && *s2 != c) {
		*s1++ = *s2++;
	}
	*s1 = 0;
	return dest;
}

int
execvp(const char *file, char * const *args) {
	extern char *getenv (const char *);  
	char *path = getenv ("PATH");
	char buf[MAXNAMLEN];

	if (file[0] == '/') {	/* absolute pathname -- easy out */
		return execv (file, args);
	}

	buf[0] = 0;	/* lots of initialization here 8-) */
	while (*path) {
		strccpy (buf, path, ':');
		strcat (buf, "/");
		strcat (buf, file);
		execv (buf, args);
		if (errno != ENOENT)
			return -1;
		while (*path && *path != ':')
			path++;
	}
	return -1;
}
