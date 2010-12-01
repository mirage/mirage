#ifndef _FENV_H
#define _FENV_H

#include <sys/cdefs.h>

__BEGIN_DECLS

#if defined(__i386__)

enum
  {
    FE_INVALID = 0x01,
#define FE_INVALID      FE_INVALID
    __FE_DENORM = 0x02,
    FE_DIVBYZERO = 0x04,
#define FE_DIVBYZERO    FE_DIVBYZERO
    FE_OVERFLOW = 0x08,
#define FE_OVERFLOW     FE_OVERFLOW
    FE_UNDERFLOW = 0x10,
#define FE_UNDERFLOW    FE_UNDERFLOW
    FE_INEXACT = 0x20
#define FE_INEXACT      FE_INEXACT
  };

#define FE_ALL_EXCEPT \
        (FE_INEXACT | FE_DIVBYZERO | FE_UNDERFLOW | FE_OVERFLOW | FE_INVALID)

enum
  {
    FE_TONEAREST = 0,
#define FE_TONEAREST    FE_TONEAREST
    FE_DOWNWARD = 0x400,
#define FE_DOWNWARD     FE_DOWNWARD
    FE_UPWARD = 0x800,
#define FE_UPWARD       FE_UPWARD
    FE_TOWARDZERO = 0xc00
#define FE_TOWARDZERO   FE_TOWARDZERO
  };

#define FE_DFL_ENV      ((__const fenv_t *) -1)

/* Type representing exception flags.  */
typedef unsigned short int fexcept_t;

/* Type representing floating-point environment.  This function corresponds
   to the layout of the block written by the `fstenv'.  */
typedef struct {
  unsigned short int __control_word;
  unsigned short int __unused1;
  unsigned short int __status_word;
  unsigned short int __unused2;
  unsigned short int __tags;
  unsigned short int __unused3;
  unsigned int __eip;
  unsigned short int __cs_selector;
  unsigned int __opcode:11;
  unsigned int __unused4:5;
  unsigned int __data_offset;
  unsigned short int __data_selector;
  unsigned short int __unused5;
} fenv_t;

#elif defined(__ia64__)

enum
  {
    FE_INEXACT =        1UL << 5,
#define FE_INEXACT      FE_INEXACT

    FE_UNDERFLOW =      1UL << 4,
#define FE_UNDERFLOW    FE_UNDERFLOW

    FE_OVERFLOW =       1UL << 3,
#define FE_OVERFLOW     FE_OVERFLOW

    FE_DIVBYZERO =      1UL << 2,
#define FE_DIVBYZERO    FE_DIVBYZERO

    FE_UNNORMAL =       1UL << 1,
#define FE_UNNORMAL     FE_UNNORMAL

    FE_INVALID =        1UL << 0,
#define FE_INVALID      FE_INVALID

    FE_ALL_EXCEPT =
        (FE_INEXACT | FE_UNDERFLOW | FE_OVERFLOW | FE_DIVBYZERO | FE_UNNORMAL | FE_INVALID)
#define FE_ALL_EXCEPT   FE_ALL_EXCEPT
  };

enum
  {
    FE_TOWARDZERO =     3,
#define FE_TOWARDZERO   FE_TOWARDZERO

    FE_UPWARD =         2,
#define FE_UPWARD       FE_UPWARD

    FE_DOWNWARD =       1,
#define FE_DOWNWARD     FE_DOWNWARD

    FE_TONEAREST =      0,
#define FE_TONEAREST    FE_TONEAREST
  };

#define FE_DFL_ENV      ((__const fenv_t *) 0xc009804c0270033fUL)

typedef unsigned long int fexcept_t;
typedef unsigned long int fenv_t;

#elif defined(__powerpc__)

enum
  {
    FE_INEXACT = 1 << (31 - 6),
#define FE_INEXACT      FE_INEXACT
    FE_DIVBYZERO = 1 << (31 - 5),
#define FE_DIVBYZERO    FE_DIVBYZERO
    FE_UNDERFLOW = 1 << (31 - 4),
#define FE_UNDERFLOW    FE_UNDERFLOW
    FE_OVERFLOW = 1 << (31 - 3),
#define FE_OVERFLOW     FE_OVERFLOW

    /* ... except for FE_INVALID, for which we use bit 31. FE_INVALID
       actually corresponds to bits 7 through 12 and 21 through 23
       in the FPSCR, but we can't use that because the current draft
       says that it must be a power of 2.  Instead we use bit 2 which
       is the summary bit for all the FE_INVALID exceptions, which
       kind of makes sense.  */
    FE_INVALID = 1 << (31 - 2),
#define FE_INVALID      FE_INVALID
  };

#define FE_ALL_EXCEPT \
        (FE_INEXACT | FE_DIVBYZERO | FE_UNDERFLOW | FE_OVERFLOW | FE_INVALID)

enum
  {
    FE_TONEAREST = 0,
#define FE_TONEAREST    FE_TONEAREST
    FE_TOWARDZERO = 1,
#define FE_TOWARDZERO   FE_TOWARDZERO
    FE_UPWARD = 2,
#define FE_UPWARD       FE_UPWARD
    FE_DOWNWARD = 3
#define FE_DOWNWARD     FE_DOWNWARD
  };

typedef unsigned int fexcept_t;
typedef double fenv_t;
extern const fenv_t __fe_dfl_env;
#define FE_DFL_ENV      (&__fe_dfl_env)

