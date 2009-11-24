#include <ieeefp.h>
#include <machine/registers.h>


fp_except _DEFUN(fpsetmask,(newmask),
		fp_except newmask)

{
  fp_except oldmask;
  v60_tkcw_type tkcw;
  
  sysv60(0, 8, &tkcw);
  oldmask = tkcw.fp_trap;
  tkcw.fp_trap = newmask;
  sysv60(0, 8, &tkcw);
  return oldmask;

}

fp_except _DEFUN_VOID(fpgetmask)
{
  v60_tkcw_type tkcw;
  sysv60(0, 8, &tkcw);
  return tkcw.fp_trap;
}


fp_rnd _DEFUN_VOID(fpgetround)
{
  v60_tkcw_type tkcw;
  sysv60(0, 8, &tkcw);
  return tkcw.fp_rounding;
}

fp_rnd _DEFUN(fpsetround,(rnd),
	     fp_rnd rnd)
{
  fp_rnd oldrnd;
  v60_tkcw_type tkcw;
  
  sysv60(0, 8, &tkcw);
  oldrnd = tkcw.fp_rounding;
  tkcw.fp_rounding = rnd;
  sysv60(0, 8, &tkcw);
  return oldrnd;
}





fp_rdi _DEFUN_VOID(fpgetroundtoi)
{
  v60_tkcw_type tkcw;
  sysv60(0, 8, &tkcw);
  return tkcw.integer_rounding;
}

fp_rdi _DEFUN(fpsetroundtoi,(rnd),
	     fp_rdi rnd)
{
  fp_rdi oldrnd;
  v60_tkcw_type tkcw;
  
  sysv60(0, 8, &tkcw);
  oldrnd = tkcw.integer_rounding;
  tkcw.integer_rounding = rnd;
  sysv60(0, 8, &tkcw);
  return oldrnd;
}



