#include <write12.h>

int rcmd(char **ahost, int inport, const char *locuser,
	 const char *remuser, const char *cmd, int *fd2p);
int rcmd(char **ahost, int inport, const char *locuser,
	 const char *remuser, const char *cmd, int *fd2p) {
  __write2("for security reasons, rcmd is not supported by the diet libc.\n");
  return -1;
}

