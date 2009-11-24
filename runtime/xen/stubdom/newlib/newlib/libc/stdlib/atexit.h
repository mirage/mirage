/*
 *	Common definitions for atexit-like routines
 */

enum __atexit_types
{
  __et_atexit,
  __et_onexit,
  __et_cxa
};

void __call_exitprocs _PARAMS ((int, _PTR));
int __register_exitproc _PARAMS ((int, void (*fn) (void), _PTR, _PTR));

