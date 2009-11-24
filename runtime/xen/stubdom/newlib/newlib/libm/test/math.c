/* 
  Test the library maths functions using trusted precomputed test
  vectors.

  These vectors were originally generated on a sun3 with a 68881 using
  80 bit precision, but ...

  Each function is called with a variety of interesting arguments.
  Note that many of the polynomials we use behave badly when the
  domain is stressed, so the numbers in the vectors depend on what is
  useful to test - eg sin(1e30) is pointless - the arg has to be
  reduced modulo pi, and after that there's no bits of significance
  left to evaluate with - any number would be just as precise as any
  other.


*/

#include "test.h"
#include <math.h>
#include <ieeefp.h>
#include <float.h>
#include <math.h>
#include <errno.h>
#include <stdio.h>

int inacc;

int merror;
double mretval = 64;
int traperror = 1;
char *mname;

int verbose;

/* To test exceptions - we trap them all and return a known value */
int
_DEFUN(matherr,(e),
       struct exception *e)
{
  if (traperror) 
  {
    merror = e->type + 12;
    mname = e->name;
    e->retval = mretval;
    errno = merror + 24;
    return 1;
  }
  return 0;
}


void _DEFUN(translate_to,(file,r),
	    FILE *file _AND
	    double r)
{
  __ieee_double_shape_type bits;
  bits.value = r;
  fprintf(file, "0x%08x, 0x%08x", bits.parts.msw, bits.parts.lsw);
}

int 
_DEFUN(ffcheck,( is, p, name, serrno, merror),
       double is _AND
       one_line_type *p _AND
       char *name _AND
       int serrno _AND
       int merror)
{
  /* Make sure the answer isn't to far wrong from the correct value */
  __ieee_double_shape_type correct, isbits;
  int mag;  
  isbits.value = is;
  
  correct.parts.msw = p->qs[0].msw;
  correct.parts.lsw = p->qs[0].lsw;
  
  mag = mag_of_error(correct.value, is);
  
  if (mag < p->error_bit)
  {
    inacc ++;
    
    printf("%s:%d, inaccurate answer: bit %d (%08x%08x %08x%08x) (%g %g)\n",
	   name,  p->line, mag,
	   correct.parts.msw,
	   correct.parts.lsw,
	   isbits.parts.msw,
	   isbits.parts.lsw,
	   correct.value, is);
  }      
  
#if 0
  if (p->qs[0].merror != merror) 
  {
    printf("testing %s_vec.c:%d, matherr wrong: %d %d\n",
	   name, p->line, merror, p->qs[0].merror);
  }

  if (p->qs[0].errno_val != errno) 
  {
    printf("testing %s_vec.c:%d, errno wrong: %d %d\n",
	   name, p->line, errno, p->qs[0].errno_val);
    
  }
#endif
  return mag;
}

double
_DEFUN(thedouble, (msw, lsw),
       long msw _AND
       long lsw)
{
  __ieee_double_shape_type x;
  
  x.parts.msw = msw;
  x.parts.lsw = lsw;
  return x.value;
}

int calc;
int reduce;


_DEFUN(frontline,(f, mag, p, result, merror, errno, args, name),
       FILE *f _AND
       int mag _AND
       one_line_type *p _AND
       double result _AND
       int merror _AND
       int errno _AND
       char *args _AND
       char *name)
{
  if (reduce && p->error_bit < mag) 
  {
    fprintf(f, "{%2d,", p->error_bit);
  }
  else 
  {
    fprintf(f, "{%2d,",mag);
  }


  fprintf(f,"%2d,%3d,", merror,errno);
  fprintf(f, "__LINE__, ");

  if (calc) 
  {
    translate_to(f, result);
  }
  else 
  {
    translate_to(f, thedouble(p->qs[0].msw, p->qs[0].lsw));
  }
  
  fprintf(f, ", ");      

  fprintf(f,"0x%08x, 0x%08x", p->qs[1].msw, p->qs[1].lsw);
  

  if (args[2]) 
  {
    fprintf(f, ", ");      
    fprintf(f,"0x%08x, 0x%08x", p->qs[2].msw, p->qs[2].lsw);
  }
	
  fprintf(f,"},	/* %g=f(%g",result,
  	  thedouble(p->qs[1].msw, p->qs[1].lsw));

  if (args[2])
  {
    fprintf(f,", %g", thedouble(p->qs[2].msw,p->qs[2].lsw));
  }
  fprintf(f, ")*/\n");      
}

