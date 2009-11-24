

#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <float.h>
#include <ieeefp.h>
#include <stdlib.h>
#include <string.h>
#define _MAX_CHARS 512

static char *lcset = "0123456789abcdef";

static struct p {
	double pvalue, nvalue;
	int exp;
} powers[] = 
{ 
{ 1e32, 1e-32, 32},
{ 1e16, 1e-16, 16},
{ 1e8, 1e-8, 8},
{ 1e4, 1e-4, 4},
{ 1e2, 1e-2, 2},
{ 1e1, 1e-1, 1 },
{ 1e0, 1e-0, 0 }
};

#define _MAX_PREC 16

static char 
_DEFUN(nextdigit,(value),
double *value)
{
  double tmp;
  
  *value = modf (*value * 10, &tmp) ;
  return  lcset[(int)tmp];
}


static char *
_DEFUN(print_nan,(buffer, value, precision),
       char *buffer _AND
       double value _AND
       int precision)
{
  size_t  i;
  
  if (isnan(value))
    {
      strcpy(buffer, "nan");
      i = 3;
    
    }
  else 
    {
      strcpy(buffer, "infinity");
      i = 8;
    }

  while (i < precision) 
    {
      buffer[i++] = ' ';
    }
  buffer[i++] = 0;
  return buffer;
  
}

/* A convert info struct */
typedef struct 
{
  char *buffer ;		/* Destination of conversion */
  double value;			/* scratch Value to convert */
  double original_value;	/* saved Value to convert */
  int value_neg;		/* OUT: 1 if value initialiy neg */
  int abs_exp;			/* abs Decimal exponent of value */
  int abs_exp_sign;		/* + or - */
  int exp;			/* exp not sgned */
  int type;			/* fFeEgG used in printing before exp */

  int print_trailing_zeros;     /* Print 00's after a . */
  
  int null_idx;  /* Index of the null at the end */
  
/* These ones are read only */
  int decimal_places;		/* the number of digits to print after
				   the decimal */
  int max_digits;		/* total number of digits to print */
  int buffer_size;              /* Size of output buffer */
  
  /* Two sorts of dot ness.
     0  never ever print a dot
     1  print a dot if followed by a digit 
     2  always print a dot, even if no digit following
     */
  enum { dot_never, dot_sometimes, dot_always} dot; /* Print a decimal point, always */
  int dot_idx;			/* where the dot went, or would have gone */
} cvt_info_type;


void
_DEFUN(renormalize,(in),
       cvt_info_type *in)
{

  /* Make sure all numbers are less than 1 */

  while (in->value >= 1.0) 
  {
    in->value = in->value * 0.1;
    in->exp++;
  }

  /* Now we have only numbers between 0 and .9999.., and have adjusted
     exp to account for the shift */  

  if (in->exp >= 0)
  {
    in->abs_exp_sign = '+';
    in->abs_exp = in->exp;
  }
  else 
  {
    in->abs_exp_sign  = '-';
    in->abs_exp = -in->exp;
  }

}

/* This routine looks at original_value, and makes it between 0 and 1,
   modifying exp as it goes
 */

static void 
_DEFUN(normalize,(value, in),
       double value _AND
       cvt_info_type *in)
{
  int j;
  int texp;
  if (value != 0) 
  {
     texp = -1;

  
  if (value < 0.0) 
  {
    in->value_neg =1 ;
    value = - value;
  }
  else 
  {
    in->value_neg = 0;
  }

		
  /* Work out texponent & normalise value */

  /* If value > 1, then shrink it */
  if (value >= 1.0) 
  {
    for (j = 0; j < 6; j++) 
    {
      while (value >= powers[j].pvalue) 
      {
	value /= powers[j].pvalue;
	texp += powers[j].exp;
      }
    }
  }
  else if (value != 0.0) 
  {
    for (j = 0; j < 6; j++) 
    {
      while (value <= powers[j].nvalue) 
      {
	value *= powers[j].pvalue;
	texp -= powers[j].exp;
      }
    }
  }
   }
  
  else
  {
    texp = 0;
  }
  

  in->exp = texp;
  in->value = value;
  in->original_value = value;  
  renormalize(in);
  
}
int
_DEFUN(round,(in, start, now, ch),
       cvt_info_type *in _AND
       char *start _AND
       char *now _AND
       char ch)
{
  double rounder = 5.0;

  char *p;
  int ok = 0;

  now --;

  /* If the next digit to output would have been a '5' run back and */
  /* see if we can create a more rounded number. If we can then do it.
     If not (like when the number was 9.9 and the last char was
     another 9), then we'll have to modify the number and try again */
  if (ch < '5') 
   return 0;
  

  for (p = now;!ok && p >= start; p--) 
  {
    switch (*p) 
    {
    default:
      abort();
    case '.':
      break;
    case '9':
      rounder = rounder * 0.1;
      break;
    case '8':
    case '7':
    case '6':
    case '5':
    case '4':
    case '3':
    case '2':
    case '1':
    case '0':
      p = now;
      while (1) {
	  if (*p == '9') {
	      *p = '0';
	    }
	  else if (*p != '.') {
	      (*p)++;
	      return 0;
	    }
	  p--;
	}
    }

  }

  /* Getting here means that we couldn't round the number in place
     textually - there have been all nines.
     We'll have to add to it and try the conversion again
     eg
     .99999[9] can't be rounded in place, so add 
     .000005   to it giving:
     1.000004   we notice that the result is > 1 so add to exp and
     divide by 10
     .100004
     */

  in->original_value = in->value = in->original_value + rounder;
  normalize(in->original_value , in);
  return 1; 

  
}



