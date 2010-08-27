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
#include <stdio.h>
#include <string.h>
#include <fcntl.h>

#include <caml/mlvalues.h>
#include <caml/fail.h>

#define LINUX

#ifdef LINUX
#include <net/if.h>
#include <sys/ioctl.h>
#include <linux/if_tun.h>
#endif

extern int tap_ready;
extern int tap_fd;

#ifdef LINUX
int tun_alloc(char *dev)
{
  struct ifreq ifr;
  int fd, err;
  if ((fd = open("/dev/net/tun", O_RDWR)) < 0)
    caml_failwith("unable to open /dev/net/tun");
  memset(&ifr, 0, sizeof(ifr));
  ifr.ifr_flags = IFF_TAP;
  if (*dev)
    strncpy(ifr.ifr_name, dev, IFNAMSIZ);
  fprintf(stderr, "fd=%d name=%s\n", fd, ifr.ifr_name);
  if ((err=ioctl(fd, TUNSETIFF, (void *)&ifr)) < 0) {
    fprintf(stderr, "TUNSETIFF failed: %d\n", err);
    caml_failwith("TUNSETIFF failed");
  }
  fprintf(stderr, "MAC=%.2x:%.2x:%.2x:%.2x:%.2x:%.2x\n",
         (unsigned char)ifr.ifr_hwaddr.sa_data[0],
         (unsigned char)ifr.ifr_hwaddr.sa_data[1],
         (unsigned char)ifr.ifr_hwaddr.sa_data[2],
         (unsigned char)ifr.ifr_hwaddr.sa_data[3],
         (unsigned char)ifr.ifr_hwaddr.sa_data[4],
         (unsigned char)ifr.ifr_hwaddr.sa_data[5]);
  strcpy(dev, ifr.ifr_name);
  return fd;
}

CAMLprim value
tap_opendev(value v_str)
{
  char dev[IFNAMSIZ];
  int fd;
  bzero(dev, sizeof dev);
  memcpy(dev, String_val(v_str), caml_string_length(v_str));
  fprintf(stderr, "tap_open: before dev=%s\n", dev);
  fd = tun_alloc(dev);
  fprintf(stderr, "   after dev=%s\n", dev);
  tap_fd = fd;
  return Val_int(fd);
}
#else
#ifdef DARWIN
CAMLprim value
tap_opendev(value v_str)
{
  int fd = open("/dev/tap0", O_RDWR);
  if (fd < 0)
    caml_failwith("tap open failed");
  return Val_int(fd);
}
#endif
#endif

CAMLprim value
tap_read(value v_fd, value v_buf, value v_off, value v_len)
{
  int fd = Int_val(v_fd);
  int res = read(fd, String_val(v_buf) + Int_val(v_off), Int_val(v_len));
  if (res < 0)
    caml_failwith("tap_read < 0");
  return Val_int(res);
}

CAMLprim value
tap_has_input(value v_fd)
{
  return Val_int(tap_ready);
}

CAMLprim value
tap_write(value v_fd, value v_buf)
{
  /* XXX figure out the IFF_NO_PI stuff */
  caml_failwith("tap_write: todo");
}

CAMLprim value
tap_mac(value v_tap)
{
  caml_failwith("\0\0\0\0\0\0");
}
