#include <mini-os/wait.h>
struct netfront_dev;
struct netfront_dev *init_netfront(char *nodename, void (*netif_rx)(void *, unsigned char *data, int len), unsigned char rawmac[6], char **ip);
void netfront_xmit(struct netfront_dev *dev, unsigned char* data, int len);
void shutdown_netfront(struct netfront_dev *dev);
void set_netfront_state(struct netfront_dev *, void *);
void netif_rx(void *, unsigned char *, int);
