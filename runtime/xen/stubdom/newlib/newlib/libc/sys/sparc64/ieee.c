
#include <ieeefp.h>


fp_rnd
_DEFUN_VOID(fpgetround)
{
  char *out;
  ieee_flags("get", "direction","", &out);
  if (strcmp(out,"nearest") == 0) return FP_RN;  
  if (strcmp(out,"negative") == 0) return FP_RM;  
  if (strcmp(out,"positive") == 0) return FP_RP;  
  if (strcmp(out,"tozero") == 0) return FP_RZ;  
  abort();
  
}

fp_rnd
_DEFUN(fpsetround,(new),
       fp_rnd new)
{
  fp_rnd old = fpgetround();
  char *dummy;
  
  switch (new) 
  {
  case FP_RN:
    ieee_flags("set", "direction", "nearest", &dummy);
    break;
  case FP_RM:
    ieee_flags("set", "direction", "negative", &dummy);
    break;
  case FP_RP:
    ieee_flags("set", "direction", "positive", &dummy);
    break;
  case FP_RZ:
    ieee_flags("set", "direction", "tozero", &dummy);
    break;
  default:
    break;
  }
  return old;
}


fp_except
_DEFUN_VOID(fpgetmask)
{
  char *out;
  int r = 0;

  int i = ieee_flags("get","exception","",&out);  
  if (i & 1) r |= FP_X_IMP;
  if (i & 2) r |= FP_X_DX;
  if (i & 4) r |= FP_X_UFL;
  if (i & 8) r |= FP_X_OFL;
  if (i & 16) r |= FP_X_INV;
  return r;

}

fp_except
_DEFUN(fpsetmask,(mask),
       fp_except mask)
{
  fp_except old = fpgetmask();  

  char *out;
  ieee_flags("clear","exception", "all", &out);


  if (mask & FP_X_IMP) 
   ieee_flags("set","exception","inexact", &out);
  if (mask  & FP_X_DX)
   ieee_flags("set","exception","division", &out);
  if (mask & FP_X_UFL)
   ieee_flags("set","exception","underflow", &out);
  if (mask & FP_X_OFL)
   ieee_flags("set","exception","overflow", &out);
  if (mask & FP_X_INV)
   ieee_flags("set","exception","invalid", &out);

  return old;

}

fp_except 
_DEFUN(fpsetsticky,(mask),
       fp_except mask)
{
  return fpsetmask(mask);
}

fp_except
_DEFUN_VOID(fpgetsticky)
{
  return fpgetmask();
}

int
_DEFUN(fpsetroundtoi,(rdi_mode),
       fp_rdi rdi_mode)
{
  
  return 0;
  
}

int 
_DEFUN_VOID(fpgetroundtoi)
{
  
  return 0;
  
}
