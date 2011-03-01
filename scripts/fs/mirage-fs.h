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

#define MAGIC_HDR 0xF0F0


struct fs_hdr {
  u_int16_t magic;
  u_int64_t offset;
  u_int64_t length;
  char filename[490];
};

struct fs_hdr *init_hdr(char *filename, int length, u_long offset);
struct fs_hdr *read_hdr(int fd);
int fcopy(int infd, int outfd, u_long length);