_DEFUN(finish,(f, vector,  result , p, args, name),
       FILE *f _AND
       int vector _AND
       double result _AND
       one_line_type *p _AND
       char *args _AND
       char *name)
{
  int mag;

  mag = ffcheck(result, p,name,  merror, errno);    
  if (vector) 
  {    
    frontline(f, mag, p, result, merror, errno, args , name);
  }
} 
int redo;  

_DEFUN(run_vector_1,(vector, p, func, name, args),
       int vector _AND
       one_line_type *p _AND
       char *func _AND
       char *name _AND
       char *args)
{
  FILE *f;
  int mag;
  double result;  
  
  if (vector)
  {

    VECOPEN(name, f);

    if (redo)
    {
      double k;

      for (k = -.2; k < .2; k+= 0.00132) 
      {

	fprintf(f,"{1,1, 1,1, 0,0,0x%08x,0x%08x, 0x%08x, 0x%08x},\n",
		k,k+4);

      }

      for (k = -1.2; k < 1.2; k+= 0.01) 
      {

	fprintf(f,"{1,1, 1,1, 0,0,0x%08x,0x%08x, 0x%08x, 0x%08x},\n",
		k,k+4);

      }
      for (k = -M_PI *2; k < M_PI *2; k+= M_PI/2) 
      {

	fprintf(f,"{1,1, 1,1, 0,0,0x%08x,0x%08x, 0x%08x, 0x%08x},\n",
		k,k+4);

      }

      for (k = -30; k < 30; k+= 1.7) 
      {

	fprintf(f,"{2,2, 1,1, 0,0, 0x%08x,0x%08x, 0x%08x, 0x%08x},\n",
		k,k+4);

      }
      VECCLOSE(f, name, args);
      return;
    }
  }
 
  newfunc(name);
  while (p->line) 
  {
    double arg1 = thedouble(p->qs[1].msw, p->qs[1].lsw);
    double arg2 = thedouble(p->qs[2].msw, p->qs[2].lsw);

    double r;
    double rf;
    
    errno = 0;
    merror = 0;
    mname = 0;

    
    line(p->line);          

    merror = 0;
    errno = 123;

    if (strcmp(args,"dd")==0)
    {
      typedef double _EXFUN((*pdblfunc),(double));
      
      /* Double function returning a double */
      
      result = ((pdblfunc)(func))(arg1);
      
      finish(f,vector, result, p, args, name);       
    }  
    else  if (strcmp(args,"ff")==0)
    {
      float arga;
      double a;
      
      typedef float _EXFUN((*pdblfunc),(float));
      
      /* Double function returning a double */
      
      if (arg1 < FLT_MAX )
      {
	arga = arg1;      
	result = ((pdblfunc)(func))(arga);
	finish(f, vector, result, p,args, name);       
      }
    }      
    else if (strcmp(args,"ddd")==0)
     {
       typedef double _EXFUN((*pdblfunc),(double,double));
      
       result = ((pdblfunc)(func))(arg1,arg2);
       finish(f, vector, result, p,args, name);       
     }  
     else  if (strcmp(args,"fff")==0)
     {
       double a,b;
       
       float arga;
       float argb;
      
       typedef float _EXFUN((*pdblfunc),(float,float));
      

       if (arg1 < FLT_MAX && arg2 < FLT_MAX) 
       {
	 arga = arg1;      
	 argb = arg2;
	 result = ((pdblfunc)(func))(arga, argb);
	 finish(f, vector, result, p,args, name);       
       }
     }      
     else if (strcmp(args,"did")==0)
     {
       typedef double _EXFUN((*pdblfunc),(int,double));
      
       result = ((pdblfunc)(func))((int)arg1,arg2);
       finish(f, vector, result, p,args, name);       
     }  
     else  if (strcmp(args,"fif")==0)
     {
       double a,b;
       
       float arga;
       float argb;
      
       typedef float _EXFUN((*pdblfunc),(int,float));
      

       if (arg1 < FLT_MAX && arg2 < FLT_MAX) 
       {
	 arga = arg1;      
	 argb = arg2;
	 result = ((pdblfunc)(func))((int)arga, argb);
	 finish(f, vector, result, p,args, name);       
       }
     }      

    p++;
  }
  if (vector)
  {
    VECCLOSE(f, name, args);
  }
}