void
_DEFUN(_cvte,(in),
       register  cvt_info_type *in)
{
  int buffer_idx  =0;
  int digit = 0;
  
  int after_decimal =0;

  in->buffer[buffer_idx++] = nextdigit(&(in->value));
  digit++;
  in->dot_idx = buffer_idx;

  
  switch (in->dot) 
  {
  case dot_never:
    break;
  case dot_sometimes:
    if (in->decimal_places 
	&& digit < in->max_digits) 
    {
      in->buffer[buffer_idx++] = '.';
    }
    break;
  case dot_always: 
    in->buffer[buffer_idx++] = '.';    
  }

  
  while (buffer_idx < in->buffer_size
	 && after_decimal < in->decimal_places
	 && digit < in->max_digits)
  {
    in->buffer[buffer_idx] = nextdigit(&(in->value));
    after_decimal++;
    buffer_idx++;
    digit++;
    
  }

  if (round(in,
	    in->buffer,
	    in->buffer+buffer_idx,
	    nextdigit(&(in->value)))) 
  {
    _cvte(in);
  }
  else 
  {
    in->buffer[buffer_idx++] = in->type;			
    in->buffer[buffer_idx++] = in->abs_exp_sign;

    if (in->abs_exp >= 100) 
    {
      in->buffer[buffer_idx++] = lcset[in->abs_exp / 100];
      in->abs_exp %= 100;
    }
    in->buffer[buffer_idx++] = lcset[in->abs_exp / 10];
    in->buffer[buffer_idx++] = lcset[in->abs_exp % 10];
  }
  
  in->buffer[buffer_idx++] = 0;
}




/* Produce NNNN.FFFF */
void
_DEFUN(_cvtf,(in),
       cvt_info_type *in)
{
  
  int buffer_idx = 0;		/* Current char being output */
  int after_decimal = 0;
  int digit =0;

  
  in->dot_idx = in->exp + 1;
  
  /* Two sorts of number, NNN.FFF and 0.0000...FFFF */


  /* Print all the digits up to the decimal point */
  
  while (buffer_idx <= in->exp
	 && digit < in->max_digits
	 && buffer_idx < in->buffer_size)
  {
    in->buffer[buffer_idx]  = nextdigit(&(in->value));
    buffer_idx++;
    digit ++;
  }


  /* And the decimal point if we should */
  if (buffer_idx < in->buffer_size) 
  {
    
    switch (in->dot) 
    {
    case dot_never:
      break;
    case dot_sometimes:
      /* Only print a dot if following chars */
      if (in->decimal_places
	  && digit < in->max_digits )
      {
       in->buffer[buffer_idx++] = '.';     
     }
      
      break;
    case dot_always:
      in->buffer[buffer_idx++] = '.';
    }
  
    after_decimal = 0;

    /* And the digits following the point if necessary */

    /* Only print the leading zeros if a dot was possible */
    if (in->dot || in->exp>0) 
    {
     while (buffer_idx < in->buffer_size
	    && (in->abs_exp_sign == '-' && digit < in->abs_exp - 1)
	    && (after_decimal < in->decimal_places)
	    && (digit < in->max_digits))
     {
       in->buffer[buffer_idx] = '0';
       buffer_idx++;
       digit++;
       after_decimal++;
     }
   }
    
    while (buffer_idx < in->buffer_size
	   && after_decimal < in->decimal_places
	   && digit < in->max_digits)
    {
      in->buffer[buffer_idx]  = nextdigit(&(in->value));
      buffer_idx++;
      digit++;
      after_decimal++;
    }
  }

  in->null_idx = buffer_idx;  
  in->buffer[buffer_idx] = 0;
  if (round(in, in->buffer, in->buffer+buffer_idx,
	    nextdigit(&(in->value)))) 
  {
      _cvtf(in);
  }
  


  
}



