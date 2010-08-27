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
#include <errno.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>

#define LINUX

#ifdef LINUX
#include <net/if.h>
#include <sys/ioctl.h>
#include <linux/if_tun.h>
#endif

extern uint8_t ev_callback_ml[];
extern uint8_t ev_fds[];

#ifdef LINUX
int tun_alloc(char *dev)
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

CAMLprim value
tap_opendev(value v_str)
{
  char dev[IFNAMSIZ];
  int fd;
  bzero(dev, sizeof dev);
  memcpy(dev, String_val(v_str), caml_string_length(v_str));
  fd = tun_alloc(dev);
  ev_fds[fd] = 1;
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
  ev_fds[fd] = 1;
  return Val_int(fd);
}
#endif
#endif

CAMLprim value
tap_read(value v_fd, value v_buf, value v_off, value v_len)
{
  int fd = Int_val(v_fd);
  int res = read(fd, String_val(v_buf) + Int_val(v_off), Int_val(v_len));
  if (res < 0) {
    fprintf(stderr, "read err: %s\n", strerror(errno));
    caml_failwith("tap_read < 0");
  }
  return Val_int(res);
}

CAMLprim value
tap_has_input(value v_fd)
{
  int fd = Int_val(v_fd);
  fd_set fdset;
  struct timeval tv;
  int ret;
  FD_ZERO(&fdset);
  FD_SET(fd, &fdset);
  tv.tv_sec = 0;
  tv.tv_usec = 1;
  ret = select(fd+1, &fdset, NULL, NULL, &tv);
  return Val_int(ret == 1 ? 1 : 0);
}

CAMLprim value
tap_write(value v_fd, value v_buf)
{
  int fd = Int_val(v_fd);
  size_t len = caml_string_length(v_buf);
  int res = write(fd, String_val(v_buf), len);
  if (res != len)
    caml_failwith("tap_write: not full write");
  return Val_int(len);
}

CAMLprim value
tap_mac(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal1(v_str);
  int fd = Int_val(v_fd);
  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  if (ioctl(fd, SIOCGIFHWADDR, (void *)&ifr) < 0)
    caml_failwith("tuntap SIOCGIFHWADDR failed");
  v_str = caml_alloc_string(6);
  memcpy(String_val(v_str), ifr.ifr_hwaddr.sa_data, 6);
  CAMLreturn(v_str);
}
