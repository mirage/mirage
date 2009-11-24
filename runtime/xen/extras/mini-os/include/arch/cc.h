/* 
 * lwip/arch/cc.h
 *
 * Compiler-specific types and macros for lwIP running on mini-os 
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 */

#ifndef __LWIP_ARCH_CC_H__
#define __LWIP_ARCH_CC_H__

/*   Typedefs for the types used by lwip - */
#include <mini-os/os.h>
#include <mini-os/types.h>
#include <time.h>
typedef uint8_t  u8_t;
typedef int8_t   s8_t;
typedef uint16_t u16_t;
typedef int16_t  s16_t;
typedef uint32_t u32_t;
typedef int32_t  s32_t;
typedef uint64_t u64_t;
typedef int64_t  s64_t;
typedef uintptr_t mem_ptr_t;

typedef uint16_t u_short;

/*   Compiler hints for packing lwip's structures - */
#define PACK_STRUCT_FIELD(_x)  _x
#define PACK_STRUCT_STRUCT     __attribute__ ((packed))
#define PACK_STRUCT_BEGIN 
#define PACK_STRUCT_END

/*   Platform specific diagnostic output - */

extern void lwip_printk(char *fmt, ...);
#define LWIP_PLATFORM_DIAG(_x) do { lwip_printk _x ; } while (0)

extern void lwip_die(char *fmt, ...);
#define LWIP_PLATFORM_ASSERT(_x) do { lwip_die(_x); } while(0)

/*   "lightweight" synchronization mechanisms - */
/*     SYS_ARCH_DECL_PROTECT(x) - declare a protection state variable. */
/*     SYS_ARCH_PROTECT(x)      - enter protection mode. */
/*     SYS_ARCH_UNPROTECT(x)    - leave protection mode. */

/*   If the compiler does not provide memset() this file must include a */
/*   definition of it, or include a file which defines it. */
#include <mini-os/lib.h>

/*   This file must either include a system-local <errno.h> which defines */
/*   the standard *nix error codes, or it should #define LWIP_PROVIDE_ERRNO */
/*   to make lwip/arch.h define the codes which are used throughout. */
#include <errno.h>

/*   Not required by the docs, but needed for network-order calculations */
#ifdef HAVE_LIBC
#include <machine/endian.h>
#ifndef BIG_ENDIAN
#error endian.h does not define byte order
#endif
#else
#include <endian.h>
#endif

#include <inttypes.h>
#define S16_F PRIi16
#define U16_F PRIu16
#define X16_F PRIx16
#define S32_F PRIi32
#define U32_F PRIu32
#define X32_F PRIx32

#if 0
#ifndef DBG_ON
#define DBG_ON	LWIP_DBG_ON
#endif
#define LWIP_DEBUG	DBG_ON
//#define IP_DEBUG	DBG_ON
#define TCP_DEBUG	DBG_ON
#define TCP_INPUT_DEBUG	DBG_ON
#define TCP_QLEN_DEBUG	DBG_ON
#define TCPIP_DEBUG	DBG_ON
#define DBG_TYPES_ON	DBG_ON
#endif

#endif /* __LWIP_ARCH_CC_H__ */
