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

#include "mirage-fs.h"

void usage() {
  printf("Usage:\n\textract <Dir> <INPUT>\n");
}

int main(int argc, char *argv[]) {
  char *dir;
  int outfd, infd;
  struct fs_hdr *fsh;
  int mseek = 0;
  int size, i;

  if (argc != 3) {
    usage();
    return -1;
  }

  infd = open(argv[2],O_RDONLY);
  if (infd == -1) {
    printf("Failed to open input file\n");
    return -1;
  }

  dir = argv[1];
  if(chdir(dir)!=0) {
    printf("Failed to change dir to %s\n",dir);
    return -1;
  }
  
  for(i=0; i<(START_OFFSET >> 9); i++) {
    uint64_t offset, length;
    mseek = i * SECTOR_SIZE;
    lseek(infd, mseek, SEEK_SET);
    fsh = read_hdr(infd);
    if(!fsh) break;
    offset = be64toh(fsh->offset);
    length = be64toh(fsh->length);
    printf("Node: %s %lu [%lu]\n", fsh->filename, length, offset);

    //Extract file to dir location
    outfd = open(fsh->filename, O_CREAT|O_WRONLY, S_IRUSR|S_IWUSR);
    lseek(infd, offset,SEEK_SET);
    size = fcopy(infd, outfd, length);
    ftruncate(outfd, length);

    free(fsh);
    close(outfd);
  }
  close(infd);
  return 0;
}
  
  

