#ifndef _NETINET_UDP_H
#define _NETINET_UDP_H

#include <sys/cdefs.h>
#include <sys/types.h>

__BEGIN_DECLS

struct udphdr {		/* size 8     28/0x1c with IP header */
  uint16_t source;	/* offset 0   20/0x14 */
  uint16_t dest;	/* offset 2   22/0x16 */
  uint16_t len;		/* offset 4   24/0x18 */
  uint16_t check;	/* offset 6   26/0x1a */
};

#define SOL_UDP            17      /* sockopt level for UDP */

__END_DECLS

#endif