char *
_DEFUN(_dcvt,(buffer, invalue, precision, width, type, dot),
       char *buffer _AND
       double invalue _AND
       int precision _AND
       int width _AND
       char type _AND
       int dot)
{
  cvt_info_type in;



  in.buffer = buffer;
  in.buffer_size = 512;

  if (!finite(invalue))
  {
    return print_nan(buffer, invalue, precision);
  }    


  normalize(invalue, &in);
    
  in.type = type;
  in.dot = dot? dot_always: dot_sometimes;

  switch (type)
  {
  
  case 'g':
  case 'G':
    /* When formatting a g, the precision refers to the number of
       char positions *total*, this leads to various off by ones */	
  {
    /* A precision of 0 means 1 */
    if (precision == 0)
     precision = 1;
      
    /* A g turns into an e if there are more digits than the
       precision, or it's smaller than e-4 */
    if (in.exp >= precision || in.exp < -4) 
    {
      in.type = (type == 'g' ? 'e' : 'E');
      in.decimal_places = _MAX_CHARS;
      in.max_digits = precision;
      in.print_trailing_zeros = 1;
      _cvte(&in);
    }
    else 
    {
      /* G means total number of chars to print */
      in.decimal_places = _MAX_CHARS;
      in.max_digits = precision;
      in.type = (type == 'g' ? 'f' : 'F');
      in.print_trailing_zeros = 0;
      _cvtf(&in);

   if (!dot) {
       /* trim trailing zeros */
       int j = in.null_idx -1;
       while (j > 0 && in.buffer[j] == '0') 
       {
	 in.buffer[j] = 0;
	 j--;
       }
       /* Stamp on a . if not followed by zeros */
       if (j > 0 && buffer[j] == '.')
	in.buffer[j] = 0;
     }
    }
    
      
    break;
  case 'f':
  case 'F':
    in.decimal_places= precision;
    in.max_digits = _MAX_CHARS;
      in.print_trailing_zeros = 1;    
    _cvtf(&in);
    break;
  case 'e':
  case 'E':
      in.print_trailing_zeros = 1;
    in.decimal_places = precision;
    in.max_digits = _MAX_CHARS;
    _cvte(&in);
    break;
  }

  }


  return buffer;
}




char *
_DEFUN(fcvtbuf,(invalue,ndigit,decpt,sign, fcvt_buf),
       double invalue _AND 
       int ndigit _AND
       int *decpt _AND
       int *sign _AND
       char *fcvt_buf)
{
  cvt_info_type in;
  in.buffer = fcvt_buf;
  in.buffer_size = 512;
    
  if (!finite(invalue))
    {
      return print_nan(fcvt_buf, invalue, ndigit);
    }    

  normalize(invalue, &in);

  in.dot = dot_never;			/* Don't print a decimal point */
  in.max_digits = _MAX_CHARS;
  in.buffer_size = _MAX_CHARS;		/* Take as many as needed */
  in.decimal_places = ndigit;
  _cvtf(&in);
  *decpt = in.dot_idx;
  *sign = in.value_neg;
  return in.buffer;
}


char *
_DEFUN(ecvtbuf,(invalue,ndigit,decpt,sign, fcvt_buf),
       double invalue _AND 
       int ndigit _AND
       int *decpt _AND
       int *sign _AND
       char *fcvt_buf)
{
  cvt_info_type in;
  in.buffer = fcvt_buf;
    
  if (!finite(invalue))
    {
      return print_nan(fcvt_buf, invalue, ndigit);
    }    

  normalize(invalue, &in);


  in.dot = dot_never;			/* Don't print a decimal point */
/* We can work out how many digits go after the decimal point */

  in.buffer_size =_MAX_CHARS;
  in.decimal_places = _MAX_CHARS;
  in.max_digits = ndigit;		/* Take as many as told */
  _cvtf(&in);
  *decpt = in.dot_idx;
  *sign = in.value_neg;
  return in.buffer;
}



char *
_DEFUN(gcvt,(d,ndigit,buf),
   double d _AND
   int ndigit _AND
   char *buf)
{
  return _dcvt(buf, d, ndigit, 0, 'g', 1);
}
