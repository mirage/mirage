#ifndef _ATTR_XATTR_H
#define _ATTR_XATTR_H

#include <sys/cdefs.h>
#include <sys/types.h>

enum { XATTR_CREATE=1, XATTR_REPLACE=2 };
#define XATTR_CREATE XATTR_CREATE
#define XATTR_REPLACE XATTR_REPLACE

#define XATTR_SECURITY_PREFIX	"security."

int setxattr(const char *path, const char *name, const void *value, size_t size, int flags);
int lsetxattr(const char *path, const char *name, const void *value, size_t size, int flags);
int fsetxattr(int filedes, const char *name, const void *value, size_t size, int flags);

ssize_t getxattr(const char *path, const char *name, void *value, size_t size);
ssize_t lgetxattr(const char *path, const char *name, void *value, size_t size);
ssize_t fgetxattr(int filedes, const char *name, void *value, size_t size);

ssize_t listxattr(const char *path, char *list, size_t size);
ssize_t llistxattr(const char *path, char *list, size_t size);
ssize_t flistxattr(int filedes, char *list, size_t size);

int removexattr(const char *path, const char *name);
int lremovexattr(const char *path, const char *name);
int fremovexattr(int filedes, const char *name);

#endif
