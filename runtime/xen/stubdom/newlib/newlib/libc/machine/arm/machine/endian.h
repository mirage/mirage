/* ARM configuration file */

#ifndef _MACHINE_ENDIAN_H
# define _MACHINE_ENDIAN_H

#ifdef __ARMEB__
#define BYTE_ORDER BIG_ENDIAN
#else
#define BYTE_ORDER LITTLE_ENDIAN
#endif

#endif
