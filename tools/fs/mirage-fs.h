/*
 * Copyright (c) 2011 Julian Chesterfield <julian.chesterfield@citrix.com>
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

#include <sys/types.h>
#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <pwd.h>
#include <grp.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>

#define roundup(x,n) (((x)+((n)-1))&(~((n)-1)))

#define SECTOR_SIZE 1 << 9
#define PAGE_SIZE SECTOR_SIZE << 3
#define START_OFFSET PAGE_SIZE << 10

#define MAGIC_HDR 0xDEADBEEF

struct fs_hdr {
  u_int32_t magic;
  u_int64_t offset;
  u_int64_t length;
  u_int32_t namelen;
  char filename[488];
} __attribute__((__packed__));

struct fs_hdr *init_hdr(char *filename, uint64_t length, uint64_t offset);
struct fs_hdr *read_hdr(int fd);
int fcopy(int infd, int outfd, u_long length);
int fzero(int, int);

#if HAVE_BYTESWAP_H
#  include <byteswap.h>
#else
#  define bswap_16(v) ((((v) & 0xff) << 8) | ((v) >> 8))
#  define bswap_32(v)                                       \
    (((uint32_t)bswap_16((uint16_t)((v) & 0xffff)) << 16)   \
     | (uint32_t)bswap_16((uint16_t)((v) >> 16)))
#  define bswap_64(v)                                         \
    (((uint64_t)bswap_32((uint32_t)((v) & 0xffffffff)) << 32) \
     | (uint64_t)bswap_32((uint32_t)((v) >> 32)))
#endif

#if !defined(be32toh)
#  if defined(__LITTLE_ENDIAN__)
#    define be32toh(x) bswap_32(x)
#  else
#    define be32toh(x) (x)
#  endif
#endif

#if !defined(htobe32)
#  if defined(__LITTLE_ENDIAN__)
#    define htobe32(x) bswap_32(x)
#  else
#    define htobe32(x) (x)
#  endif
#endif

#if !defined(htobe64)
#  if defined(__LITTLE_ENDIAN__)
#    define htobe64(x) bswap_64(x)
#  else
#    define htobe64(x) (x)
#  endif
#endif

#if !defined(be64toh)
#  if defined(__LITTLE_ENDIAN__)
#    define be64toh(x) bswap_64(x)
#  else
#    define be64toh(x) (x)
#  endif
#endif
