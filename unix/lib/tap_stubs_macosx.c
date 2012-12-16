/*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <err.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <net/ndrv.h>
#include <ifaddrs.h>

#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <net/bpf.h>

#include <string.h>

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <sys/ioctl.h>
#include <net/if_dl.h>


static void
setnonblock(int fd)
{
  int flags;
  flags = fcntl(fd, F_GETFL);
  if (flags < 0)
    err(1, "setnonblock: fcntl");
  flags |= O_NONBLOCK;
  if (fcntl(fd, F_SETFL, flags) < 0)
    err(1, "setnonblock, F_SETFL");
}

CAMLprim value
tap_opendev(value v_str)
{
  char name[IFNAMSIZ];
  snprintf(name, sizeof name, "/dev/%s", String_val(v_str));

  int dev_id;

  //small hack to create multiple interfaces
  sscanf(name, "/dev/tap%d", &dev_id);
  fprintf(stderr, "I should be opening 10.%d.0.1\n", dev_id);

  fprintf(stderr, "opendev: %s\n", name);
  int fd = open(name, O_RDWR);
  if (fd < 0)
    err(1, "tap_opendev");
  setnonblock(fd);
  /* Mark interface as up
     Since MacOS doesnt have ethernet bridging built in, the
     IP binding is temporary until someone writes a KPI filter for Darwin */
  char buf[1024];
  snprintf(buf, sizeof buf, "/sbin/ifconfig %s 10.%d.0.1 netmask 255.255.255.0 up", String_val(v_str), dev_id);
  fprintf(stderr, "%s\n", buf);
  system(buf);
  return Val_int(fd);
}

CAMLprim value
eth_opendev(value v_str)
{
  char name[IFNAMSIZ];
  snprintf(name, sizeof name, "%s", String_val(v_str));

  // opening socket
  int fd = socket(PF_NDRV, SOCK_RAW, 0);
 
  // bind to interface
  struct sockaddr_ndrv ndrv;
  strlcpy((char*)ndrv.snd_name, name, IFNAMSIZ);
  ndrv.snd_len = sizeof(ndrv);
  ndrv.snd_family = AF_NDRV;
  bind(fd, (struct sockaddr*)&ndrv, sizeof(ndrv));

  if (fd < 0)
    err(1, "eth_opendev");
  setnonblock(fd);
  
  // return the fd
  return Val_int(fd);
}

CAMLprim value
pcap_opendev(value v_name) {
  CAMLparam1(v_name);
  
  // opening socket
  int fd, i, flag = 1;
  char buf[ 11 ];
  struct ifreq bound_if;
  char name[IFNAMSIZ];

  snprintf(name, sizeof name, "%s", String_val(v_name));

  for( i = 0; i < 99; i++ ) {
    sprintf( buf, "/dev/bpf%i", i );
    fd = open( buf, O_RDWR );
    if( fd != -1 )break;
  }

  if (fd < 0)
    err(1, "pcap_opendev");
  printf ("open dev '%s' with bpf '%s'\n", name, buf) ; 

  // bind to interface
  strcpy(bound_if.ifr_name, name);
  if(ioctl( fd, BIOCSETIF, &bound_if ) > 0)
    err(1, "pcap_opendev");

  // activate immediate mode (therefore, buf_len is initially set to "1")
  if( ioctl(fd, BIOCIMMEDIATE, &flag) == -1)
    err(1, "pcap_opendev");
  if( ioctl(fd, BIOCPROMISC, &flag) == -1)
    err(1, "pcap_opendev");
  if( ioctl(fd, BIOCSHDRCMPLT, &flag) == -1)
    err(1, "pcap_opendev");

  flag = 0;
  if( ioctl(fd, BIOCSSEESENT, &flag) == -1)
    err(1, "pcap_opendev");
 
  setnonblock(fd);

  // return the fd
  CAMLreturn(Val_int(fd));
}

CAMLprim value
pcap_get_buf_len(value v_fd) {
  CAMLparam1(v_fd);
  int buf_len;
    
  // request buffer length
  if(ioctl( Int_val(v_fd), BIOCGBLEN, &buf_len ) == -1 )
    err(1, "pcap_get_buf_len");

  CAMLreturn(Val_int(buf_len));
}

CAMLprim value
get_mac_addr(value v_str) {
  CAMLparam1( v_str );
  CAMLlocal1(v_mac);
  
  struct ifaddrs *ifap, *p;
  char *mac_addr[6]; 
  int found = 0;
  char name[IFNAMSIZ];
  snprintf(name, sizeof name, "%s", String_val(v_str));

  if (getifaddrs(&ifap) != 0) {
    err(1, "get_mac_addr");
  }

  for(p = ifap; p != NULL; p = p->ifa_next) {
    if((strcmp(p->ifa_name, name) == 0) &&
      (p->ifa_addr != NULL)){
      char *tmp = LLADDR((struct sockaddr_dl *)(p)->ifa_addr);
      memcpy(mac_addr, tmp, 6);
      found = 1;
      break;
    } 
  }

  freeifaddrs(ifap);
  if (!found) 
    err(1, "get_mac_addr");

  v_mac = caml_alloc_string(6);
  memcpy(String_val(v_mac), mac_addr, 6);
  CAMLreturn (v_mac);
} 
