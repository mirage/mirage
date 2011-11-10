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
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <err.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <net/if.h>
#include <sys/ioctl.h>

#include <linux/if_tun.h>

static int tun_alloc(char *dev)
{
  struct ifreq ifr;
  int fd, err;
  if ((fd = open("/dev/net/tun", O_RDWR)) < 0)
    caml_failwith("unable to open /dev/net/tun");
  memset(&ifr, 0, sizeof(ifr));
  ifr.ifr_flags = IFF_TAP | IFF_NO_PI;
  if (*dev)
    strncpy(ifr.ifr_name, dev, IFNAMSIZ);
  if ((err=ioctl(fd, TUNSETIFF, (void *)&ifr)) < 0) {
    fprintf(stderr, "TUNSETIFF failed: %d\n", err);
    caml_failwith("TUNSETIFF failed");
  }
  strcpy(dev, ifr.ifr_name);
  return fd;
}

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
  char dev[IFNAMSIZ];
  char buf[4096];
  int fd;

  bzero(dev, sizeof dev);
  memcpy(dev, String_val(v_str), caml_string_length(v_str));
  fd = tun_alloc(dev);
  setnonblock(fd);

  int dev_id;

  //small hack to create multiple interfaces
  sscanf(dev, "tap%d", &dev_id);
  fprintf(stderr, "I should be opening 10.%d.0.1\n", dev_id);

  snprintf(buf, sizeof buf, "ip link set %s up", dev);
  if (system(buf) < 0) err(1, "system");
  snprintf(buf, sizeof buf, "/sbin/ifconfig %s 10.%d.0.2 netmask 255.255.255.0 up", String_val(v_str), dev_id);
  fprintf(stderr, "%s\n", buf);
  system(buf);
  if (system(buf) < 0) err(1, "system");
  fprintf(stderr, "tap_opendev: %s\n", dev);
  return Val_int(fd);
}
