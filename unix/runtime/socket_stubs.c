/*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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
#include <sys/un.h>
#include <sys/stat.h>
#include <dirent.h>
#include <arpa/inet.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

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

/* Get a UDP socket suitable for sendto(2).
   Only used at start-of-day so failwith ok here for now */
CAMLprim value
caml_udpv4_socket(value v_unit)
{
  CAMLparam1(v_unit);
  int s = socket(PF_INET, SOCK_DGRAM, 0);
  if (s < 0)
    caml_failwith("socket() failed");
  else {
    setnonblock(s);
    CAMLreturn(Val_int(s));
  }
}

CAMLprim value
caml_tcpv4_connect(value v_ipaddr, value v_port)
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
  if (s < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    CAMLreturn(v_ret);
  }
  setnonblock(s); 
  r = connect(s, (struct sockaddr *)&sa, sizeof(struct sockaddr));
  if (r == 0 || (r == -1 && errno == EINPROGRESS)) {
    Val_OK(v_ret, Val_int(s));
  } else {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_socket_connect_result(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal2(v_ret, v_err);
  int fd = Int_val(v_fd);
  int valopt;
  socklen_t lon = sizeof(int);
  if (getsockopt(fd, SOL_SOCKET, SO_ERROR, (void*)(&valopt), &lon) < 0)
    err(1, "tcp_connect_result: getsockopt");
  if (!valopt) { 
    Val_OK(v_ret, Val_unit);
  } else {
    v_err = caml_copy_string(strerror(valopt));
    Val_Err(v_ret, v_err);
    close(fd);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_tcpv4_bind(value v_ipaddr, value v_port)
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
    err(1, "caml_tcp_bind: socket");
  setnonblock(s);
  setreuseaddr(s);
  r = bind(s, (struct sockaddr *)&sa, sizeof(struct sockaddr));
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
caml_socket_listen(value v_socket)
{
  CAMLparam1(v_socket);
  CAMLlocal2(v_err, v_ret);
  int r, s = Int_val(v_socket);
  r = listen(s, 25);
  if (r < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
    CAMLreturn(v_ret);
  }
  Val_OK(v_ret, Val_unit);
  CAMLreturn(v_ret);
}

CAMLprim value
caml_tcpv4_accept(value v_fd)
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
    setnonblock(r);
    v_ip = caml_copy_int32(ntohl(sa.sin_addr.s_addr));
    v_ca = caml_alloc(3,0);
    Store_field(v_ca, 0, Val_int(r));
    Store_field(v_ca, 1, v_ip);
    Store_field(v_ca, 2, Val_int(ntohs(sa.sin_port)));
    Val_OK(v_ret, v_ca);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_socket_read(value v_fd, value v_ba, value v_off, value v_len)
{
  CAMLparam4(v_fd ,v_ba, v_off, v_len);
  CAMLlocal2(v_ret, v_err);
  char *buf = Caml_ba_data_val(v_ba);
  int r = read(Int_val(v_fd), buf + Int_val(v_off), Int_val(v_len));
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
caml_socket_write(value v_fd, value v_ba, value v_off, value v_len)
{
  CAMLparam4(v_fd, v_ba, v_off, v_len);
  CAMLlocal2(v_ret, v_err);
  char *buf = Caml_ba_data_val(v_ba);
  int r = write(Int_val(v_fd), buf + Int_val(v_off), Int_val(v_len));
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

/* Bind a UDP socket to a local v4 addr and return it */
CAMLprim value
caml_udpv4_bind(value v_ipaddr, value v_port)
{
  CAMLparam2(v_ipaddr, v_port);
  CAMLlocal2(v_ret, v_err);
  int s = socket(PF_INET, SOCK_DGRAM, 0);
  if (s < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    CAMLreturn(v_ret);
  }
  setnonblock(s);
  struct sockaddr_in sa;
  bzero(&sa, sizeof sa);
  sa.sin_family = AF_INET;
  sa.sin_addr.s_addr = ntohl(Int32_val(v_ipaddr));
  sa.sin_port = htons(Int_val(v_port));
 
  int r = bind(s, (struct sockaddr *)&sa, sizeof(struct sockaddr));
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
caml_udpv4_recvfrom(value v_fd, value v_ba, value v_off, value v_len, value v_src)
{
  CAMLparam5(v_fd, v_ba, v_off, v_len, v_src);
  CAMLlocal3(v_ret, v_err, v_inf);
  char *buf = Caml_ba_data_val(v_ba) + Int_val(v_off);
  size_t len = Int_val(v_len);
  int fd = Int_val(v_fd);
  struct sockaddr_in sa;
  socklen_t sa_len = sizeof(sa);
  int r = recvfrom(fd, (void *)buf, len, MSG_DONTWAIT, (struct sockaddr *)&sa, &sa_len);
  if (r < 0) {
    if (errno == EAGAIN || errno==EWOULDBLOCK)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }
  } else {
    v_inf = caml_alloc_tuple(3);
    Store_field(v_inf, 0, caml_copy_int32(ntohl(sa.sin_addr.s_addr)));
    Store_field(v_inf, 1, Val_int(ntohs(sa.sin_port)));
    Store_field(v_inf, 2, Val_int(r));
    Val_OK(v_ret, v_inf);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_udpv4_sendto(value v_fd, value v_ba, value v_off, value v_len, value v_dst)
{
  CAMLparam5(v_fd, v_ba, v_off, v_len, v_dst);
  CAMLlocal2(v_ret, v_err);
  char *buf = Caml_ba_data_val(v_ba) + Int_val(v_off);
  size_t len = Int_val(v_len);
  int fd = Int_val(v_fd);
  struct sockaddr_in sa;
  socklen_t sa_len = sizeof(sa);
  bzero(&sa, sizeof sa);
  sa.sin_family = AF_INET;
  sa.sin_addr.s_addr = htonl(Int32_val(Field(v_dst, 0)));
  sa.sin_port = htons(Int_val(Field(v_dst, 1)));

  int r = sendto(fd, buf, len, MSG_DONTWAIT, (struct sockaddr *)&sa, sa_len);
  if (r < 0) {
    if (errno == EAGAIN || errno==EWOULDBLOCK)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }
  } else {
    Val_OK(v_ret, Val_int(r));
  }
  CAMLreturn(v_ret);
}

/* Get a unique name for this process (just PID atm) */
CAMLprim value
caml_domain_name(value v_unit)
{
  return (Val_int(getpid()));
}

static char *
get_domaindir(void)
{
  char *basedir = getenv("MIRAGE_RUNDIR");
  if (!basedir) basedir="/tmp";
  return basedir;
}

/* Bind a domain socket to the given name in the mirage runtime dir,
   and listen for connections */
CAMLprim value
caml_domain_bind(value v_uid)
{
  CAMLparam1(v_uid);
  CAMLlocal2(v_ret, v_err);
  struct sockaddr_un sa;
  size_t len;
  int s,r;
  s = socket(AF_UNIX, SOCK_STREAM, 0);
  if (s < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    CAMLreturn(v_ret);
  }  
  setnonblock(s);
  bzero(&sa, sizeof sa);
  sa.sun_family = AF_UNIX;
  snprintf(sa.sun_path, sizeof(sa.sun_path), "%s/mirage.%d", get_domaindir(), Int_val(v_uid));
  unlink(sa.sun_path);
  len = strlen(sa.sun_path) + sizeof(sa.sun_family) + 1;
  r = bind(s, (struct sockaddr *)&sa, len);
  if (r < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
    CAMLreturn(v_ret);
  }

  r = listen(s,5);
  if (r < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
    CAMLreturn(v_ret);
  }
  Val_OK(v_ret, Val_int(s));
  CAMLreturn(v_ret);
}

/* Allocate a pipe and return (readpipe,writepipe) */
CAMLprim value
caml_alloc_pipe(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal3(v_ret, v_err, v_fd);
  int pipefd[2] = { -1, -1 };
  if (pipe(pipefd) == -1) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    CAMLreturn(v_ret);
  }
  setnonblock(pipefd[0]);
  setnonblock(pipefd[1]);
  v_fd = caml_alloc(2,0);
  Store_field(v_fd, 0, Val_int(pipefd[0]));
  Store_field(v_fd, 1, Val_int(pipefd[1]));
  Val_OK(v_ret, v_fd);
  CAMLreturn(v_ret);
}

/* Connect to a local unix domain socket */
CAMLprim value
caml_domain_connect(value v_uid)
{
  CAMLparam1(v_uid);
  CAMLlocal2(v_ret, v_err);
  int s,r,len;
  struct sockaddr_un sa;
  s = socket(PF_LOCAL, SOCK_STREAM, 0);
  if (s < 0) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    CAMLreturn(v_ret);
  }
  setnonblock(s); 
  bzero(&sa, sizeof sa);
  sa.sun_family = AF_UNIX;
  snprintf(sa.sun_path, sizeof(sa.sun_path), "%s/mirage.%d", get_domaindir(), Int_val(v_uid));
  len = strlen(sa.sun_path) + sizeof(sa.sun_family) + 1;
  r = connect(s, (struct sockaddr *)&sa, len);
  if (r == 0 || (r == -1 && errno == EINPROGRESS)) {
    Val_OK(v_ret, Val_int(s));
  } else {
    if (errno == ECONNREFUSED)
      unlink(sa.sun_path); /* Garbage collect the stale domain socket */
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
    close(s);
  }
  CAMLreturn(v_ret);
}

/* Accept a connection from another UNIX domain socket */
CAMLprim value
caml_domain_accept(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal2(v_ret,v_err);
  int r, s=Int_val(v_fd);
  struct sockaddr_un sa;
  socklen_t len = sizeof sa;
  r = accept(s, (struct sockaddr *)&sa, &len);
  if (r < 0) {
    if (errno == EWOULDBLOCK || errno == EAGAIN)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }
  } else {
    setnonblock(r);
    Val_OK(v_ret, Val_int(r));
  }
  CAMLreturn(v_ret);
}

/* Walk through the socket directory and list all the domains.
   TODO This is racy, and will eventually work via a control daemon */
CAMLprim value
caml_domain_list(value v_unit)
{
  CAMLparam1(v_unit);
  CAMLlocal2(v_head, v_cons);
  v_head = Val_emptylist;
  DIR *dirp = opendir(get_domaindir());
  struct dirent *dp;
  if (!dirp)
    err(1, "opendir");
  while ((dp = readdir(dirp))) {
    int uid = -1;
    if (sscanf(dp->d_name, "mirage.%d", &uid) == 1 &&
        uid != getpid()) {
      v_cons = caml_alloc(2, 0);
      Store_field(v_cons, 0, Val_int(uid));
      Store_field(v_cons, 1, v_head);
      v_head = v_cons;
    }
  }
  closedir(dirp);
  CAMLreturn(v_head);
}

/* Send a fd over to another process */
CAMLprim value
caml_domain_send_fd(value v_dstfd, value v_fd)
{
  CAMLparam2(v_dstfd, v_fd);
  CAMLlocal2(v_err, v_ret);

  struct msghdr msg;
  char tmp[CMSG_SPACE(sizeof(int))];
  struct cmsghdr *cmsg;
  struct iovec vec;
  int result = 0;
  ssize_t n;

  bzero(&msg, sizeof(msg));
  msg.msg_control = (caddr_t)tmp;
  msg.msg_controllen = CMSG_LEN(sizeof(int));
  cmsg = CMSG_FIRSTHDR(&msg);
  cmsg->cmsg_len = CMSG_LEN(sizeof(int));
  cmsg->cmsg_level = SOL_SOCKET;
  cmsg->cmsg_type = SCM_RIGHTS;
  *(int *)CMSG_DATA(cmsg) = Int_val(v_fd);

  vec.iov_base = &result;
  vec.iov_len = sizeof(int);
  msg.msg_iov = &vec;
  msg.msg_iovlen = 1;

  if ((n = sendmsg(Int_val(v_dstfd), &msg, 0)) != sizeof(int)) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
  } else
    Val_OK(v_ret, Val_unit);
  CAMLreturn(v_ret);
}

CAMLprim value
caml_domain_recv_fd(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal2(v_err, v_ret);

  struct msghdr msg;
  char tmp[CMSG_SPACE(sizeof(int))];
  struct cmsghdr *cmsg;
  struct iovec vec;
  ssize_t n;
  int result;

  bzero(&msg, sizeof(msg));
  vec.iov_base = &result;
  vec.iov_len = sizeof(int);
  msg.msg_iov = &vec;
  msg.msg_iovlen = 1;
  msg.msg_control = tmp;
  msg.msg_controllen = sizeof(tmp);

  if ((n = recvmsg(Int_val(v_fd), &msg, 0)) == -1) {
    if (errno == EAGAIN || errno == EWOULDBLOCK) {
      Val_WouldBlock(v_ret);
      CAMLreturn(v_ret);
    }
    goto err;
  }

  if (result == 0) {
    cmsg = CMSG_FIRSTHDR(&msg);
    if (cmsg == NULL)
      goto err;
    if (cmsg->cmsg_type != SCM_RIGHTS)
      goto err;
    Val_OK(v_ret, Val_int((*(int *)CMSG_DATA(cmsg))));
    CAMLreturn(v_ret);
  }
err:
  v_err = caml_copy_string(strerror(errno));
  Val_Err(v_ret, v_err);
  CAMLreturn(v_ret);
}

/* Read from a connected domain socket, intended for small control
   messages only (such as peer uid) */
CAMLprim value
caml_domain_read(value v_fd)
{
  CAMLparam1(v_fd);
  CAMLlocal2(v_ret, v_err);
  char buf[64];
  int r = read(Int_val(v_fd), buf, sizeof(buf));
  if (r < 0) {
    if (errno == EAGAIN || errno==EWOULDBLOCK)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }   
  } else
    Val_OK(v_ret, caml_copy_string(buf));
  CAMLreturn(v_ret);
}

CAMLprim value
caml_domain_write(value v_fd, value v_str)
{
  CAMLparam2(v_fd, v_str);
  CAMLlocal2(v_ret, v_err);
  int len = caml_string_length(v_str);
  int r = write(Int_val(v_fd), String_val(v_str), len);
  if (r < 0) {
    if (errno == EAGAIN || errno==EWOULDBLOCK)
      Val_WouldBlock(v_ret);
    else {
      v_err = caml_copy_string(strerror(errno));
      Val_Err(v_ret, v_err);
    }
  } else if (r != len) {
    v_err = caml_copy_string("domain_write: partial write");
    Val_Err(v_ret, v_err);
  } else {
    Val_OK(v_ret, Val_unit);
  }
  CAMLreturn(v_ret);
}

/* Open a non-blocking file socket and return it.
   Note that non-blocking file I/O is a bit unreliable, so
   this is only a temporary measure (see mincore usage in Lwt_unix
   for another approach) */
CAMLprim value
caml_file_open_ro(value v_filename)
{
  CAMLparam1(v_filename);
  CAMLlocal2(v_ret, v_err);
  /* Ensure that the requested file is not a directory */
  struct stat buf;
  int r = stat(String_val(v_filename), &buf);
  if (r == -1) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
  } else {
    if (buf.st_mode & S_IFDIR) {
      v_err = caml_copy_string("cannot open directory");
      Val_Err(v_ret, v_err);
    } else {
      int r = open(String_val(v_filename), O_RDONLY);
      if (r == -1) {
        v_err = caml_copy_string(strerror(errno));
        Val_Err(v_ret, v_err);
      } else {
        setnonblock(r);
        Val_OK(v_ret, Val_int(r));
      }
    }
  }
  CAMLreturn(v_ret);
}

