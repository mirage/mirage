#ifndef _BYTESWAP_H_
#define _BYTESWAP_H_

/* Unfortunately not provided by newlib.  */

#include <mini-os/types.h>
static inline uint16_t bswap_16(uint16_t x)
{
    return
    ((((x) & 0xff00) >> 8) | (((x) & 0xff) << 8));
}

static inline uint32_t bswap_32(uint32_t x)
{
    return
    ((((x) & 0xff000000) >> 24) | (((x) & 0x00ff0000) >>  8) |
     (((x) & 0x0000ff00) <<  8) | (((x) & 0x000000ff) << 24));
}

static inline uint64_t bswap_64(uint64_t x)
{
    return
    ((((x) & 0xff00000000000000ULL) >> 56) |
     (((x) & 0x00ff000000000000ULL) >> 40) |
     (((x) & 0x0000ff0000000000ULL) >> 24) |
     (((x) & 0x000000ff00000000ULL) >>  8) |
     (((x) & 0x00000000ff000000ULL) <<  8) |
     (((x) & 0x0000000000ff0000ULL) << 24) |
     (((x) & 0x000000000000ff00ULL) << 40) |
     (((x) & 0x00000000000000ffULL) << 56));
}

#endif /* _BYTESWAP_H */
