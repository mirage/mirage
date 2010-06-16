/* 
 * lwip-net.c
 *
 * interface between lwIP's ethernet and Mirage's netfront.
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 * based on lwIP's ethernetif.c skeleton file, copyrights as below.
 *
 * adapted for Mirage by Anil Madhavapeddy <anil@recoil.org>, June 2010
 */


/*
 * Copyright (c) 2001-2004 Swedish Institute of Computer Science.
 * All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 * OF SUCH DAMAGE.
 *
 * This file is part of the lwIP TCP/IP stack.
 * 
 * Author: Adam Dunkels <adam@sics.se>
 *
 */

#include <os.h>
#include <semaphore.h>

#include <lwip/stats.h>
#include <lwip/sys.h>
#include <lwip/mem.h>
#include <lwip/memp.h>
#include <lwip/pbuf.h>
#include <netif/etharp.h>
#include <lwip/tcpip.h>
#include <lwip/tcp.h>
#include <lwip/netif.h>

#include <netfront.h>

/* Define those to better describe your network interface. */
#define IFNAME0 'e'
#define IFNAME1 'n'

/* Only have one network interface at a time. */
static struct netif *the_interface = NULL;

static struct netfront_dev *dev;

/* Forward declarations. */
static err_t netfront_output(struct netif *netif, struct pbuf *p,
             struct ip_addr *ipaddr);

/*
 * low_level_output():
 *
 * Should do the actual transmission of the packet. The packet is
 * contained in the pbuf that is passed to the function. This pbuf
 * might be chained.
 *
 */

static err_t
low_level_output(struct netif *netif, struct pbuf *p)
{
  if (!dev)
    return ERR_OK;

  /* Send the data from the pbuf to the interface, one pbuf at a
     time. The size of the data in each pbuf is kept in the ->len
     variable. */
  if (!p->next) {
    /* Only one fragment, can send it directly */
      netfront_xmit(dev, p->payload, p->len);
  } else {
    unsigned char data[p->tot_len], *cur;
    struct pbuf *q;

    for(q = p, cur = data; q != NULL; cur += q->len, q = q->next)
      memcpy(cur, q->payload, q->len);
    netfront_xmit(dev, data, p->tot_len);
  }

  LINK_STATS_INC(link.xmit);

  return ERR_OK;
}



/*
 * netfront_output():
 *
 * This function is called by the TCP/IP stack when an IP packet
 * should be sent. It calls the function called low_level_output() to
 * do the actual transmission of the packet.
 *
 */

static err_t
netfront_output(struct netif *netif, struct pbuf *p,
      struct ip_addr *ipaddr)
{
  
 /* resolve hardware address, then send (or queue) packet */
  return etharp_output(netif, p, ipaddr);
 
}

/*
 * netfront_input():
 *
 * This function should be called when a packet is ready to be read
 * from the interface. 
 *
 */

static void
netfront_input(struct netif *netif, unsigned char* data, int len)
{
  struct pbuf *p, *q;

  /* move received packet into a new pbuf */
  p = pbuf_alloc(PBUF_RAW, len, PBUF_POOL);
  if (p == NULL) {
    LINK_STATS_INC(link.memerr);
    LINK_STATS_INC(link.drop);
    return;
  }

  /* We iterate over the pbuf chain until we have read the entire
   * packet into the pbuf. */
  for(q = p; q != NULL && len > 0; q = q->next) {
    /* Read enough bytes to fill this pbuf in the chain. The
     * available data in the pbuf is given by the q->len
     * variable. */
    memcpy(q->payload, data, len < q->len ? len : q->len);
    data += q->len;
    len -= q->len;
  }

  LINK_STATS_INC(link.recv);

  ethernet_input(p, netif);
}


/* 
 * netif_rx(): overrides the default netif_rx behaviour in the netfront driver.
 * 
 * Pull received packets into a pbuf queue for the low_level_input() 
 * function to pass up to lwIP.
 */

void netif_rx(unsigned char* data, int len)
{
  if (the_interface != NULL) {
    netfront_input(the_interface, data, len);
    wake_up(&netfront_queue);
  }
  /* By returning, we ack the packet and relinquish the RX ring slot */
}

/*
 * netif_netfront_init():
 *
 * Should be called at the beginning of the program to set up the
 * network interface.
 *
 */

err_t
netif_netfront_init(struct netif *netif)
{
  unsigned char *mac = netif->state;

  netif->name[0] = IFNAME0;
  netif->name[1] = IFNAME1;
  netif->output = netfront_output;
  netif->linkoutput = low_level_output;
  
  the_interface = netif;
  
  /* set MAC hardware address */
  netif->hwaddr_len = 6;
  netif->hwaddr[0] = mac[0];
  netif->hwaddr[1] = mac[1];
  netif->hwaddr[2] = mac[2];
  netif->hwaddr[3] = mac[3];
  netif->hwaddr[4] = mac[4];
  netif->hwaddr[5] = mac[5];

  /* No interesting per-interface state */
  netif->state = NULL;

  /* maximum transfer unit */
  netif->mtu = 1500;
  
  /* broadcast capability */
  netif->flags = NETIF_FLAG_BROADCAST;

  etharp_init();

  return ERR_OK;
}

void start_networking(unsigned char rawmac[6])
{
  struct netif *netif;
  char *ip = NULL;

  printf("start_networking\n");

  dev = init_netfront(NULL, NULL, rawmac, NULL);
  
  netif = malloc(sizeof(struct netif));
  netif_netfront_init(netif);
}

/* Shut down the network */
void stop_networking(void)
{
  if (dev)
    shutdown_netfront(dev);
}
