#ifndef _LINUX_IF_H
#define _LINUX_IF_H

#include <net/if.h>

#define IF_GET_IFACE	0x0001		/* for querying only */
#define IF_GET_PROTO	0x0002

/* For definitions see hdlc.h */
#define IF_IFACE_V35	0x1000		/* V.35 serial interface	*/
#define IF_IFACE_V24	0x1001		/* V.24 serial interface	*/
#define IF_IFACE_X21	0x1002		/* X.21 serial interface	*/
#define IF_IFACE_T1	0x1003		/* T1 telco serial interface	*/
#define IF_IFACE_E1	0x1004		/* E1 telco serial interface	*/
#define IF_IFACE_SYNC_SERIAL 0x1005	/* can't be set by software	*/
#define IF_IFACE_X21D   0x1006          /* X.21 Dual Clocking (FarSite) */

/* For definitions see hdlc.h */
#define IF_PROTO_HDLC	0x2000		/* raw HDLC protocol		*/
#define IF_PROTO_PPP	0x2001		/* PPP protocol			*/
#define IF_PROTO_CISCO	0x2002		/* Cisco HDLC protocol		*/
#define IF_PROTO_FR	0x2003		/* Frame Relay protocol		*/
#define IF_PROTO_FR_ADD_PVC 0x2004	/*    Create FR PVC		*/
#define IF_PROTO_FR_DEL_PVC 0x2005	/*    Delete FR PVC		*/
#define IF_PROTO_X25	0x2006		/* X.25				*/
#define IF_PROTO_HDLC_ETH 0x2007	/* raw HDLC, Ethernet emulation	*/
#define IF_PROTO_FR_ADD_ETH_PVC 0x2008	/*  Create FR Ethernet-bridged PVC */
#define IF_PROTO_FR_DEL_ETH_PVC 0x2009	/*  Delete FR Ethernet-bridged PVC */
#define IF_PROTO_FR_PVC	0x200A		/* for reading PVC status	*/
#define IF_PROTO_FR_ETH_PVC 0x200B
#define IF_PROTO_RAW    0x200C          /* RAW Socket                   */

#endif
