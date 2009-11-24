
#include "test.h"
#include <errno.h>


int
_DEFUN_VOID(randi)
{
  static int next;
  next = (next * 1103515245) + 12345;
  return ((next >> 16) & 0xffff);
}

double _DEFUN_VOID(randx)
{
  double res;
  
  do 
  {
    union {
	short parts[4];
	double res;
      } u;
    
    u.parts[0] = randi();
    u.parts[1] = randi();
    u.parts[2] = randi();
    u.parts[3] = randi();
    res = u.res;
    
  } while (!finite(res));
  
  return res ;
}

/* Return a random double, but bias for numbers closer to 0 */
double _DEFUN_VOID(randy)
{
  int pow;
  double r= randx();
  r = frexp(r, &pow);
  return ldexp(r, randi() & 0x1f);
}

void
_DEFUN_VOID(test_frexp)
{
  int i;
  double r;
  int t;
  
  float xf;  
  double gives;

  int pow;

  
  /* Frexp of x return a and n, where a * 2**n == x, so test this with a
     set of random numbers */
  for (t = 0; t < 2; t++)   
  {
    for (i = 0; i < 1000; i++)  
    {
      
      double x = randx();   
      line(i);   
      switch (t) 
      {
      case 0:
	newfunc("frexp/ldexp");
	r = frexp(x, &pow);
	if (r > 1.0 || r < -1.0) 
	{ 
	  /* Answer can never be > 1 or < 1 */
	  test_iok(0,1);
	}
	
	gives = ldexp(r ,pow);
	test_mok(gives,x,62);
	break;
      case 1:
	newfunc("frexpf/ldexpf");
	if (x > FLT_MIN && x < FLT_MAX)
	{
	  /* test floats too, but they have a smaller range so make sure x
	     isn't too big. Also x can get smaller than a float can
	     represent to make sure that doesn't happen too */
	  xf = x;
	  r = frexpf(xf, &pow);
	  if (r > 1.0 || r < -1.0) 
	  { 
	    /* Answer can never be > 1 or < -1 */
	    test_iok(0,1);
	  }

	  gives = ldexpf(r ,pow);
	  test_mok(gives,x, 32);
	  
	}
      }

    }
    
  }
  
  /* test a few numbers manually to make sure frexp/ldexp are not
     testing as ok because both are broken */

  r = frexp(64.0, &i);
  
  test_mok(r, 0.5,64);
  test_iok(i, 7);

  r = frexp(96.0, &i);
  
  test_mok(r, 0.75, 64);
  test_iok(i, 7);
  
}

/* Test mod - this is given a real hammering by the strtod type
   routines, here are some more tests.

   By definition

   modf = func(value, &iptr)

      (*iptr + modf) == value

   we test this

*/
void
_DEFUN_VOID(test_mod)
{
  int i;
  
  newfunc("modf");

  
  for (i = 0; i < 1000; i++) 
  {
    double intpart;
    double n;
    line(i);
    n  = randx();
    if (finite(n) && n != 0.0 )
    {
      double r = modf(n, &intpart);
      line(i);
      test_mok(intpart + r, n, 63);
    }
    
  }
  newfunc("modff");
  
  for (i = 0; i < 1000; i++) 
  {
    float intpart;
    double nd;
    line(i);
    nd  = randx() ;
    if (nd < FLT_MAX && finitef(nd) && nd != 0.0)
    {
      float n = nd;
      double r = modff(n, &intpart);
      line(i);
      test_mok(intpart + r, n, 32);
    }
  }


}

/*
Test pow by multiplying logs  
*/
void
_DEFUN_VOID(test_pow)
{
  unsigned int i;  
  newfunc("pow");

  for (i = 0; i < 1000; i++) 
  {
    double n1;
    double n2;
    double res;
    double shouldbe;

    line(i);  
    n1 = fabs(randy());
    n2 = fabs(randy()/100.0);
    res = pow(n1, n2);
    shouldbe = exp(log(n1) * n2);
    test_mok(shouldbe, res,64);
  }

  newfunc("powf");
  
  for (i = 0; i < 1000; i++) 
  {
    double n1;
    double n2;
    double res;
    double shouldbe;

    errno = 0;
    
    line(i);  
    n1 = fabs(randy());
    n2 = fabs(randy()/100.0);
    res = powf(n1, n2);
    shouldbe = expf(logf(n1) * n2);
    if (!errno)
     test_mok(shouldbe, res,28);
  }




}



void
_DEFUN_VOID(test_math2)
{
  test_mod();  
  test_frexp();
  test_pow();
}
