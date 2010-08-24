#if defined(__i386__)
#include "i386/syscalls.h"

#elif defined(__x86_64__)
#include "x86_64/syscalls.h"

#elif defined(__sparc__)
#if defined(__arch64__)
#include "sparc64/syscalls.h"
#else
#include "sparc/syscalls.h"
#endif

#elif defined(__powerpc64__)
#include "ppc64/syscalls.h"

#elif defined(__powerpc__)
#include "ppc/syscalls.h"

#elif defined(__mips__)
#include "mips/syscalls.h"

#elif defined(__arm__)
#include "arm/syscalls.h"

#elif defined(__s390__)
#if defined(__s390x__)
#include "s390x/syscalls.h"
#else
#include "s390/syscalls.h"
#endif

#elif defined(__alpha__)
#include "alpha/syscalls.h"

#elif defined(__hppa__)
#include "parisc/syscalls.h"

#elif defined(__ia64__)
#include "ia64/syscalls.h"

#endif