/* Open a non-blocking file socket for read/write and return it.
   Note that non-blocking file I/O is a bit unreliable, so
   this is only a temporary measure (see mincore usage in Lwt_unix
   for another approach) */
CAMLprim value
caml_file_open_rw(value v_filename)
{
  CAMLparam1(v_filename);
  CAMLlocal2(v_ret, v_err);
  /* Ensure that the requested file is not a directory */
  struct stat buf;
  int r = stat(String_val(v_filename), &buf);
  if (r == -1) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
  } else {
    if (buf.st_mode & S_IFDIR) {
      v_err = caml_copy_string("cannot open directory");
      Val_Err(v_ret, v_err);
    } else {
      int r = open(String_val(v_filename), O_RDWR);
      if (r == -1) {
        v_err = caml_copy_string(strerror(errno));
        Val_Err(v_ret, v_err);
      } else {
        setnonblock(r);
        Val_OK(v_ret, Val_int(r));
      }
    }
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_lseek(value v_fd, value v_off)
{
  CAMLparam2(v_fd, v_off);
  CAMLlocal2(v_ret, v_err);
  off_t r = lseek(Int_val(v_fd), Int64_val(v_off), SEEK_SET);
  if (r == -1) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
  } else {
    Val_OK(v_ret, Val_unit);
  }
  CAMLreturn(v_ret);
}


