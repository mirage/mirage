#ifndef _LINUX_IF_TUN_H
#define _LINUX_IF_TUN_H

/* Read queue size */
#define TUN_READQ_SIZE	500

/* TUN device flags */
#define TUN_TUN_DEV 	0x0001
#define TUN_TAP_DEV	0x0002
#define TUN_TYPE_MASK	0x000f

#define TUN_FASYNC	0x0010
#define TUN_NOCHECKSUM	0x0020
#define TUN_NO_PI	0x0040
#define TUN_ONE_QUEUE	0x0080
#define TUN_PERSIST 	0x0100

/* Ioctl defines */
#define TUNSETNOCSUM	_IOW('T', 200, int)
#define TUNSETDEBUG	_IOW('T', 201, int)
#define TUNSETIFF	_IOW('T', 202, int)
#define TUNSETPERSIST	_IOW('T', 203, int)
#define TUNSETOWNER	_IOW('T', 204, int)
#define TUNSETLINK	_IOW('T', 205, int)

/* TUNSETIFF ifr flags */
#define IFF_TUN		0x0001
#define IFF_TAP		0x0002
#define IFF_NO_PI	0x1000
#define IFF_ONE_QUEUE	0x2000

struct tun_pi {
  unsigned short flags;
  unsigned short proto;
};
#define TUN_PKT_STRIP	0x0001

#endif
