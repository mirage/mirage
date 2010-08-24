#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

ssize_t __write1 ( const char* s ) __attribute__ (( __regparm__(1) ));
ssize_t __write2 ( const char* s ) __attribute__ (( __regparm__(1) ));

__END_DECLS