#elif defined(__s390__)

enum
  {
    FE_INVALID = 0x80,
#define FE_INVALID      FE_INVALID
    FE_DIVBYZERO = 0x40,
#define FE_DIVBYZERO    FE_DIVBYZERO
    FE_OVERFLOW = 0x20,
#define FE_OVERFLOW     FE_OVERFLOW
    FE_UNDERFLOW = 0x10,
#define FE_UNDERFLOW    FE_UNDERFLOW
    FE_INEXACT = 0x08
#define FE_INEXACT      FE_INEXACT
  };

#define FE_ALL_EXCEPT \
        (FE_INEXACT | FE_DIVBYZERO | FE_UNDERFLOW | FE_OVERFLOW | FE_INVALID)

enum
  {
    FE_TONEAREST = 0,
#define FE_TONEAREST    FE_TONEAREST
    FE_DOWNWARD = 0x3,
#define FE_DOWNWARD     FE_DOWNWARD
    FE_UPWARD = 0x2,
#define FE_UPWARD       FE_UPWARD
    FE_TOWARDZERO = 0x1
#define FE_TOWARDZERO   FE_TOWARDZERO
  };

#define FE_DFL_ENV      ((__const fenv_t *) -1)

typedef unsigned int fexcept_t; /* size of fpc */
typedef struct
{
  fexcept_t fpc;
  void *ieee_instruction_pointer;
  /* failing instruction for ieee exceptions */
} fenv_t;

#elif defined(__sparc__)

enum
  {    
    FE_INVALID =        (1 << 9),
#define FE_INVALID      FE_INVALID
    FE_OVERFLOW =       (1 << 8),
#define FE_OVERFLOW     FE_OVERFLOW
    FE_UNDERFLOW =      (1 << 7),
#define FE_UNDERFLOW    FE_UNDERFLOW
    FE_DIVBYZERO =      (1 << 6),
#define FE_DIVBYZERO    FE_DIVBYZERO
    FE_INEXACT =        (1 << 5)
#define FE_INEXACT      FE_INEXACT
  };

#define FE_ALL_EXCEPT \
        (FE_INEXACT | FE_DIVBYZERO | FE_UNDERFLOW | FE_OVERFLOW | FE_INVALID)

enum
  {      
    FE_TONEAREST =      (0U << 30),
#define FE_TONEAREST    FE_TONEAREST
    FE_TOWARDZERO =     (1U << 30),
#define FE_TOWARDZERO   FE_TOWARDZERO
    FE_UPWARD =         (2U << 30),
#define FE_UPWARD       FE_UPWARD
    FE_DOWNWARD =       (3U << 30)
#define FE_DOWNWARD     FE_DOWNWARD
  };

#define __FE_ROUND_MASK (3U << 30)
#define FE_DFL_ENV      ((__const fenv_t *) -1)

typedef unsigned long int fexcept_t;
typedef unsigned long int fenv_t;

#elif defined(__x86_64__)

enum
  {    
    FE_INVALID = 0x01,  
#define FE_INVALID      FE_INVALID
    __FE_DENORM = 0x02,
    FE_DIVBYZERO = 0x04,
#define FE_DIVBYZERO    FE_DIVBYZERO
    FE_OVERFLOW = 0x08,
#define FE_OVERFLOW     FE_OVERFLOW
    FE_UNDERFLOW = 0x10,
#define FE_UNDERFLOW    FE_UNDERFLOW
    FE_INEXACT = 0x20
#define FE_INEXACT      FE_INEXACT
  };

#define FE_ALL_EXCEPT \
        (FE_INEXACT | FE_DIVBYZERO | FE_UNDERFLOW | FE_OVERFLOW | FE_INVALID)

enum
  { 
    FE_TONEAREST = 0,
#define FE_TONEAREST    FE_TONEAREST
    FE_DOWNWARD = 0x400,
#define FE_DOWNWARD     FE_DOWNWARD
    FE_UPWARD = 0x800,
#define FE_UPWARD       FE_UPWARD
    FE_TOWARDZERO = 0xc00
#define FE_TOWARDZERO   FE_TOWARDZERO
  };

#define FE_DFL_ENV      ((__const fenv_t *) -1)

typedef unsigned short int fexcept_t;

typedef struct {
  unsigned short int __control_word;
  unsigned short int __unused1;
  unsigned short int __status_word;
  unsigned short int __unused2;
  unsigned short int __tags;
  unsigned short int __unused3;
  unsigned int __eip;
  unsigned short int __cs_selector;
  unsigned int __opcode:11;
  unsigned int __unused4:5;
  unsigned int __data_offset;
  unsigned short int __data_selector;
  unsigned short int __unused5;
  unsigned int __mxcsr;
} fenv_t;

#else

#error unsupported platform, edit include/fenv.h
#endif

int  feclearexcept(int);
int  fegetexceptflag(fexcept_t *, int);
int  feraiseexcept(int);
int  fesetexceptflag(const fexcept_t *, int);
int  fetestexcept(int);
int  fegetround(void);
int  fesetround(int);
int  fegetenv(fenv_t *);
int  feholdexcept(fenv_t *);
int  fesetenv(const fenv_t *);
int  feupdateenv(const fenv_t *);

__END_DECLS

#endif
