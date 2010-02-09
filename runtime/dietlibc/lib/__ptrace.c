/* we need this because we need to use the glibc prototype which uses
 * varargs :-( */
#include <errno.h>
#define ptrace fnord
#include <sys/ptrace.h>
#undef ptrace
#include <sys/types.h>
#include <unistd.h>

extern int __diet_ptrace(int request, pid_t pid, void *addr, void *data);
int ptrace(int request, pid_t pid, void *addr, void *data);

int ptrace(int request, pid_t pid, void *addr, void *data) {
  errno=0;
  switch (request) {
    case PTRACE_TRACEME: case PTRACE_KILL: case PTRACE_ATTACH:
    case PTRACE_DETACH:
      return (__diet_ptrace (request, pid, NULL, NULL));
    case PTRACE_PEEKDATA: case PTRACE_PEEKUSER: case PTRACE_PEEKTEXT:
      {
	long result;
	if (__diet_ptrace (request, pid, addr, &result) == -1)
		return (-1);
	return (result);
      }
    default:
      return (__diet_ptrace (request, pid, addr, data));
  }
}
