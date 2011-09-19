/*
 * Copyright (c) 2011 Julian Chesterfield <julian.chesterfield@citrix.com>
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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
#include <stdio.h>
#include <err.h>

void start_write(char *, char *);

int outfd, mseek;
static int fseekv = START_OFFSET;

int
main(int argc, char *argv[])
{
  if (argc != 3) {
    printf("Usage: %s <root-dir> <output-device>\n", argv[0]);
    return 1;
  } 

  outfd = open(argv[2],O_WRONLY);
  if (outfd == -1 && errno == ENOENT) {
    outfd = open(argv[2],O_CREAT|O_WRONLY);
  }
  if (outfd == -1)
    err(2, "open output file");

  // Zero out metadata region and reset filehandle
  fzero(outfd, START_OFFSET);
  lseek(outfd, mseek, SEEK_SET);
  
  start_write(argv[1],"");
  lseek(outfd, mseek, SEEK_SET);
  close(outfd);
  return 0;
}

void
start_write(char *dirname, char *prefix)
{
  struct dirent* dirp;
  DIR* d;
  char *path;
  int infd;
  struct stat st;
  struct fs_hdr *fsh;
  int size;

  if ((d = opendir(dirname)) == NULL)
    err(1, "opendir");

  while ((dirp = readdir(d)) != NULL) {
    switch (dirp->d_type) {
    case DT_REG:
      size = strlen(dirname) + strlen(dirp->d_name) + 2;
      path = malloc(size);
      if(!path)
	err(1, "%s", path);
      snprintf(path, size, "%s/%s", dirname, dirp->d_name);

      //Open the file and write to dst
      infd = open(path, O_RDONLY);
      if (infd < 0)
        err(1, "open");
      free(path);

      if(fstat(infd, &st)!=0)
        err(1, "fstat");

      lseek(outfd, fseekv, SEEK_SET);
      size = fcopy(infd, outfd, roundup(st.st_size,SECTOR_SIZE));
      if (size < st.st_size)
	printf("Short file write [%s,%Lu,%d]\n",dirp->d_name,st.st_size,size);
      close(infd);

      //Seek to location and Write FS metadata
      char *fname = malloc(512);
      if (!fname) err(1, "malloc");
      snprintf(fname, 512, "%s%s", prefix, dirp->d_name);
      fsh = init_hdr(fname, st.st_size, fseekv);
      free(fname);
      lseek(outfd, mseek, SEEK_SET);
      write(outfd, fsh, sizeof(struct fs_hdr));

      //Reset FD pointers
      mseek += SECTOR_SIZE;
      fseekv += roundup(size,PAGE_SIZE);

      free(fsh);
      close(infd);
      break;
    case DT_DIR:
      if (!strcmp(dirp->d_name,".") || !strcmp(dirp->d_name,".."))
        break;
      char *subdir, *newprefix;
      subdir=malloc(4096);
      if (!subdir)
        err(1, "malloc");
      newprefix=malloc(512);
      if (!newprefix)
        err(1, "malloc");
      snprintf(subdir, 4096, "%s/%s", dirname, dirp->d_name);
      snprintf(newprefix, 512, "%s%s/", prefix, dirp->d_name);
      start_write(subdir, newprefix);
      free(subdir);
      free(newprefix);
      break;
    default:
      break;
    }
  }
  closedir(d);
}
