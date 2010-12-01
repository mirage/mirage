#include <setjmp.h>
#include <signal.h>

int __sigjmp_save(sigjmp_buf env,int savemask);
int __sigjmp_save(sigjmp_buf env,int savemask) {
  env[0].__mask_was_saved = 0;
  if (savemask) {
    env[0].__mask_was_saved=(sigprocmask(SIG_BLOCK,(sigset_t*)0,&env[0].__saved_mask)==0);
  }
  return 0;
}
