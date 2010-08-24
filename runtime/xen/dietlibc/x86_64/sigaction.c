#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <syscalls.h>

int __rt_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact, long nr);

#if 0
static void __restore_rt(void) {
  asm volatile ("syscall" : : "a" (__NR_rt_sigreturn));
}
#else
/* exactly match MD_FALLBACK_FRAME_STATE_FOR in gcc-3.4/gcc/config/i386/linux64.h */
void __restore_rt(void);
asm(".text\n" ".align 16\n"
    "__restore_rt:"
    "movq $15, %rax\n" "syscall\n" "hlt\n");
#endif

int __libc_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
int __libc_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) {
  struct sigaction *newact = (struct sigaction *)act;
  if (act) {
	newact = alloca(sizeof(*newact));
	newact->sa_handler = act->sa_handler;
	newact->sa_flags = act->sa_flags | SA_RESTORER;
	newact->sa_restorer = &__restore_rt;
	newact->sa_mask = act->sa_mask;
  }
  return __rt_sigaction(signum, newact, oldact, _NSIG/8);
}

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact)
__attribute__((weak,alias("__libc_sigaction")));