/* Directory functions */
CAMLprim value
caml_opendir(value v_dirname)
{
  CAMLparam1(v_dirname);
  CAMLlocal2(v_ret, v_err);
  DIR *dir = opendir(String_val(v_dirname));
  if (!dir) {
     v_err = caml_copy_string(strerror(errno));
     Val_Err(v_ret, v_err);
  } else {
    Val_OK(v_ret, (value)dir);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_readdir(value v_dir)
{
  CAMLparam1(v_dir);
  CAMLlocal3(v_de, v_ret, v_err);
  struct dirent *de = readdir((DIR *)v_dir);
  if (!de) { /* EOF */
    v_err = caml_copy_string("");
    Val_Err(v_ret, v_err);
  } else {
    if (de->d_type == DT_REG) {
      v_de = caml_copy_string(de->d_name);
      Val_OK(v_ret, v_de);
    } else {
      Val_WouldBlock(v_ret);
    }
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_closedir(value v_dir)
{
  CAMLparam1(v_dir);
  CAMLlocal2(v_ret, v_err);
  int r = closedir((DIR *)v_dir);
  if (r == -1) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
  } else {
    Val_OK(v_ret, Val_unit);
  }
  CAMLreturn(v_ret);
}

CAMLprim value
caml_stat_size(value v_filename)
{
  CAMLparam1(v_filename);
  CAMLlocal3(v_sz, v_ret, v_err);
  struct stat buf;
  int r = stat(String_val(v_filename), &buf);
  if (r == -1) {
    v_err = caml_copy_string(strerror(errno));
    Val_Err(v_ret, v_err);
  } else {
    v_sz = caml_copy_int64(buf.st_size);
    Val_OK(v_ret, v_sz);
  }
  CAMLreturn(v_ret);
}

