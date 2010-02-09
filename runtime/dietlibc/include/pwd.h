#ifndef _PWD_H
#define _PWD_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <stdio.h>

__BEGIN_DECLS

struct passwd {
  char *pw_name;		/* Username.  */
  char *pw_passwd;		/* Password.  */
  uid_t pw_uid;			/* User ID.  */
  gid_t pw_gid;			/* Group ID.  */
  char *pw_gecos;		/* Real name.  */
  char *pw_dir;			/* Home directory.  */
  char *pw_shell;		/* Shell program.  */
};

extern struct passwd *getpwuid (uid_t uid) __THROW;
extern struct passwd *getpwnam (const char *name) __THROW;

extern struct passwd *getpwent(void) __THROW;
extern void setpwent(void) __THROW;
extern void endpwent(void) __THROW;
extern int putpwent(const struct passwd *p, FILE *stream) __THROW __attribute_dontuse__;

int getpwent_r(struct passwd *res, char *buf, size_t buflen,
	       struct passwd **res_sig) __THROW;
int getpwnam_r(const char* name,
	       struct passwd *res, char *buf, size_t buflen,
	       struct passwd **res_sig) __THROW;
int getpwuid_r(uid_t uid,
	       struct passwd *res, char *buf, size_t buflen,
	       struct passwd **res_sig) __THROW;

/* NON STANDARD */
extern struct passwd *fgetpwent(FILE * fp);
extern void fsetpwent(int fd) __THROW;
extern int fgetpwent_r(int fd,struct passwd *res, 
		char *buf, size_t buflen,
	       	struct passwd **res_sig);

__END_DECLS

#endif
