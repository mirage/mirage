#include "syscalls.h"

syscall_weak(syslog,__syscall_syslog,klogctl)
