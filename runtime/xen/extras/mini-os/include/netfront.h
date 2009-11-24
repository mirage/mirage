#include <mini-os/wait.h>
#ifdef HAVE_LWIP
#include <lwip/netif.h>
#endif
struct netfront_dev;
struct netfront_dev *init_netfront(char *nodename, void (*netif_rx)(unsigned char *data, int len), unsigned char rawmac[6], char **ip);
void netfront_xmit(struct netfront_dev *dev, unsigned char* data,int len);
void shutdown_netfront(struct netfront_dev *dev);
#ifdef HAVE_LIBC
int netfront_tap_open(char *nodename);
ssize_t netfront_receive(struct netfront_dev *dev, unsigned char *data, size_t len);
#endif

extern struct wait_queue_head netfront_queue;

#ifdef HAVE_LWIP
/* Call this to bring up the netfront interface and the lwIP stack.
 * N.B. _must_ be called from a thread; it's not safe to call this from 
 * app_main(). */
void start_networking(void);
void stop_networking(void);

void networking_set_addr(struct ip_addr *ipaddr, struct ip_addr *netmask, struct ip_addr *gw);
#endif
