#define HAVE_FLOAT 1
#define X(x) (char *)x

#include <_ansi.h>
#include <math.h>
#include <float.h>
#include <ieeefp.h>
#include <stdio.h>

void checkf();
void enter();


double translate_from();

typedef struct 
{
  long msw, lsw;
} question_struct_type;


typedef struct 
{
  char error_bit;
  char errno_val;
  char merror;
  int line;
  
  question_struct_type qs[3];
} one_line_type;


#define MVEC_START(x) one_line_type x[] =  {
#define MVEC_END    0,};


int _EXFUN(mag_of_error,(double, double));


#define ERROR_PERFECT 20
#define ERROR_FAIL -1

#define AAAA 15
#define AAA 10
#define AA  6
#define A   5
#define B   3
#define C   1 
#define VECOPEN(x,f) \
{\
  char buffer[100];\
   sprintf(buffer,"%s_vec.c",x);\
    f = fopen(buffer,"w");\
     fprintf(f,"#include \"test.h\"\n");\
      fprintf(f," one_line_type %s_vec[] = {\n", x);\
}

#define VECCLOSE(f,name,args)\
{\
  fprintf(f,"0,};\n");      \
   fprintf(f,"test_%s(m)   {run_vector_1(m,%s_vec,(char *)(%s),\"%s\",\"%s\");   }	\n",\
	   name,\
	   name,name,name,args);\
	    fclose(f);\
}



typedef struct 
{
  int line;
  
  char *string;
  double value;
  int endscan;
} double_type;


typedef struct {
  long int value;
  char end;
  char errno_val;
} int_scan_type;

typedef struct 
{
  int line;
  int_scan_type octal;
  int_scan_type decimal;
  int_scan_type hex;
  int_scan_type normal;
  int_scan_type alphabetical;
  char *string;
} int_type;


typedef struct 
{
  int line;
  double value;
  char *estring;
  int e1;
  int e2;
  int e3;
  char *fstring;
  int f1;
  int f2;
  int f3;
  char *gstring;
  int g1;
} ddouble_type;

typedef struct
{
  int line;
  double value;
  char *result;
  char *format_string;
} sprint_double_type;


typedef struct
{
  int line;
  int value;
  char *result;
  char *format_string;
} sprint_int_type;


void _EXFUN(test_ieee,(void));
void _EXFUN(test_math2,(void));
void _EXFUN(test_math,(void));
void _EXFUN(test_string,(void));
void _EXFUN(test_is,(void));
void _EXFUN(test_cvt,(void));

void _EXFUN(line,(int));

void _EXFUN(test_mok, (double, double, int));
void _EXFUN(test_iok, (int, int));
void _EXFUN(test_eok, (int, int));
void _EXFUN(test_sok, (char *, char*));
void _EXFUN(test_scok, (char *, char*, int));
void _EXFUN(newfunc,(_CONST char *));
