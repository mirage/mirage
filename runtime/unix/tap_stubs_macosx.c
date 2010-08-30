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

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <net/if_dl.h>

extern uint8_t ev_fds[];

CAMLprim value
tap_opendev(value v_str)
{
  char name[IFNAMSIZ];
  snprintf(name, sizeof name, "/dev/%s", String_val(v_str));
  fprintf(stderr, "opendev: %s\n", name);
  int fd = open(name, O_RDWR);
  if (fd < 0)
    caml_failwith("tap open failed");
  /* Mark interface as up
     Since MacOS doesnt have ethernet bridging built in, the
     IP binding is temporary until someone writes a KPI filter for Darwin */
  char buf[1024];
  snprintf(buf, sizeof buf, "/sbin/ifconfig %s 10.0.0.1 netmask 255.255.255.0 up", String_val(v_str));
  system(buf);
  ev_fds[fd] = 1;
  return Val_int(fd);
}

CAMLprim value
tap_mac(value v_name, value v_fd)
{
  CAMLparam2(v_name, v_fd);
  CAMLlocal1(v_str);

  struct ifaddrs *ifap, *ifa;
  int rv;

  if (( rv = getifaddrs(&ifap)) < 0)
    caml_failwith("tap_mac getifaddrs fail");
  if (!ifap)
    caml_failwith("tap_mac ifap NULL");

  v_str = 0;
  for (ifa = ifap; ifa != NULL; ifa = ifa->ifa_next) {
    if (ifa->ifa_addr->sa_family == AF_LINK)
      if (strcmp(ifa->ifa_name, String_val(v_name)) == 0) {
        struct sockaddr_dl *sdl = (struct sockaddr_dl *)ifa->ifa_addr;
        v_str = caml_alloc_string(sdl->sdl_alen);
        memcpy(String_val(v_str), LLADDR(sdl), sdl->sdl_alen);
      }
  }
  freeifaddrs(ifap);
  if (!v_str)
    caml_failwith("tap_mac ifaddr not found");
  CAMLreturn(v_str);
}