void
_DEFUN_VOID(test_math)
{
  test_acos(0);
  test_acosf(0);
  test_acosh(0);
  test_acoshf(0);
  test_asin(0);
  test_asinf(0);
  test_asinh(0);
  test_asinhf(0);
  test_atan(0);
  test_atan2(0);
  test_atan2f(0);
  test_atanf(0);
  test_atanh(0);
  test_atanhf(0);
  test_ceil(0);
  test_ceilf(0);
  test_cos(0);
  test_cosf(0);
  test_cosh(0);
  test_coshf(0);
  test_erf(0);
  test_erfc(0);
  test_erfcf(0);
  test_erff(0);
  test_exp(0);
  test_expf(0);
  test_fabs(0);
  test_fabsf(0);
  test_floor(0);
  test_floorf(0);
  test_fmod(0);
  test_fmodf(0);
  test_gamma(0);
  test_gammaf(0);
  test_hypot(0);
  test_hypotf(0);
  test_j0(0);
  test_j0f(0);
  test_j1(0);
  test_j1f(0);
  test_jn(0);
  test_jnf(0);
  test_log(0);
  test_log10(0);
  test_log10f(0);
  test_log1p(0);
  test_log1pf(0);
  test_log2(0);
  test_log2f(0);
  test_logf(0);
  test_sin(0);
  test_sinf(0);
  test_sinh(0);
  test_sinhf(0);
  test_sqrt(0);
  test_sqrtf(0);
  test_tan(0);
  test_tanf(0);
  test_tanh(0);
  test_tanhf(0);
  test_y0(0);
  test_y0f(0);
  test_y1(0);
  test_y1f(0);
  test_y1f(0);
  test_ynf(0);
}

/* These have to be played with to get to compile on machines which
   don't have the fancy <foo>f entry points
*/

#if 0
float _DEFUN(cosf,(a), float a) { return cos((double)a); }
float _DEFUN(sinf,(a), float  a) { return sin((double)a); }
float _DEFUN(log1pf,(a), float a) { return log1p((double)a); }
float _DEFUN(tanf,(a), float a) { return tan((double)a); }
float _DEFUN(ceilf,(a), float a) { return ceil(a); }
float _DEFUN(floorf,(a), float a) { return floor(a); }
#endif

/*ndef HAVE_FLOAT*/
#if 0

float fmodf(a,b) float a,b; { return fmod(a,b); }
float hypotf(a,b) float a,b; { return hypot(a,b); }
  
float acosf(a) float a; { return acos(a); }
float acoshf(a) float a; { return acosh(a); }
float asinf(a) float a; { return asin(a); }
float asinhf(a) float a; { return asinh(a); }
float atanf(a) float a; { return atan(a); }
float atanhf(a) float a; { return atanh(a); }

float coshf(a) float a; { return cosh(a); }
float erff(a) float a; { return erf(a); }
float erfcf(a) float a; { return erfc(a); }
float expf(a) float a; { return exp(a); }
float fabsf(a) float a; { return fabs(a); }

float gammaf(a) float a; { return gamma(a); }
float j0f(a) float a; { return j0(a); }
float j1f(a) float a; { return j1(a); }
float log10f(a) float a; { return log10(a); }

float logf(a) float a; { return log(a); }

float sinhf(a) float a; { return sinh(a); }
float sqrtf(a) float a; { return sqrt(a); }

float tanhf(a) float a; { return tanh(a); }
float y0f(a) float a; { return y0(a); }
float y1f(a) float a; { return y1(a); }
#endif
