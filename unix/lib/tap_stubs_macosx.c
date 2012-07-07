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

