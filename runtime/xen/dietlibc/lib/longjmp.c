#include <setjmp.h>
#include <signal.h>

void __longjmp(void*env,int val);

void __libc_longjmp(sigjmp_buf env,int val);
void __libc_longjmp(sigjmp_buf env,int val) {
  if (env[0].__mask_was_saved) {
    sigprocmask(SIG_SETMASK,(sigset_t*)&env[0].__saved_mask,0);
  }
  if (val==0) val=1;
  __longjmp(env[0].__jmpbuf,val);
}
void __siglongjmp(sigjmp_buf env,int val) __attribute__((alias("__libc_longjmp")));
void longjmp(sigjmp_buf env,int val) __attribute__((weak,alias("__libc_longjmp")));
void siglongjmp(sigjmp_buf env,int val) __attribute__((weak,alias("__libc_longjmp")));
