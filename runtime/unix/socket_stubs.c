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

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>

#include <fcntl.h>
#include <errno.h>
#include <err.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

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

static void
setreuseaddr(int fd)
{
  int o = 1;
  if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &o, sizeof o) < 0)
    err(1, "setsockopt: reuseaddr");
} 
 
CAMLprim value
caml_socket_close(value v_fd)
{
  close(Int_val(v_fd));
  return Val_unit;
}

#define Val_OK(v, x) do { (v)=caml_alloc(1,0); Store_field((v),0,(x)); } while (0)
#define Val_Err(v, x) do { (v)=caml_alloc(1,1); Store_field((v),0,(x)); } while (0)
#define Val_WouldBlock(v) do { (v)=Val_int(2); } while (0)

CAMLprim value
caml_tcp_connect(value v_ipaddr, value v_port)
{
  CAMLparam2(v_ipaddr, v_port);
  CAMLlocal2(v_ret, v_err);
  int s,r;
  struct sockaddr_in sa;
  bzero(&sa, sizeof sa);
  sa.sin_family = AF_INET;
  sa.sin_port = htons(Int_val(v_port));
  sa.sin_addr.s_addr = ntohl(Int32_val(v_ipaddr));
  s = socket(PF_INET, SOCK_STREAM, 0);
  setnonblock(s); 
  if (s < 0)
    err(1, "caml_tcp_connect: socket");
  r = connect(s, (struct sockaddr *)&sa, sizeof(struct sockaddr));
  if (r == 0 || (r == -1 && errno == EINPROGRESS)) {
    fprintf(stderr, "connect: OK %d \n", r);
    Val_OK(v_ret, Val_int(s));
  } else {
    fprintf(stderr, "connect: ERR: %s\n", strerror(errno));
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_tcp_connect_result(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal2(v_ret, v_err);
  int fd = Int_val(v_fd);
  int valopt;
  socklen_t lon = sizeof(int);
  if (getsockopt(fd, SOL_SOCKET, SO_ERROR, (void*)(&valopt), &lon) < 0)
    err(1, "tcp_connect_result: getsockopt");
  if (!valopt) { 
    fprintf(stderr, "connect_result: OK\n");
    Val_OK(v_ret, Val_unit);
  } else {
    fprintf(stderr, "connect_result: ERR\n");
    v_err = caml_copy_string(strerror(valopt));
    Val_Err(v_ret, v_err);
    close(fd);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_tcp_listen(value v_ipaddr, value v_port)
{
  CAMLparam2(v_ipaddr, v_port);
  CAMLlocal2(v_ret, v_err);
  int s, r;
  struct sockaddr_in sa;
  bzero(&sa, sizeof sa);
  sa.sin_family = AF_INET;
  sa.sin_port = htons(Int_val(v_port));
  sa.sin_addr.s_addr = ntohl(Int32_val(v_ipaddr));
  s = socket(PF_INET, SOCK_STREAM, 0);
  if (s < 0)
    err(1, "caml_tcp_listen: socket");
  setreuseaddr(s);
  r = bind(s, (struct sockaddr *)&sa, sizeof(struct sockaddr));
  if (r < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
    CAMLreturn(v_ret);
  }
  r = listen(s, 5);
  setnonblock(s);
  if (r < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
    CAMLreturn(v_ret);
  }
  Val_OK(v_ret, Val_int(s));
  CAMLreturn(v_ret);
}

CAMLprim value
caml_tcp_accept(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal4(v_ret,v_err,v_ca,v_ip);
  int r, fd=Int_val(v_fd);
  struct sockaddr_in sa;
  socklen_t len = sizeof sa;
  r = accept(fd, (struct sockaddr *)&sa, &len);
  if (r < 0) {
    if (errno == EWOULDBLOCK || errno == EAGAIN)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }
  } else {
    v_ip = caml_copy_int32(ntohl(sa.sin_addr.s_addr));
    v_ca = caml_alloc(3,0);
    Store_field(v_ca, 0, Val_int(r));
    Store_field(v_ca, 1, v_ip);
    Store_field(v_ca, 2, Val_int(sa.sin_port));
    Val_OK(v_ret, v_ca);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_socket_read(value v_fd, value v_buf, value v_off, value v_len)
{
  CAMLparam4(v_fd ,v_buf, v_off, v_len);
  CAMLlocal2(v_ret, v_err);
  int r = read(Int_val(v_fd), String_val(v_buf) + Int_val(v_off), Int_val(v_len));
  if (r < 0) {
    if (errno == EAGAIN || errno==EWOULDBLOCK)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }   
  } else
    Val_OK(v_ret, Val_int(r));
  CAMLreturn(v_ret);
}

CAMLprim value
caml_socket_write(value v_fd, value v_buf, value v_off, value v_len)
{
  CAMLparam4(v_fd, v_buf, v_off, v_len);
  CAMLlocal2(v_ret, v_err);
  int r = write(Int_val(v_fd), String_val(v_buf) + Int_val(v_off), Int_val(v_len));
  if (r < 0) {
    if (errno == EAGAIN || errno==EWOULDBLOCK)
      Val_WouldBlock(v_ret);
    else {
      fprintf(stderr, "   err=%s\n", strerror(errno));
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }
  } else
    Val_OK(v_ret, Val_int(r));
  CAMLreturn(v_ret);
}
