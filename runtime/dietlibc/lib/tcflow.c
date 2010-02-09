#include "dietfeatures.h"
#include <errno.h>
#include <termios.h>
#include <sys/ioctl.h>

int  tcflow ( int fd, int action )
{
#if TCOOFF==0  &&  TCOON==1  &&  TCIOFF==2  &&  TCION==3

    if ( (unsigned int)action < 4u )
	return ioctl ( fd, TCXONC, action );

    errno = EINVAL;
    return -1;

#else

    int  arg = 0;
    
    switch (action) {
    case TCION: 
	arg++;
    case TCIOFF: 
	arg++;
    case TCOON:   
	arg++;
    case TCOOFF:
	return ioctl ( fd, TCXONC, arg );
    default:
        errno = EINVAL;
        return -1;
    }

#endif
}
