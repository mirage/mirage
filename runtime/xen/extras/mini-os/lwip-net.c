/* 
 * lwip-net.c
 *
 * interface between lwIP's ethernet and Mini-os's netfront.
 * For now, support only one network interface, as mini-os does.
 *
 * Tim Deegan <Tim.Deegan@eu.citrix.net>, July 2007
 * based on lwIP's ethernetif.c skeleton file, copyrights as below.
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

#include "lwip/opt.h"
#include "lwip/def.h"
#include "lwip/mem.h"
#include "lwip/pbuf.h"
#include "lwip/sys.h"

#include <lwip/stats.h>
#include <lwip/sys.h>
#include <lwip/mem.h>
#include <lwip/memp.h>
#include <lwip/pbuf.h>
#include <netif/etharp.h>
#include <lwip/tcpip.h>
#include <lwip/tcp.h>
#include <lwip/netif.h>
#include <lwip/dhcp.h>

#include "netif/etharp.h"

#include <netfront.h>

/* Define those to better describe your network interface. */
#define IFNAME0 'e'
#define IFNAME1 'n'

#define IF_IPADDR	0x00000000
#define IF_NETMASK	0x00000000

/* Only have one network interface at a time. */
static struct netif *the_interface = NULL;

static unsigned char rawmac[6];
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

#ifdef ETH_PAD_SIZE
  pbuf_header(p, -ETH_PAD_SIZE); /* drop the padding word */
#endif

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

#if ETH_PAD_SIZE
  pbuf_header(p, ETH_PAD_SIZE);			/* reclaim the padding word */
#endif
  
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
  struct eth_hdr *ethhdr;
  struct pbuf *p, *q;

#if ETH_PAD_SIZE
  len += ETH_PAD_SIZE; /* allow room for Ethernet padding */
#endif
  
  /* move received packet into a new pbuf */
  p = pbuf_alloc(PBUF_RAW, len, PBUF_POOL);
  if (p == NULL) {
    LINK_STATS_INC(link.memerr);
    LINK_STATS_INC(link.drop);
    return;
  }

#if ETH_PAD_SIZE
  pbuf_header(p, -ETH_PAD_SIZE); /* drop the padding word */
#endif
  
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

#if ETH_PAD_SIZE
  pbuf_header(p, ETH_PAD_SIZE); /* reclaim the padding word */
#endif

  LINK_STATS_INC(link.recv);

  /* points to packet payload, which starts with an Ethernet header */
  ethhdr = p->payload;

  ethhdr = p->payload;
    
  switch (htons(ethhdr->type)) {
  /* IP packet? */
  case ETHTYPE_IP:
#if 0
/* CSi disabled ARP table update on ingress IP packets.
   This seems to work but needs thorough testing. */
    /* update ARP table */
    etharp_ip_input(netif, p);
#endif
    /* skip Ethernet header */
    pbuf_header(p, -(int16_t)sizeof(struct eth_hdr));
    /* pass to network layer */
    if (tcpip_input(p, netif) == ERR_MEM)
      /* Could not store it, drop */
      pbuf_free(p);
    break;
      
  case ETHTYPE_ARP:
    /* pass p to ARP module  */
    etharp_arp_input(netif, (struct eth_addr *) netif->hwaddr, p);
    break;

  default:
    pbuf_free(p);
    p = NULL;
    break;
  }
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
 * Set the IP, mask and gateway of the IF
 */
void networking_set_addr(struct ip_addr *ipaddr, struct ip_addr *netmask, struct ip_addr *gw)
{
  netif_set_ipaddr(the_interface, ipaddr);
  netif_set_netmask(the_interface, netmask);
  netif_set_gw(the_interface, gw);
}


static void
arp_timer(void *arg)
{
  etharp_tmr();
  sys_timeout(ARP_TMR_INTERVAL, arp_timer, NULL);
}

/*
 * netif_netfront_init():
 *
 * Should be called at the beginning of the program to set up the
 * network interface. It calls the function low_level_init() to do the
 * actual setup of the hardware.
 *
 */

err_t
netif_netfront_init(struct netif *netif)
{
  unsigned char *mac = netif->state;

#if LWIP_SNMP
  /* ifType ethernetCsmacd(6) @see RFC1213 */
  netif->link_type = 6;
  /* your link speed here */
  netif->link_speed = ;
  netif->ts = 0;
  netif->ifinoctets = 0;
  netif->ifinucastpkts = 0;
  netif->ifinnucastpkts = 0;
  netif->ifindiscards = 0;
  netif->ifoutoctets = 0;
  netif->ifoutucastpkts = 0;
  netif->ifoutnucastpkts = 0;
  netif->ifoutdiscards = 0;
#endif
  
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

  sys_timeout(ARP_TMR_INTERVAL, arp_timer, NULL);

  return ERR_OK;
}

/*
 * Thread run by netfront: bring up the IP address and fire lwIP timers.
 */
static __DECLARE_SEMAPHORE_GENERIC(tcpip_is_up, 0);
static void tcpip_bringup_finished(void *p)
{
  tprintk("TCP/IP bringup ends.\n");
  up(&tcpip_is_up);
}

/* 
 * Utility function to bring the whole lot up.  Call this from app_main() 
 * or similar -- it starts netfront and have lwIP start its thread,
 * which calls back to tcpip_bringup_finished(), which 
 * lets us know it's OK to continue.
 */
void start_networking(void)
{
  struct netif *netif;
  struct ip_addr ipaddr = { htonl(IF_IPADDR) };
  struct ip_addr netmask = { htonl(IF_NETMASK) };
  struct ip_addr gw = { 0 };
  char *ip = NULL;

  tprintk("Waiting for network.\n");

  dev = init_netfront(NULL, NULL, rawmac, &ip);
  
  if (ip) {
    ipaddr.addr = inet_addr(ip);
    if (IN_CLASSA(ntohl(ipaddr.addr)))
      netmask.addr = htonl(IN_CLASSA_NET);
    else if (IN_CLASSB(ntohl(ipaddr.addr)))
      netmask.addr = htonl(IN_CLASSB_NET);
    else if (IN_CLASSC(ntohl(ipaddr.addr)))
      netmask.addr = htonl(IN_CLASSC_NET);
    else
      tprintk("Strange IP %s, leaving netmask to 0.\n", ip);
  }
  tprintk("IP %x netmask %x gateway %x.\n",
          ntohl(ipaddr.addr), ntohl(netmask.addr), ntohl(gw.addr));
  
  tprintk("TCP/IP bringup begins.\n");
  
  netif = xmalloc(struct netif);
  tcpip_init(tcpip_bringup_finished, netif);
    
  netif_add(netif, &ipaddr, &netmask, &gw, rawmac, 
            netif_netfront_init, ip_input);
  netif_set_default(netif);
  netif_set_up(netif);

  down(&tcpip_is_up);

  tprintk("Network is ready.\n");
}

/* Shut down the network */
void stop_networking(void)
{
  if (dev)
    shutdown_netfront(dev);
}
