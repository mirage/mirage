/*
	setjmp.h
	stubs for future use.
*/

#ifndef _SETJMP_H_
#ifdef __cplusplus
extern "C" {
#endif
#define _SETJMP_H_

#include "_ansi.h"
#include <machine/setjmp.h>
#include <signal.h> /* for sigset_t and sigprocmask */

typedef struct __sigjmpbuf
{
  __jmp_buf __buf;
  int __is_mask_saved;
  sigset_t __saved_mask;
} sigjmp_buf;

typedef __jmp_buf jmp_buf;

void	_EXFUN(longjmp,(jmp_buf __jmpb, int __retval));
int	_EXFUN(setjmp,(jmp_buf __jmpb));
void	_EXFUN(siglongjmp,(sigjmp_buf __jmpb, int __retval));
int	_EXFUN(sigsetjmp,(sigjmp_buf __jmpb, int __savemask));

/* sigsetjmp is implemented as macro using setjmp */

#define sigsetjmp(__jmpb, __savemask) \
                 ( __jmpb.__is_mask_saved = __savemask && \
                   (sigprocmask (SIG_BLOCK, NULL, &__jmpb.__saved_mask) == 0), \
                    setjmp (__jmpb.__buf) )

#ifdef __cplusplus
}
#endif
#endif /* _SETJMP_H_ */

